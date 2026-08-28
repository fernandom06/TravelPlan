def _valid_trip(**overrides):
    payload = {
        "name": "Viaje a Galicia",
        "start_date": "2026-06-01",
        "end_date": "2026-06-10",
    }
    payload.update(overrides)
    return payload


def _square_zone():
    return {
        "points": [
            {"latitude": 42.0, "longitude": -4.0},
            {"latitude": 42.0, "longitude": -3.0},
            {"latitude": 43.0, "longitude": -3.0},
            {"latitude": 43.0, "longitude": -4.0},
        ]
    }


def _create_category(client, name="Naturaleza"):
    return client.post("/categories", json={"name": name}).json()


def _create_place(client, category_id, latitude, longitude, name="Mirador"):
    response = client.post(
        "/places",
        json={
            "name": name,
            "category_id": category_id,
            "latitude": latitude,
            "longitude": longitude,
        },
    )
    assert response.status_code == 201
    return response.json()


def _linked_place_ids(db_conn, trip_id):
    rows = db_conn.execute(
        "SELECT place_id FROM trip_itinerary_items "
        "WHERE trip_id = ? AND day_date IS NULL AND slot IS NULL "
        "ORDER BY position",
        (trip_id,),
    ).fetchall()
    return sorted(row["place_id"] for row in rows)


def test_create_trip_with_zone_less_than_3_points_returns_422(test_client):
    response = test_client.post(
        "/trips",
        json=_valid_trip(zone={"points": [
            {"latitude": 42.0, "longitude": -4.0},
            {"latitude": 42.0, "longitude": -3.0},
        ]}),
    )

    assert response.status_code == 422


def test_create_trip_with_zone_out_of_range_coords_returns_422(test_client):
    response = test_client.post(
        "/trips",
        json=_valid_trip(zone={"points": [
            {"latitude": 100.0, "longitude": -4.0},
            {"latitude": 42.0, "longitude": -3.0},
            {"latitude": 43.0, "longitude": -3.0},
        ]}),
    )

    assert response.status_code == 422


def test_create_trip_with_valid_zone_succeeds(test_client):
    response = test_client.post(
        "/trips",
        json=_valid_trip(zone=_square_zone()),
    )

    assert response.status_code == 201


def test_create_trip_links_only_places_inside_zone(
    test_client, db_conn
):
    category = _create_category(test_client)
    inside_1 = _create_place(test_client, category["id"], 42.5, -3.5, "Dentro 1")
    inside_2 = _create_place(test_client, category["id"], 42.5, -3.2, "Dentro 2")
    outside = _create_place(test_client, category["id"], 44.0, -3.5, "Fuera")

    response = test_client.post(
        "/trips", json=_valid_trip(zone=_square_zone())
    )

    assert response.status_code == 201
    data = response.json()
    assert "zone" not in data
    assert _linked_place_ids(db_conn, data["id"]) == sorted(
        [inside_1["id"], inside_2["id"]]
    )
    assert outside["id"] not in _linked_place_ids(db_conn, data["id"])


def test_create_trip_without_zone_leaves_trip_places_empty(
    test_client, db_conn
):
    category = _create_category(test_client)
    _create_place(test_client, category["id"], 42.5, -3.5, "Dentro")

    response = test_client.post("/trips", json=_valid_trip())

    assert response.status_code == 201
    assert _linked_place_ids(db_conn, response.json()["id"]) == []


def test_create_trip_with_zone_matching_no_places_is_ok(
    test_client, db_conn
):
    category = _create_category(test_client)
    _create_place(test_client, category["id"], 44.0, -3.5, "Fuera")

    response = test_client.post(
        "/trips", json=_valid_trip(zone=_square_zone())
    )

    assert response.status_code == 201
    assert _linked_place_ids(db_conn, response.json()["id"]) == []


def test_update_trip_keeps_linked_places_intact(test_client, db_conn):
    category = _create_category(test_client)
    inside = _create_place(test_client, category["id"], 42.5, -3.5, "Dentro")

    created = test_client.post(
        "/trips", json=_valid_trip(zone=_square_zone())
    ).json()

    response = test_client.patch(
        f"/trips/{created['id']}",
        json=_valid_trip(name="Viaje renombrado"),
    )

    assert response.status_code == 200
    assert response.json()["name"] == "Viaje renombrado"
    assert _linked_place_ids(db_conn, created["id"]) == [inside["id"]]


def test_delete_trip_cascades_trip_places(test_client, db_conn):
    category = _create_category(test_client)
    inside = _create_place(test_client, category["id"], 42.5, -3.5, "Dentro")

    created = test_client.post(
        "/trips", json=_valid_trip(zone=_square_zone())
    ).json()
    assert _linked_place_ids(db_conn, created["id"]) == [inside["id"]]

    response = test_client.delete(f"/trips/{created['id']}")

    assert response.status_code == 204
    assert _linked_place_ids(db_conn, created["id"]) == []
    # El place sobrevive al borrado del viaje.
    assert test_client.get(f"/places/{inside['id']}").status_code == 200


def test_zone_bulk_add_uses_correlative_positions_in_general_list(
    test_client, db_conn
):
    category = _create_category(test_client)
    _create_place(test_client, category["id"], 42.5, -3.5, "Dentro 1")
    _create_place(test_client, category["id"], 42.3, -3.2, "Dentro 2")

    created = test_client.post(
        "/trips", json=_valid_trip(zone=_square_zone())
    ).json()

    rows = db_conn.execute(
        "SELECT place_id, position, day_date, slot FROM trip_itinerary_items "
        "WHERE trip_id = ? ORDER BY position",
        (created["id"],),
    ).fetchall()
    assert [row["place_id"] for row in rows] == sorted(
        row["place_id"] for row in rows
    )
    assert [row["position"] for row in rows] == [0, 1]
    assert all(row["day_date"] is None and row["slot"] is None for row in rows)


def test_zone_bulk_add_links_each_place_once(test_client, db_conn):
    category = _create_category(test_client)
    inside = _create_place(test_client, category["id"], 42.5, -3.5, "Dentro")

    created = test_client.post(
        "/trips", json=_valid_trip(zone=_square_zone())
    ).json()

    count = db_conn.execute(
        "SELECT COUNT(*) FROM trip_itinerary_items "
        "WHERE trip_id = ? AND place_id = ?",
        (created["id"], inside["id"]),
    ).fetchone()[0]
    assert count == 1