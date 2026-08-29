import sqlite3
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from . import config
from .database import get_db
from .schemas import ImageUploadResponse, TripCreate, TripResponse, TripUpdate
from .zones import link_places_in_zone

router = APIRouter(prefix="/trips", tags=["trips"])

_TRIP_SELECT = """
    SELECT id, name, description, start_date, end_date,
           image_url, created_at
    FROM trips
"""


def _row_to_response(row: sqlite3.Row) -> TripResponse:
    return TripResponse(
        id=row["id"],
        name=row["name"],
        description=row["description"],
        start_date=row["start_date"],
        end_date=row["end_date"],
        image_url=row["image_url"],
        created_at=row["created_at"],
    )


def _fetch_trip(conn: sqlite3.Connection, trip_id: str) -> sqlite3.Row | None:
    return conn.execute(_TRIP_SELECT + "WHERE id = ?", (trip_id,)).fetchone()


def _reset_itinerary_placements(conn: sqlite3.Connection, trip_id: str) -> None:
    """Devuelve todos los items del viaje a la lista general.

    Se conserva el orden relativo previo: lista general primero (por
    ``position``) y después los colocados (por día, franja y posición),
    compactando posiciones de forma correlativa.
    """
    rows = conn.execute(
        "SELECT id FROM trip_itinerary_items WHERE trip_id = ? "
        "ORDER BY day_date IS NOT NULL, day_date, slot, position",
        (trip_id,),
    ).fetchall()
    for position, row in enumerate(rows):
        conn.execute(
            "UPDATE trip_itinerary_items SET day_date = NULL, slot = NULL, "
            "position = ? WHERE id = ?",
            (position, row["id"]),
        )


@router.get("", response_model=list[TripResponse])
def list_trips(
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> list[TripResponse]:
    rows = conn.execute(_TRIP_SELECT + "ORDER BY created_at DESC").fetchall()
    return [_row_to_response(row) for row in rows]


@router.post("", response_model=TripResponse, status_code=status.HTTP_201_CREATED)
def create_trip(
    payload: TripCreate,
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> TripResponse:
    trip_id = str(uuid.uuid4())
    conn.execute(
        """
        INSERT INTO trips (id, name, description, start_date, end_date, image_url)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        (
            trip_id,
            payload.name,
            payload.description,
            payload.start_date.isoformat(),
            payload.end_date.isoformat(),
            payload.image_url,
        ),
    )
    if payload.zone is not None:
        link_places_in_zone(conn, trip_id, payload.zone.points)
    conn.commit()
    return _row_to_response(_fetch_trip(conn, trip_id))


@router.get("/{trip_id}", response_model=TripResponse)
def get_trip(
    trip_id: str,
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> TripResponse:
    row = _fetch_trip(conn, trip_id)
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Trip not found"
        )
    return _row_to_response(row)


@router.patch("/{trip_id}", response_model=TripResponse)
def update_trip(
    trip_id: str,
    payload: TripUpdate,
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> TripResponse:
    existing = _fetch_trip(conn, trip_id)
    if existing is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Trip not found"
        )

    conn.execute(
        """
        UPDATE trips
        SET name = ?, description = ?, start_date = ?, end_date = ?, image_url = ?
        WHERE id = ?
        """,
        (
            payload.name,
            payload.description,
            payload.start_date.isoformat(),
            payload.end_date.isoformat(),
            payload.image_url,
            trip_id,
        ),
    )

    dates_changed = (
        payload.start_date.isoformat() != existing["start_date"]
        or payload.end_date.isoformat() != existing["end_date"]
    )
    if dates_changed:
        _reset_itinerary_placements(conn, trip_id)

    conn.commit()
    return _row_to_response(_fetch_trip(conn, trip_id))


@router.delete("/{trip_id}", status_code=status.HTTP_204_NO_CONTENT, response_model=None)
def delete_trip(
    trip_id: str,
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> None:
    existing = _fetch_trip(conn, trip_id)
    if existing is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Trip not found"
        )
    conn.execute("DELETE FROM trips WHERE id = ?", (trip_id,))
    conn.commit()


@router.post(
    "/images", response_model=ImageUploadResponse, status_code=status.HTTP_201_CREATED
)
def upload_image(
    file: Annotated[UploadFile, File()],
) -> ImageUploadResponse:
    content_type = file.content_type or ""
    if content_type not in config.ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Unsupported content type",
        )

    content = file.file.read()
    if len(content) > config.MAX_IMAGE_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_CONTENT_TOO_LARGE,
            detail="Image too large",
        )

    ext = config.EXT_BY_CONTENT_TYPE[content_type]
    filename = f"{uuid.uuid4()}{ext}"
    config.UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
    (config.UPLOADS_DIR / filename).write_bytes(content)

    return ImageUploadResponse(url=f"/uploads/{filename}")
