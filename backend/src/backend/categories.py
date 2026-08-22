import sqlite3
from typing import Annotated

from fastapi import APIRouter, Depends

from .database import get_db
from .schemas import CategoryResponse

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryResponse])
def list_categories(
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> list[CategoryResponse]:
    rows = conn.execute("SELECT id, name FROM categories ORDER BY id").fetchall()
    return [CategoryResponse(id=row["id"], name=row["name"]) for row in rows]
