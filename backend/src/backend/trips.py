import sqlite3
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status

from .database import get_db
from .schemas import TripCreate, TripResponse, TripUpdate

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
