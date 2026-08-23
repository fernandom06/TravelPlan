import sqlite3
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status

from .database import get_db
from .schemas import CategoryCreate, CategoryResponse

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryResponse])
def list_categories(
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> list[CategoryResponse]:
    rows = conn.execute("SELECT id, name FROM categories ORDER BY id").fetchall()
    return [CategoryResponse(id=row["id"], name=row["name"]) for row in rows]


@router.post("", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(
    payload: CategoryCreate,
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> CategoryResponse:
    try:
        cursor = conn.execute(
            "INSERT INTO categories (name) VALUES (?)", (payload.name,)
        )
        conn.commit()
    except sqlite3.IntegrityError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="Category already exists"
        )
    return CategoryResponse(id=cursor.lastrowid, name=payload.name)
