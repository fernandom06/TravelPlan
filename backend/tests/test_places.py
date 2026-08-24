def _create_category(client, name="Naturaleza"):
    return client.post("/categories", json={"name": name}).json()


def _valid_place(category_id):
    return {
        "name": "Mirador del Canon",
        "category_id": category_id,
        "description": "Vistas del canon",
        "latitude": 42.5,
        "longitude": -3.1,
    }


def test_list_places_empty(test_client):
    response = test_client.get("/places")

    assert response.status_code == 200
    assert response.json() == []


def test_create_place(test_client):
    category = _create_category(test_client)

    response = test_client.post("/places", json=_valid_place(category["id"]))

    assert response.status_code == 201
    data = response.json()
    assert data["id"] is not None
    assert data["name"] == "Mirador del Canon"
    assert data["latitude"] == 42.5
    assert data["longitude"] == -3.1
    assert data["category"]["id"] == category["id"]
    assert data["category"]["name"] == category["name"]


def test_list_places_after_create(test_client):
    category = _create_category(test_client)
    test_client.post("/places", json=_valid_place(category["id"]))

    response = test_client.get("/places")

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_get_place_by_id(test_client):
    category = _create_category(test_client)
    created = test_client.post("/places", json=_valid_place(category["id"])).json()

    response = test_client.get(f"/places/{created['id']}")

    assert response.status_code == 200
    assert response.json()["id"] == created["id"]


def test_get_place_not_found(test_client):
    response = test_client.get("/places/9999")

    assert response.status_code == 404


def test_create_place_unknown_category(test_client):
    response = test_client.post("/places", json=_valid_place(9999))

    assert response.status_code == 404


def test_create_place_empty_name(test_client):
    category = _create_category(test_client)
    payload = _valid_place(category["id"])
    payload["name"] = ""

    response = test_client.post("/places", json=payload)

    assert response.status_code == 422


def test_create_place_missing_coordinates(test_client):
    category = _create_category(test_client)
    payload = _valid_place(category["id"])
    del payload["latitude"]
    del payload["longitude"]

    response = test_client.post("/places", json=payload)

    assert response.status_code == 422


def test_place_response_includes_category_icon(test_client):
    category = test_client.post(
        "/categories", json={"name": "Playa", "icon": "beach"}
    ).json()

    created = test_client.post("/places", json=_valid_place(category["id"])).json()

    assert created["category"]["icon"] == "beach"

    listing = test_client.get("/places").json()
    assert listing[0]["category"]["icon"] == "beach"

    fetched = test_client.get(f"/places/{created['id']}").json()
    assert fetched["category"]["icon"] == "beach"


def _create_place(client, category_id):
    response = client.post("/places", json=_valid_place(category_id))
    assert response.status_code == 201
    return response.json()


def test_update_place_returns_200_and_persists(test_client):
    category = _create_category(test_client)
    other = _create_category(test_client, name="Monumento")
    created = _create_place(test_client, category["id"])

    response = test_client.patch(
        f"/places/{created['id']}",
        json={
            "name": "Mirador nuevo",
            "description": "Otra vista",
            "category_id": other["id"],
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == created["id"]
    assert data["name"] == "Mirador nuevo"
    assert data["description"] == "Otra vista"
    assert data["category"]["id"] == other["id"]
    assert data["category"]["name"] == other["name"]

    fetched = test_client.get(f"/places/{created['id']}").json()
    assert fetched["name"] == "Mirador nuevo"
    assert fetched["description"] == "Otra vista"
    assert fetched["category"]["id"] == other["id"]


def test_update_place_not_found_returns_404(test_client):
    response = test_client.patch("/places/9999", json={"name": "X", "category_id": 1})

    assert response.status_code == 404


def test_update_place_unknown_category_returns_404(test_client):
    category = _create_category(test_client)
    created = _create_place(test_client, category["id"])

    response = test_client.patch(
        f"/places/{created['id']}",
        json={"name": "X", "category_id": 9999},
    )

    assert response.status_code == 404


def test_update_place_empty_name_returns_422(test_client):
    category = _create_category(test_client)
    created = _create_place(test_client, category["id"])

    response = test_client.patch(
        f"/places/{created['id']}",
        json={"name": "", "category_id": category["id"]},
    )

    assert response.status_code == 422


def test_update_place_keeps_coordinates(test_client):
    category = _create_category(test_client)
    created = _create_place(test_client, category["id"])

    response = test_client.patch(
        f"/places/{created['id']}",
        json={"name": "Renombrado", "category_id": category["id"]},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["latitude"] == created["latitude"]
    assert data["longitude"] == created["longitude"]


def test_update_place_ignores_extra_fields(test_client):
    category = _create_category(test_client)
    created = _create_place(test_client, category["id"])

    response = test_client.patch(
        f"/places/{created['id']}",
        json={
            "name": "Renombrado",
            "category_id": category["id"],
            "latitude": 1.0,
            "longitude": 2.0,
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert data["latitude"] == created["latitude"]
    assert data["longitude"] == created["longitude"]


def test_delete_place_returns_204_and_removes(test_client):
    category = _create_category(test_client)
    created = _create_place(test_client, category["id"])

    response = test_client.delete(f"/places/{created['id']}")

    assert response.status_code == 204
    ids = [p["id"] for p in test_client.get("/places").json()]
    assert created["id"] not in ids
    assert test_client.get(f"/places/{created['id']}").status_code == 404


def test_delete_place_not_found_returns_404(test_client):
    response = test_client.delete("/places/9999")

    assert response.status_code == 404
