import sqlite3
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status

from .database import get_db
from .schemas import (
    CategoryResponse,
    ItineraryItemCreate,
    ItineraryItemMove,
    ItineraryItemResponse,
    PlaceResponse,
)

router = APIRouter(prefix="/trips", tags=["itinerary"])

_ITEM_SELECT = """
    SELECT ii.id, ii.day_date, ii.slot, ii.position,
           p.id AS place_id, p.name AS place_name, p.description AS place_description,
           p.latitude AS place_latitude, p.longitude AS place_longitude,
           p.category_id, c.name AS category_name, c.icon AS category_icon
    FROM trip_itinerary_items ii
    JOIN places p ON p.id = ii.place_id
    JOIN categories c ON c.id = p.category_id
"""


def _row_to_response(row: sqlite3.Row) -> ItineraryItemResponse:
    return ItineraryItemResponse(
        id=row["id"],
        day_date=row["day_date"],
        slot=row["slot"],
        position=row["position"],
        place=PlaceResponse(
            id=row["place_id"],
            name=row["place_name"],
            description=row["place_description"],
            latitude=row["place_latitude"],
            longitude=row["place_longitude"],
            category=CategoryResponse(
                id=row["category_id"],
                name=row["category_name"],
                icon=row["category_icon"],
            ),
        ),
    )


def _fetch_trip(conn: sqlite3.Connection, trip_id: str) -> sqlite3.Row | None:
    return conn.execute(
        "SELECT id FROM trips WHERE id = ?", (trip_id,)
    ).fetchone()


def _fetch_item(
    conn: sqlite3.Connection, trip_id: str, item_id: int
) -> sqlite3.Row | None:
    return conn.execute(
        _ITEM_SELECT + "WHERE ii.trip_id = ? AND ii.id = ?", (trip_id, item_id)
    ).fetchone()


def _general_list_next_position(
    conn: sqlite3.Connection, trip_id: str
) -> int:
    row = conn.execute(
        "SELECT COALESCE(MAX(position) + 1, 0) FROM trip_itinerary_items "
        "WHERE trip_id = ? AND day_date IS NULL AND slot IS NULL",
        (trip_id,),
    ).fetchone()
    return row[0]


def _container_where(day: str | None, slot: str | None) -> str:
    if day is None and slot is None:
        return "trip_id = ? AND day_date IS NULL AND slot IS NULL"
    return "trip_id = ? AND day_date = ? AND slot = ?"


def _container_params(trip_id: str, day: str | None, slot: str | None):
    if day is None and slot is None:
        return (trip_id,)
    return (trip_id, day, slot)


@router.get("/{trip_id}/itinerary", response_model=list[ItineraryItemResponse])
def get_itinerary(
    trip_id: str,
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> list[ItineraryItemResponse]:
    if _fetch_trip(conn, trip_id) is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Trip not found"
        )
    rows = conn.execute(
        _ITEM_SELECT
        + "WHERE ii.trip_id = ? "
        "ORDER BY ii.day_date IS NOT NULL, ii.day_date, ii.slot, ii.position",
        (trip_id,),
    ).fetchall()
    return [_row_to_response(row) for row in rows]


@router.post(
    "/{trip_id}/itinerary",
    response_model=ItineraryItemResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_itinerary_item(
    trip_id: str,
    payload: ItineraryItemCreate,
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> ItineraryItemResponse:
    if _fetch_trip(conn, trip_id) is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Trip not found"
        )
    place = conn.execute(
        "SELECT id FROM places WHERE id = ?", (payload.place_id,)
    ).fetchone()
    if place is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Place not found"
        )

    position = _general_list_next_position(conn, trip_id)
    cursor = conn.execute(
        "INSERT INTO trip_itinerary_items "
        "(trip_id, place_id, day_date, slot, position) "
        "VALUES (?, ?, NULL, NULL, ?)",
        (trip_id, payload.place_id, position),
    )
    conn.commit()
    return _row_to_response(_fetch_item(conn, trip_id, cursor.lastrowid))


@router.patch(
    "/{trip_id}/itinerary/{item_id}", response_model=ItineraryItemResponse
)
def move_itinerary_item(
    trip_id: str,
    item_id: int,
    payload: ItineraryItemMove,
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> ItineraryItemResponse:
    if _fetch_trip(conn, trip_id) is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Trip not found"
        )
    item = _fetch_item(conn, trip_id, item_id)
    if item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Itinerary item not found"
        )

    target_day = payload.day_date.isoformat() if payload.day_date else None
    target_slot = payload.slot.value if payload.slot else None

    if target_day is not None:
        trip = conn.execute(
            "SELECT start_date, end_date FROM trips WHERE id = ?", (trip_id,)
        ).fetchone()
        if not (trip["start_date"] <= target_day <= trip["end_date"]):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="day_date is outside the trip date range",
            )

    origin_day = item["day_date"]
    origin_slot = item["slot"]
    old_position = item["position"]
    same_container = origin_day == target_day and origin_slot == target_slot

    # Compacta el origen: los items posteriores al movido bajan una posición.
    conn.execute(
        "UPDATE trip_itinerary_items SET position = position - 1 "
        f"WHERE {_container_where(origin_day, origin_slot)} "
        "AND id != ? AND position > ?",
        (*_container_params(trip_id, origin_day, origin_slot), item_id, old_position),
    )

    # Índice efectivo de inserción: al reordenar dentro del mismo contenedor,
    # el origen ya se compactó antes de insertar.
    effective = payload.position
    if same_container and effective > old_position:
        effective -= 1
    target_count = conn.execute(
        "SELECT COUNT(*) FROM trip_itinerary_items "
        f"WHERE {_container_where(target_day, target_slot)} "
        "AND id != ?",
        (*_container_params(trip_id, target_day, target_slot), item_id),
    ).fetchone()[0]
    effective = max(0, min(effective, target_count))

    # Abre hueco en el destino desplazando hacia arriba desde el índice.
    conn.execute(
        "UPDATE trip_itinerary_items SET position = position + 1 "
        f"WHERE {_container_where(target_day, target_slot)} "
        "AND id != ? AND position >= ?",
        (*_container_params(trip_id, target_day, target_slot), item_id, effective),
    )

    conn.execute(
        "UPDATE trip_itinerary_items SET day_date = ?, slot = ?, position = ? "
        "WHERE id = ?",
        (target_day, target_slot, effective, item_id),
    )
    conn.commit()
    return _row_to_response(_fetch_item(conn, trip_id, item_id))


@router.delete(
    "/{trip_id}/itinerary/{item_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_model=None,
)
def delete_itinerary_item(
    trip_id: str,
    item_id: int,
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> None:
    if _fetch_trip(conn, trip_id) is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Trip not found"
        )
    item = _fetch_item(conn, trip_id, item_id)
    if item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Itinerary item not found"
        )

    conn.execute(
        "UPDATE trip_itinerary_items SET position = position - 1 "
        f"WHERE {_container_where(item["day_date"], item["slot"])} "
        "AND id != ? AND position > ?",
        (
            *_container_params(trip_id, item["day_date"], item["slot"]),
            item_id,
            item["position"],
        ),
    )
    conn.execute(
        "DELETE FROM trip_itinerary_items WHERE id = ?", (item_id,)
    )
    conn.commit()