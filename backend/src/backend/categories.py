import sqlite3
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status

from .database import get_db
from .schemas import CategoryCreate, CategoryResponse

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryResponse])
def list_categories(
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> list[CategoryResponse]:
    rows = conn.execute("SELECT id, name, icon FROM categories ORDER BY id").fetchall()
    return [
        CategoryResponse(id=row["id"], name=row["name"], icon=row["icon"])
        for row in rows
    ]


@router.post("", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(
    payload: CategoryCreate,
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> CategoryResponse:
    try:
        cursor = conn.execute(
            "INSERT INTO categories (name, icon) VALUES (?, ?)",
            (payload.name, payload.icon),
        )
        conn.commit()
    except sqlite3.IntegrityError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="Category already exists"
        )
    return CategoryResponse(id=cursor.lastrowid, name=payload.name, icon=payload.icon)


@router.patch("/{category_id}", response_model=CategoryResponse)
def update_category(
    category_id: int,
    payload: CategoryCreate,
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
) -> CategoryResponse:
    exists = conn.execute(
        "SELECT id FROM categories WHERE id = ?", (category_id,)
    ).fetchone()
    if exists is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Category not found"
        )
    try:
        conn.execute(
            "UPDATE categories SET name = ?, icon = ? WHERE id = ?",
            (payload.name, payload.icon, category_id),
        )
        conn.commit()
    except sqlite3.IntegrityError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="Category already exists"
        )
    return CategoryResponse(id=category_id, name=payload.name, icon=payload.icon)


@router.delete(
    "/{category_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_model=None,
)
def delete_category(
    category_id: int,
    conn: Annotated[sqlite3.Connection, Depends(get_db)],
    reassign_to: int | None = Query(default=None),
) -> None:
    exists = conn.execute(
        "SELECT id FROM categories WHERE id = ?", (category_id,)
    ).fetchone()
    if exists is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Category not found"
        )

    count = conn.execute(
        "SELECT COUNT(*) FROM places WHERE category_id = ?", (category_id,)
    ).fetchone()[0]
    if count == 0:
        conn.execute("DELETE FROM categories WHERE id = ?", (category_id,))
        conn.commit()
        return

    if reassign_to is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Reassignment target required",
        )
    if reassign_to == category_id:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Cannot reassign to the category being deleted",
        )
    target = conn.execute(
        "SELECT id FROM categories WHERE id = ?", (reassign_to,)
    ).fetchone()
    if target is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Reassignment target not found",
        )

    conn.execute(
        "UPDATE places SET category_id = ? WHERE category_id = ?",
        (reassign_to, category_id),
    )
    conn.execute("DELETE FROM categories WHERE id = ?", (category_id,))
    conn.commit()
