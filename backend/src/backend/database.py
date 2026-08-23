import sqlite3
from collections.abc import Iterator

DB_PATH = "places.db"

DEFAULT_CATEGORIES = [
    "Naturaleza",
    "Monumento",
    "Restaurante",
    "Punto de interes",
]


def get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS places (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            category_id INTEGER NOT NULL REFERENCES categories(id),
            created_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
        """
    )
    conn.commit()


def seed_categories(conn: sqlite3.Connection) -> None:
    count = conn.execute("SELECT COUNT(*) FROM categories").fetchone()[0]
    if count == 0:
        conn.executemany(
            "INSERT INTO categories (name) VALUES (?)",
            [(name,) for name in DEFAULT_CATEGORIES],
        )
        conn.commit()


def init_database() -> None:
    conn = get_connection()
    try:
        init_db(conn)
        seed_categories(conn)
    finally:
        conn.close()


def get_db() -> Iterator[sqlite3.Connection]:
    conn = get_connection()
    try:
        yield conn
    finally:
        conn.close()
