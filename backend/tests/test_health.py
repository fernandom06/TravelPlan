def test_get_health_returns_200_and_payload(test_client):
    response = test_client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_head_health_returns_200_without_body(test_client):
    response = test_client.head("/health")

    assert response.status_code == 200
    assert response.content == b""


def test_unsupported_method_returns_405(test_client):
    response = test_client.post("/health")

    assert response.status_code == 405


def test_root_endpoint_unchanged(test_client):
    response = test_client.get("/")

    assert response.status_code == 200
    assert response.json() == {"message": "Hello World"}
