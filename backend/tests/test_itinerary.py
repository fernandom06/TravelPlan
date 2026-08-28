def _create_category(client, name="Naturaleza"):
    return client.post("/categories", json={"name": name}).json()


def _create_place(client, category_id, name="Mirador", latitude=42.5, longitude=-3.5):
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


def _create_trip(client, start_date="2026-06-01", end_date="2026-06-10"):
    response = client.post(
        "/trips",
        json={"name": "Viaje", "start_date": start_date, "end_date": end_date},
    )
    assert response.status_code == 201
    return response.json()


def _insert_item(db_conn, trip_id, place_id, position, day_date=None, slot=None):
    cursor = db_conn.execute(
        "INSERT INTO trip_itinerary_items "
        "(trip_id, place_id, day_date, slot, position) "
        "VALUES (?, ?, ?, ?, ?)",
        (trip_id, place_id, day_date, slot, position),
    )
    return cursor.lastrowid


def test_get_itinerary_trip_not_found(test_client):
    response = test_client.get("/trips/nonexistent/itinerary")

    assert response.status_code == 404


def test_get_itinerary_empty_for_new_trip(test_client):
    trip = _create_trip(test_client)

    response = test_client.get(f"/trips/{trip['id']}/itinerary")

    assert response.status_code == 200
    assert response.json() == []


def test_get_itinerary_returns_items_with_embedded_place(
    test_client, db_conn
):
    category = _create_category(test_client)
    place = _create_place(test_client, category["id"], "Mirador")
    trip = _create_trip(test_client)
    _insert_item(db_conn, trip["id"], place["id"], 0)
    db_conn.commit()

    response = test_client.get(f"/trips/{trip['id']}/itinerary")

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    item = data[0]
    assert item["day_date"] is None
    assert item["slot"] is None
    assert item["position"] == 0
    assert item["place"]["id"] == place["id"]
    assert item["place"]["name"] == "Mirador"
    assert item["place"]["category"]["name"] == "Naturaleza"


def test_get_itinerary_mixes_general_and_placed_ordered_by_container_and_position(
    test_client, db_conn
):
    category = _create_category(test_client)
    place_a = _create_place(test_client, category["id"], "A")
    place_b = _create_place(test_client, category["id"], "B")
    place_c = _create_place(test_client, category["id"], "C")
    trip = _create_trip(test_client)
    item_a = _insert_item(
        db_conn, trip["id"], place_a["id"], 0, day_date="2026-06-01", slot="morning"
    )
    item_b = _insert_item(db_conn, trip["id"], place_b["id"], 0)
    item_c = _insert_item(
        db_conn, trip["id"], place_c["id"], 0, day_date="2026-06-03", slot="night"
    )
    db_conn.commit()

    response = test_client.get(f"/trips/{trip['id']}/itinerary")

    assert response.status_code == 200
    data = response.json()
    # La lista general va primero (por contenedor), luego los colocados.
    assert [item["id"] for item in data] == [item_b, item_a, item_c]
    assert data[0]["day_date"] is None
    assert data[1]["day_date"] == "2026-06-01"
    assert data[1]["slot"] == "morning"
    assert data[2]["day_date"] == "2026-06-03"
    assert data[2]["slot"] == "night"


def test_post_item_creates_in_general_list_at_end(test_client, db_conn):
    category = _create_category(test_client)
    place = _create_place(test_client, category["id"])
    trip = _create_trip(test_client)
    _insert_item(db_conn, trip["id"], place["id"], 0)
    db_conn.commit()

    response = test_client.post(
        f"/trips/{trip['id']}/itinerary", json={"place_id": place["id"]}
    )

    assert response.status_code == 201
    data = response.json()
    assert data["id"] > 0
    assert data["day_date"] is None
    assert data["slot"] is None
    assert data["position"] == 1
    assert data["place"]["id"] == place["id"]

    fetched = test_client.get(f"/trips/{trip['id']}/itinerary").json()
    assert [item["position"] for item in fetched] == [0, 1]


def test_post_same_place_twice_creates_two_instances(test_client):
    category = _create_category(test_client)
    place = _create_place(test_client, category["id"])
    trip = _create_trip(test_client)

    first = test_client.post(
        f"/trips/{trip['id']}/itinerary", json={"place_id": place["id"]}
    )
    second = test_client.post(
        f"/trips/{trip['id']}/itinerary", json={"place_id": place["id"]}
    )

    assert first.status_code == 201
    assert second.status_code == 201
    assert first.json()["id"] != second.json()["id"]
    items = test_client.get(f"/trips/{trip['id']}/itinerary").json()
    assert len(items) == 2
    assert all(item["place"]["id"] == place["id"] for item in items)


def test_post_item_place_not_found(test_client):
    trip = _create_trip(test_client)

    response = test_client.post(
        f"/trips/{trip['id']}/itinerary", json={"place_id": 999}
    )

    assert response.status_code == 404


def test_post_item_trip_not_found(test_client):
    response = test_client.post(
        "/trips/nonexistent/itinerary", json={"place_id": 1}
    )

    assert response.status_code == 404


def _add_item(client, trip_id, place_id):
    response = client.post(
        f"/trips/{trip_id}/itinerary", json={"place_id": place_id}
    )
    assert response.status_code == 201
    return response.json()


def _move_item(client, trip_id, item_id, day_date, slot, position):
    return client.patch(
        f"/trips/{trip_id}/itinerary/{item_id}",
        json={"day_date": day_date, "slot": slot, "position": position},
    )


def _container_items(itinerary, day_date, slot):
    return [
        item
        for item in itinerary
        if item["day_date"] == day_date and item["slot"] == slot
    ]


def _general_items(itinerary):
    return [item for item in itinerary if item["day_date"] is None]


def _assert_compacted(container):
    assert [item["position"] for item in container] == list(
        range(len(container))
    )


def test_patch_moves_item_from_general_to_slot(test_client):
    category = _create_category(test_client)
    place_a = _create_place(test_client, category["id"], "A")
    place_b = _create_place(test_client, category["id"], "B")
    trip = _create_trip(test_client)
    item_a = _add_item(test_client, trip["id"], place_a["id"])
    _add_item(test_client, trip["id"], place_b["id"])

    response = _move_item(
        test_client, trip["id"], item_a["id"], "2026-06-01", "morning", 0
    )

    assert response.status_code == 200
    data = response.json()
    assert data["day_date"] == "2026-06-01"
    assert data["slot"] == "morning"
    assert data["position"] == 0

    itinerary = test_client.get(f"/trips/{trip['id']}/itinerary").json()
    assert [item["place"]["id"] for item in _general_items(itinerary)] == [
        place_b["id"]
    ]
    morning = _container_items(itinerary, "2026-06-01", "morning")
    assert [item["place"]["id"] for item in morning] == [place_a["id"]]
    _assert_compacted(morning)


def test_patch_moves_item_from_slot_to_general(test_client):
    category = _create_category(test_client)
    place_a = _create_place(test_client, category["id"], "A")
    place_b = _create_place(test_client, category["id"], "B")
    trip = _create_trip(test_client)
    item_a = _add_item(test_client, trip["id"], place_a["id"])
    _add_item(test_client, trip["id"], place_b["id"])
    _move_item(test_client, trip["id"], item_a["id"], "2026-06-01", "morning", 0)

    response = _move_item(
        test_client, trip["id"], item_a["id"], None, None, 0
    )

    assert response.status_code == 200
    itinerary = test_client.get(f"/trips/{trip['id']}/itinerary").json()
    general = _general_items(itinerary)
    assert [item["place"]["id"] for item in general] == [
        place_a["id"],
        place_b["id"],
    ]
    _assert_compacted(general)
    assert _container_items(itinerary, "2026-06-01", "morning") == []


def test_patch_moves_item_between_slots_of_different_days(test_client):
    category = _create_category(test_client)
    place_a = _create_place(test_client, category["id"], "A")
    place_b = _create_place(test_client, category["id"], "B")
    trip = _create_trip(test_client)
    item_a = _add_item(test_client, trip["id"], place_a["id"])
    _add_item(test_client, trip["id"], place_b["id"])
    _move_item(test_client, trip["id"], item_a["id"], "2026-06-01", "morning", 0)

    response = _move_item(
        test_client, trip["id"], item_a["id"], "2026-06-03", "night", 0
    )

    assert response.status_code == 200
    itinerary = test_client.get(f"/trips/{trip['id']}/itinerary").json()
    assert _container_items(itinerary, "2026-06-01", "morning") == []
    night = _container_items(itinerary, "2026-06-03", "night")
    assert [item["place"]["id"] for item in night] == [place_a["id"]]
    _assert_compacted(night)


def test_patch_reorders_within_slot_with_index_adjustment(test_client):
    category = _create_category(test_client)
    place_a = _create_place(test_client, category["id"], "A")
    place_b = _create_place(test_client, category["id"], "B")
    place_c = _create_place(test_client, category["id"], "C")
    trip = _create_trip(test_client)
    item_a = _add_item(test_client, trip["id"], place_a["id"])
    item_b = _add_item(test_client, trip["id"], place_b["id"])
    item_c = _add_item(test_client, trip["id"], place_c["id"])
    for item, slot_pos in [(item_a, 0), (item_b, 1), (item_c, 2)]:
        _move_item(test_client, trip["id"], item["id"], "2026-06-01", "morning", slot_pos)

    # Mover C (última) antes de B: PATCH position 1.
    response = _move_item(
        test_client, trip["id"], item_c["id"], "2026-06-01", "morning", 1
    )

    assert response.status_code == 200
    morning = _container_items(
        test_client.get(f"/trips/{trip['id']}/itinerary").json(),
        "2026-06-01",
        "morning",
    )
    assert [item["place"]["id"] for item in morning] == [
        place_a["id"],
        place_c["id"],
        place_b["id"],
    ]
    _assert_compacted(morning)

    # Mover A (primera) tras C: PATCH position 2 (insertar después de sí misma).
    response = _move_item(
        test_client, trip["id"], item_a["id"], "2026-06-01", "morning", 2
    )

    assert response.status_code == 200
    morning = _container_items(
        test_client.get(f"/trips/{trip['id']}/itinerary").json(),
        "2026-06-01",
        "morning",
    )
    assert [item["place"]["id"] for item in morning] == [
        place_c["id"],
        place_a["id"],
        place_b["id"],
    ]
    _assert_compacted(morning)


def test_patch_compacts_positions_in_origin_and_destination(test_client):
    category = _create_category(test_client)
    place_a = _create_place(test_client, category["id"], "A")
    place_b = _create_place(test_client, category["id"], "B")
    place_c = _create_place(test_client, category["id"], "C")
    trip = _create_trip(test_client)
    item_a = _add_item(test_client, trip["id"], place_a["id"])
    item_b = _add_item(test_client, trip["id"], place_b["id"])
    _add_item(test_client, trip["id"], place_c["id"])

    _move_item(test_client, trip["id"], item_a["id"], "2026-06-01", "morning", 0)
    _move_item(test_client, trip["id"], item_b["id"], "2026-06-01", "morning", 0)
    # Sacar B de la franja: origen queda con A en position 0 compactado.
    _move_item(test_client, trip["id"], item_b["id"], None, None, 0)

    itinerary = test_client.get(f"/trips/{trip['id']}/itinerary").json()
    morning = _container_items(itinerary, "2026-06-01", "morning")
    general = _general_items(itinerary)
    assert [item["place"]["id"] for item in morning] == [place_a["id"]]
    assert [item["place"]["id"] for item in general] == [
        place_b["id"],
        place_c["id"],
    ]
    _assert_compacted(morning)
    _assert_compacted(general)


def test_patch_day_outside_trip_range_returns_422(test_client):
    category = _create_category(test_client)
    place = _create_place(test_client, category["id"])
    trip = _create_trip(test_client)
    item = _add_item(test_client, trip["id"], place["id"])

    response = _move_item(
        test_client, trip["id"], item["id"], "2026-05-31", "morning", 0
    )
    assert response.status_code == 422

    response = _move_item(
        test_client, trip["id"], item["id"], "2026-06-11", "morning", 0
    )
    assert response.status_code == 422

    itinerary = test_client.get(f"/trips/{trip['id']}/itinerary").json()
    assert [item["place"]["id"] for item in _general_items(itinerary)] == [
        place["id"]
    ]


def test_patch_invalid_slot_returns_422(test_client):
    category = _create_category(test_client)
    place = _create_place(test_client, category["id"])
    trip = _create_trip(test_client)
    item = _add_item(test_client, trip["id"], place["id"])

    response = test_client.patch(
        f"/trips/{trip['id']}/itinerary/{item['id']}",
        json={"day_date": "2026-06-01", "slot": "evening", "position": 0},
    )

    assert response.status_code == 422


def test_patch_item_not_found(test_client):
    category = _create_category(test_client)
    _create_place(test_client, category["id"])
    trip = _create_trip(test_client)

    response = _move_item(
        test_client, trip["id"], 999, "2026-06-01", "morning", 0
    )

    assert response.status_code == 404


def test_patch_trip_not_found(test_client):
    response = _move_item(
        test_client, "nonexistent", 1, "2026-06-01", "morning", 0
    )

    assert response.status_code == 404


def test_delete_item_removes_only_that_instance(test_client):
    category = _create_category(test_client)
    place_a = _create_place(test_client, category["id"], "A")
    place_b = _create_place(test_client, category["id"], "B")
    trip = _create_trip(test_client)
    item_a_1 = _add_item(test_client, trip["id"], place_a["id"])
    _add_item(test_client, trip["id"], place_b["id"])
    _add_item(test_client, trip["id"], place_a["id"])
    _move_item(test_client, trip["id"], item_a_1["id"], "2026-06-01", "morning", 0)

    response = test_client.delete(
        f"/trips/{trip['id']}/itinerary/{item_a_1['id']}"
    )

    assert response.status_code == 204
    itinerary = test_client.get(f"/trips/{trip['id']}/itinerary").json()
    # La otra instancia de A sigue, ahora en la lista general.
    general = _general_items(itinerary)
    assert [item["place"]["id"] for item in general] == [
        place_b["id"],
        place_a["id"],
    ]
    _assert_compacted(general)
    assert _container_items(itinerary, "2026-06-01", "morning") == []


def test_delete_item_compacts_positions(test_client):
    category = _create_category(test_client)
    place_a = _create_place(test_client, category["id"], "A")
    place_b = _create_place(test_client, category["id"], "B")
    place_c = _create_place(test_client, category["id"], "C")
    trip = _create_trip(test_client)
    item_a = _add_item(test_client, trip["id"], place_a["id"])
    item_b = _add_item(test_client, trip["id"], place_b["id"])
    item_c = _add_item(test_client, trip["id"], place_c["id"])
    for item, slot_pos in [(item_a, 0), (item_b, 1), (item_c, 2)]:
        _move_item(test_client, trip["id"], item["id"], "2026-06-01", "morning", slot_pos)

    response = test_client.delete(
        f"/trips/{trip['id']}/itinerary/{item_b['id']}"
    )

    assert response.status_code == 204
    morning = _container_items(
        test_client.get(f"/trips/{trip['id']}/itinerary").json(),
        "2026-06-01",
        "morning",
    )
    assert [item["place"]["id"] for item in morning] == [
        place_a["id"],
        place_c["id"],
    ]
    _assert_compacted(morning)


def test_delete_item_not_found(test_client):
    category = _create_category(test_client)
    _create_place(test_client, category["id"])
    trip = _create_trip(test_client)

    response = test_client.delete(f"/trips/{trip['id']}/itinerary/999")

    assert response.status_code == 404


def test_deleting_place_removes_it_from_all_itineraries(test_client):
    category = _create_category(test_client)
    place = _create_place(test_client, category["id"], "Mirador")
    trip_a = _create_trip(test_client)
    trip_b = _create_trip(test_client)
    _add_item(test_client, trip_a["id"], place["id"])
    _add_item(test_client, trip_a["id"], place["id"])
    _add_item(test_client, trip_b["id"], place["id"])

    response = test_client.delete(f"/places/{place['id']}")

    assert response.status_code == 204
    for trip in (trip_a, trip_b):
        itinerary = test_client.get(f"/trips/{trip['id']}/itinerary").json()
        assert itinerary == []