def _valid_place(category_id=1):
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
    response = test_client.post("/places", json=_valid_place())

    assert response.status_code == 201
    data = response.json()
    assert data["id"] is not None
    assert data["name"] == "Mirador del Canon"
    assert data["latitude"] == 42.5
    assert data["longitude"] == -3.1
    assert data["category"]["id"] == 1
    assert data["category"]["name"] == "Naturaleza"


def test_list_places_after_create(test_client):
    test_client.post("/places", json=_valid_place())

    response = test_client.get("/places")

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_get_place_by_id(test_client):
    created = test_client.post("/places", json=_valid_place()).json()

    response = test_client.get(f"/places/{created['id']}")

    assert response.status_code == 200
    assert response.json()["id"] == created["id"]


def test_get_place_not_found(test_client):
    response = test_client.get("/places/9999")

    assert response.status_code == 404


def test_create_place_unknown_category(test_client):
    response = test_client.post("/places", json=_valid_place(category_id=9999))

    assert response.status_code == 404


def test_create_place_empty_name(test_client):
    payload = _valid_place()
    payload["name"] = ""

    response = test_client.post("/places", json=payload)

    assert response.status_code == 422


def test_create_place_missing_coordinates(test_client):
    payload = _valid_place()
    del payload["latitude"]
    del payload["longitude"]

    response = test_client.post("/places", json=payload)

    assert response.status_code == 422
