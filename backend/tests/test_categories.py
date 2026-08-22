def test_list_categories(test_client):
    response = test_client.get("/categories")

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 4
    for category in data:
        assert isinstance(category["id"], int)
        assert isinstance(category["name"], str)
