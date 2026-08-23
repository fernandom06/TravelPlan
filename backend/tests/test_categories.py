def test_list_categories(test_client):
    response = test_client.get("/categories")

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 4
    for category in data:
        assert isinstance(category["id"], int)
        assert isinstance(category["name"], str)


def test_create_category_returns_201_and_persists(test_client):
    response = test_client.post("/categories", json={"name": "Playa"})

    assert response.status_code == 201
    data = response.json()
    assert isinstance(data["id"], int)
    assert data["name"] == "Playa"

    listing = test_client.get("/categories").json()
    assert any(c["name"] == "Playa" for c in listing)


def test_create_category_duplicate_returns_409(test_client):
    response = test_client.post("/categories", json={"name": "Naturaleza"})

    assert response.status_code == 409


def test_create_category_empty_name_returns_422(test_client):
    response = test_client.post("/categories", json={"name": ""})

    assert response.status_code == 422


def test_create_category_only_spaces_returns_422(test_client):
    response = test_client.post("/categories", json={"name": "   "})

    assert response.status_code == 422


def test_create_category_too_long_returns_422(test_client):
    response = test_client.post("/categories", json={"name": "x" * 101})

    assert response.status_code == 422


def test_created_category_assignable_to_place(test_client):
    category = test_client.post("/categories", json={"name": "Playa"}).json()

    response = test_client.post(
        "/places",
        json={
            "name": "Cala del moro",
            "category_id": category["id"],
            "description": "Agua turquesa",
            "latitude": 42.5,
            "longitude": -3.1,
        },
    )

    assert response.status_code == 201
    assert response.json()["category"]["id"] == category["id"]
