import sqlite3

from backend.database import init_db


def _connect() -> sqlite3.Connection:
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def test_trips_table_is_created():
    conn = _connect()
    init_db(conn)

    columns = conn.execute("PRAGMA table_info(trips)").fetchall()
    names = [row["name"] for row in columns]

    assert "id" in names
    assert "name" in names
    assert "description" in names
    assert "start_date" in names
    assert "end_date" in names
    assert "image_url" in names
    assert "created_at" in names
    conn.close()


def test_trip_itinerary_items_created():
    conn = _connect()
    init_db(conn)

    columns = conn.execute("PRAGMA table_info(trip_itinerary_items)").fetchall()
    names = [row["name"] for row in columns]

    assert "id" in names
    assert "trip_id" in names
    assert "place_id" in names
    assert "day_date" in names
    assert "slot" in names
    assert "position" in names
    conn.close()


def test_trip_itinerary_allows_multiple_instances_of_same_place():
    conn = _connect()
    init_db(conn)

    category_id = conn.execute(
        "INSERT INTO categories (name) VALUES (?)", ("Naturaleza",)
    ).lastrowid
    place_id = conn.execute(
        "INSERT INTO places (name, latitude, longitude, category_id) "
        "VALUES (?, ?, ?, ?)",
        ("Mirador", 42.5, -3.1, category_id),
    ).lastrowid
    trip_id = "trip-uuid-1"
    conn.execute(
        "INSERT INTO trips (id, name, start_date, end_date) VALUES (?, ?, ?, ?)",
        (trip_id, "Viaje", "2026-01-01", "2026-01-10"),
    )
    conn.execute(
        "INSERT INTO trip_itinerary_items (trip_id, place_id, position) "
        "VALUES (?, ?, ?)",
        (trip_id, place_id, 0),
    )
    conn.execute(
        "INSERT INTO trip_itinerary_items (trip_id, place_id, position) "
        "VALUES (?, ?, ?)",
        (trip_id, place_id, 1),
    )
    conn.commit()

    rows = conn.execute(
        "SELECT COUNT(*) FROM trip_itinerary_items WHERE trip_id = ? AND place_id = ?",
        (trip_id, place_id),
    ).fetchone()[0]

    assert rows == 2
    conn.close()


def test_deleting_trip_cascades_itinerary_items_but_keeps_place():
    conn = _connect()
    init_db(conn)

    category_id = conn.execute(
        "INSERT INTO categories (name) VALUES (?)", ("Naturaleza",)
    ).lastrowid
    place_id = conn.execute(
        "INSERT INTO places (name, latitude, longitude, category_id) "
        "VALUES (?, ?, ?, ?)",
        ("Mirador", 42.5, -3.1, category_id),
    ).lastrowid
    trip_id = "trip-uuid-1"
    conn.execute(
        "INSERT INTO trips (id, name, start_date, end_date) VALUES (?, ?, ?, ?)",
        (trip_id, "Viaje", "2026-01-01", "2026-01-10"),
    )
    conn.execute(
        "INSERT INTO trip_itinerary_items (trip_id, place_id, position) "
        "VALUES (?, ?, ?)",
        (trip_id, place_id, 0),
    )
    conn.commit()

    conn.execute("DELETE FROM trips WHERE id = ?", (trip_id,))
    conn.commit()

    junction = conn.execute(
        "SELECT COUNT(*) FROM trip_itinerary_items WHERE trip_id = ?", (trip_id,)
    ).fetchone()[0]
    place = conn.execute(
        "SELECT id FROM places WHERE id = ?", (place_id,)
    ).fetchone()

    assert junction == 0
    assert place is not None
    conn.close()


def test_deleting_place_cascades_itinerary_items_but_keeps_trip():
    conn = _connect()
    init_db(conn)

    category_id = conn.execute(
        "INSERT INTO categories (name) VALUES (?)", ("Naturaleza",)
    ).lastrowid
    place_id = conn.execute(
        "INSERT INTO places (name, latitude, longitude, category_id) "
        "VALUES (?, ?, ?, ?)",
        ("Mirador", 42.5, -3.1, category_id),
    ).lastrowid
    trip_id = "trip-uuid-1"
    conn.execute(
        "INSERT INTO trips (id, name, start_date, end_date) VALUES (?, ?, ?, ?)",
        (trip_id, "Viaje", "2026-01-01", "2026-01-10"),
    )
    conn.execute(
        "INSERT INTO trip_itinerary_items (trip_id, place_id, position) "
        "VALUES (?, ?, ?)",
        (trip_id, place_id, 0),
    )
    conn.commit()

    conn.execute("DELETE FROM places WHERE id = ?", (place_id,))
    conn.commit()

    junction = conn.execute(
        "SELECT COUNT(*) FROM trip_itinerary_items WHERE trip_id = ?", (trip_id,)
    ).fetchone()[0]
    trip = conn.execute(
        "SELECT id FROM trips WHERE id = ?", (trip_id,)
    ).fetchone()

    assert junction == 0
    assert trip is not None
    conn.close()
