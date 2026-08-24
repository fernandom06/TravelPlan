def _valid_trip(name="Viaje a Galicia", **overrides):
    payload = {
        "name": name,
        "start_date": "2026-06-01",
        "end_date": "2026-06-10",
        "description": "Costas y comida",
    }
    payload.update(overrides)
    return payload


def _create_trip(client, **overrides):
    response = client.post("/trips", json=_valid_trip(**overrides))
    assert response.status_code == 201
    return response.json()


def test_list_trips_empty(test_client):
    response = test_client.get("/trips")

    assert response.status_code == 200
    assert response.json() == []


def test_list_trips_after_create(test_client):
    _create_trip(test_client)

    response = test_client.get("/trips")

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["name"] == "Viaje a Galicia"


def test_create_trip_returns_201_with_uuid(test_client):
    response = test_client.post("/trips", json=_valid_trip())

    assert response.status_code == 201
    data = response.json()
    assert data["id"]
    assert data["start_date"] == "2026-06-01"
    assert data["end_date"] == "2026-06-10"
    assert data["description"] == "Costas y comida"
    assert data["image_url"] is None
    assert data["created_at"]


def test_create_trip_persists_in_listing(test_client):
    created = _create_trip(test_client)

    listing = test_client.get("/trips").json()
    assert [t["id"] for t in listing] == [created["id"]]


def test_get_trip_by_id(test_client):
    created = _create_trip(test_client)

    response = test_client.get(f"/trips/{created['id']}")

    assert response.status_code == 200
    assert response.json()["id"] == created["id"]


def test_get_trip_not_found(test_client):
    response = test_client.get("/trips/nonexistent")

    assert response.status_code == 404


def test_create_trip_invalid_dates_returns_422(test_client):
    response = test_client.post(
        "/trips",
        json=_valid_trip(start_date="2026-06-10", end_date="2026-06-01"),
    )

    assert response.status_code == 422


def test_create_trip_empty_name_returns_422(test_client):
    response = test_client.post("/trips", json=_valid_trip(name=""))

    assert response.status_code == 422


def test_update_trip_returns_200_and_persists(test_client):
    created = _create_trip(test_client)

    response = test_client.patch(
        f"/trips/{created['id']}",
        json={
            "name": "Viaje nuevo",
            "start_date": "2026-07-01",
            "end_date": "2026-07-05",
            "description": "Otra descripcion",
            "image_url": "https://example.com/img.jpg",
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == created["id"]
    assert data["name"] == "Viaje nuevo"
    assert data["start_date"] == "2026-07-01"
    assert data["end_date"] == "2026-07-05"
    assert data["description"] == "Otra descripcion"
    assert data["image_url"] == "https://example.com/img.jpg"

    fetched = test_client.get(f"/trips/{created['id']}").json()
    assert fetched["name"] == "Viaje nuevo"
    assert fetched["image_url"] == "https://example.com/img.jpg"


def test_update_trip_not_found_returns_404(test_client):
    response = test_client.patch(
        "/trips/nonexistent",
        json=_valid_trip(),
    )

    assert response.status_code == 404


def test_update_trip_invalid_dates_returns_422(test_client):
    created = _create_trip(test_client)

    response = test_client.patch(
        f"/trips/{created['id']}",
        json=_valid_trip(start_date="2026-06-10", end_date="2026-06-01"),
    )

    assert response.status_code == 422


def test_update_trip_with_image_url_null_removes_image(test_client):
    created = _create_trip(
        test_client, image_url="https://example.com/img.jpg"
    )

    response = test_client.patch(
        f"/trips/{created['id']}",
        json=_valid_trip(image_url=None),
    )

    assert response.status_code == 200
    assert response.json()["image_url"] is None


def test_delete_trip_returns_204_and_removes(test_client):
    created = _create_trip(test_client)

    response = test_client.delete(f"/trips/{created['id']}")

    assert response.status_code == 204
    assert test_client.get("/trips").json() == []
    assert test_client.get(f"/trips/{created['id']}").status_code == 404


def test_delete_trip_not_found_returns_404(test_client):
    response = test_client.delete("/trips/nonexistent")

    assert response.status_code == 404


def test_create_trip_with_external_image_url(test_client):
    created = _create_trip(
        test_client, image_url="https://example.com/photo.jpg"
    )

    assert created["image_url"] == "https://example.com/photo.jpg"


def test_create_trip_without_image(test_client):
    created = _create_trip(test_client)

    assert created["image_url"] is None


def test_duplicate_names_allowed(test_client):
    first = _create_trip(test_client, name="Mismo nombre")
    second = _create_trip(test_client, name="Mismo nombre")

    assert first["name"] == second["name"]
    assert first["id"] != second["id"]
    assert len(test_client.get("/trips").json()) == 2
