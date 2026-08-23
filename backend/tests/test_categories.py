def test_list_categories(test_client):
    response = test_client.get("/categories")

    assert response.status_code == 200
    assert response.json() == []


def test_create_category_returns_201_and_persists(test_client):
    response = test_client.post("/categories", json={"name": "Playa"})

    assert response.status_code == 201
    data = response.json()
    assert isinstance(data["id"], int)
    assert data["name"] == "Playa"

    listing = test_client.get("/categories").json()
    assert any(c["name"] == "Playa" for c in listing)


def test_create_category_duplicate_returns_409(test_client):
    test_client.post("/categories", json={"name": "Naturaleza"})

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


def test_rename_category_returns_200_and_persists(test_client):
    created = test_client.post("/categories", json={"name": "Playa"}).json()

    response = test_client.patch(
        f"/categories/{created['id']}", json={"name": "Costa"}
    )

    assert response.status_code == 200
    assert response.json() == {"id": created["id"], "name": "Costa"}
    listing = test_client.get("/categories").json()
    assert any(c["name"] == "Costa" for c in listing)
    assert all(c["name"] != "Playa" for c in listing)


def test_rename_category_not_found_returns_404(test_client):
    response = test_client.patch("/categories/9999", json={"name": "Costa"})

    assert response.status_code == 404


def test_rename_category_duplicate_returns_409(test_client):
    a = test_client.post("/categories", json={"name": "A"}).json()
    test_client.post("/categories", json={"name": "B"})

    response = test_client.patch(f"/categories/{a['id']}", json={"name": "B"})

    assert response.status_code == 409


def test_rename_category_empty_name_returns_422(test_client):
    created = test_client.post("/categories", json={"name": "Playa"}).json()

    response = test_client.patch(
        f"/categories/{created['id']}", json={"name": ""}
    )

    assert response.status_code == 422


def test_rename_category_only_spaces_returns_422(test_client):
    created = test_client.post("/categories", json={"name": "Playa"}).json()

    response = test_client.patch(
        f"/categories/{created['id']}", json={"name": "   "}
    )

    assert response.status_code == 422


def test_rename_category_too_long_returns_422(test_client):
    created = test_client.post("/categories", json={"name": "Playa"}).json()

    response = test_client.patch(
        f"/categories/{created['id']}", json={"name": "x" * 101}
    )

    assert response.status_code == 422


def test_rename_category_same_name_returns_200(test_client):
    created = test_client.post("/categories", json={"name": "A"}).json()

    response = test_client.patch(f"/categories/{created['id']}", json={"name": "A"})

    assert response.status_code == 200
    assert response.json() == {"id": created["id"], "name": "A"}


def test_rename_propagates_to_places(test_client):
    category = test_client.post("/categories", json={"name": "Playa"}).json()
    test_client.post(
        "/places",
        json={
            "name": "Cala del moro",
            "category_id": category["id"],
            "latitude": 42.5,
            "longitude": -3.1,
        },
    )

    response = test_client.patch(
        f"/categories/{category['id']}", json={"name": "Costa"}
    )
    assert response.status_code == 200

    places = test_client.get("/places").json()
    assert len(places) == 1
    assert places[0]["category"]["name"] == "Costa"


def test_delete_category_without_places_returns_204(test_client):
    created = test_client.post("/categories", json={"name": "Playa"}).json()

    response = test_client.delete(f"/categories/{created['id']}")

    assert response.status_code == 204
    assert test_client.get("/categories").json() == []


def test_delete_category_not_found_returns_404(test_client):
    response = test_client.delete("/categories/9999")

    assert response.status_code == 404


def test_delete_category_with_places_no_reassign_returns_409(test_client):
    category = test_client.post("/categories", json={"name": "Playa"}).json()
    test_client.post(
        "/places",
        json={
            "name": "Cala del moro",
            "category_id": category["id"],
            "latitude": 42.5,
            "longitude": -3.1,
        },
    )

    response = test_client.delete(f"/categories/{category['id']}")

    assert response.status_code == 409
    listing = test_client.get("/categories").json()
    assert any(c["id"] == category["id"] for c in listing)
    assert len(test_client.get("/places").json()) == 1


def test_delete_category_with_places_reassigns_places_and_deletes(test_client):
    a = test_client.post("/categories", json={"name": "A"}).json()
    b = test_client.post("/categories", json={"name": "B"}).json()
    place = test_client.post(
        "/places",
        json={
            "name": "Cala del moro",
            "category_id": a["id"],
            "latitude": 42.5,
            "longitude": -3.1,
        },
    ).json()

    response = test_client.delete(f"/categories/{a['id']}?reassign_to={b['id']}")

    assert response.status_code == 204
    listing = test_client.get("/categories").json()
    assert [c["id"] for c in listing] == [b["id"]]
    places = test_client.get("/places").json()
    assert len(places) == 1
    assert places[0]["id"] == place["id"]
    assert places[0]["category"]["id"] == b["id"]


def test_delete_category_reassign_to_same_returns_422(test_client):
    created = test_client.post("/categories", json={"name": "A"}).json()
    test_client.post(
        "/places",
        json={
            "name": "Cala del moro",
            "category_id": created["id"],
            "latitude": 42.5,
            "longitude": -3.1,
        },
    )

    response = test_client.delete(
        f"/categories/{created['id']}?reassign_to={created['id']}"
    )

    assert response.status_code == 422


def test_delete_category_reassign_to_nonexistent_returns_422(test_client):
    created = test_client.post("/categories", json={"name": "A"}).json()
    test_client.post(
        "/places",
        json={
            "name": "Cala del moro",
            "category_id": created["id"],
            "latitude": 42.5,
            "longitude": -3.1,
        },
    )

    response = test_client.delete(f"/categories/{created['id']}?reassign_to=9999")

    assert response.status_code == 422


def test_delete_only_category_with_places_returns_409(test_client):
    created = test_client.post("/categories", json={"name": "A"}).json()
    test_client.post(
        "/places",
        json={
            "name": "Cala del moro",
            "category_id": created["id"],
            "latitude": 42.5,
            "longitude": -3.1,
        },
    )

    response = test_client.delete(f"/categories/{created['id']}")

    assert response.status_code == 409
    assert len(test_client.get("/categories").json()) == 1
