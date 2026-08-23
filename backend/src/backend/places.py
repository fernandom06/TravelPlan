import sqlite3
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status

from .database import get_db
from .schemas import CategoryResponse, PlaceCreate, PlaceResponse, PlaceUpdate

router = APIRouter(prefix="/places", tags=["places"])

_PLACE_SELECT = """
    SELECT p.id, p.name, p.description, p.latitude, p.longitude,
           p.category_id, c.name AS category_name
    FROM places p
    JOIN categories c ON c.id = p.category_id
"""


def _row_to_response(row: sqlite3.Row) -> PlaceResponse:
    return PlaceResponse(
        id=row["id"],
        name=row["name"],
        description=row["description"],
        latitude=row["latitude"],
        longitude=row["longitude"],
        category=CategoryResponse(id=row["category_id"], name=row["category_name"]),
    )


def _fetch_place(conn: sqlite3.Connection, place_id: int) -> sqlite3.Row | None:
    return conn.execute(_PLACE_SELECT + "WHERE p.id = ?", (place_id,)).fetchone()


@router.get("", response_model=list[PlaceResponse])
def list_places(
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> list[PlaceResponse]:
    rows = conn.execute(_PLACE_SELECT + "ORDER BY p.id").fetchall()
    return [_row_to_response(row) for row in rows]


@router.get("/{place_id}", response_model=PlaceResponse)
def get_place(
    place_id: int,
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> PlaceResponse:
    row = _fetch_place(conn, place_id)
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Place not found"
        )
    return _row_to_response(row)


@router.post("", response_model=PlaceResponse, status_code=status.HTTP_201_CREATED)
def create_place(
    payload: PlaceCreate,
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> PlaceResponse:
    category = conn.execute(
        "SELECT id, name FROM categories WHERE id = ?", (payload.category_id,)
    ).fetchone()
    if category is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Category not found"
        )

    cursor = conn.execute(
        """
        INSERT INTO places (name, description, latitude, longitude, category_id)
        VALUES (?, ?, ?, ?, ?)
        """,
        (
            payload.name,
            payload.description,
            payload.latitude,
            payload.longitude,
            payload.category_id,
        ),
    )
    conn.commit()

    return PlaceResponse(
        id=cursor.lastrowid,
        name=payload.name,
        description=payload.description,
        latitude=payload.latitude,
        longitude=payload.longitude,
        category=CategoryResponse(id=category["id"], name=category["name"]),
    )


@router.patch("/{place_id}", response_model=PlaceResponse)
def update_place(
    place_id: int,
    payload: PlaceUpdate,
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> PlaceResponse:
    existing = _fetch_place(conn, place_id)
    if existing is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Place not found"
        )

    category = conn.execute(
        "SELECT id, name FROM categories WHERE id = ?", (payload.category_id,)
    ).fetchone()
    if category is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Category not found"
        )

    conn.execute(
        """
        UPDATE places SET name = ?, description = ?, category_id = ?
        WHERE id = ?
        """,
        (payload.name, payload.description, payload.category_id, place_id),
    )
    conn.commit()

    return _row_to_response(_fetch_place(conn, place_id))
