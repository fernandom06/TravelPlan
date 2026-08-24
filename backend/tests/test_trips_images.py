def _jpeg_bytes() -> bytes:
    return b"\xff\xd8\xff\xe0" + b"\x00" * 100


def _png_bytes() -> bytes:
    return b"\x89PNG\r\n\x1a\n" + b"\x00" * 100


def _webp_bytes() -> bytes:
    return b"RIFF\x00\x00\x00\x00WEBPVP8 " + b"\x00" * 100


def test_upload_valid_jpeg(test_client, tmp_path, monkeypatch):
    monkeypatch.setattr("backend.config.UPLOADS_DIR", tmp_path / "uploads")

    response = test_client.post(
        "/trips/images",
        files={"file": ("foto.jpg", _jpeg_bytes(), "image/jpeg")},
    )

    assert response.status_code == 201
    data = response.json()
    assert data["url"].startswith("/uploads/")

    filename = data["url"].split("/")[-1]
    saved = tmp_path / "uploads" / filename
    assert saved.exists()

    fetched = test_client.get(data["url"])
    assert fetched.status_code == 200
    assert fetched.headers["content-type"] == "image/jpeg"


def test_upload_valid_png_and_webp(test_client, tmp_path, monkeypatch):
    monkeypatch.setattr("backend.config.UPLOADS_DIR", tmp_path / "uploads")

    for name, content, content_type, ext in [
        ("a.png", _png_bytes(), "image/png", ".png"),
        ("a.webp", _webp_bytes(), "image/webp", ".webp"),
    ]:
        response = test_client.post(
            "/trips/images",
            files={"file": (name, content, content_type)},
        )
        assert response.status_code == 201
        url = response.json()["url"]
        assert url.endswith(ext)
        assert (tmp_path / "uploads" / url.split("/")[-1]).exists()


def test_upload_too_large_returns_413(test_client, tmp_path, monkeypatch):
    monkeypatch.setattr("backend.config.UPLOADS_DIR", tmp_path / "uploads")
    monkeypatch.setattr("backend.config.MAX_IMAGE_SIZE_BYTES", 100)

    response = test_client.post(
        "/trips/images",
        files={"file": ("big.jpg", b"\xff" * 200, "image/jpeg")},
    )

    assert response.status_code == 413


def test_upload_unsupported_content_type_returns_415(test_client, tmp_path, monkeypatch):
    monkeypatch.setattr("backend.config.UPLOADS_DIR", tmp_path / "uploads")

    response = test_client.post(
        "/trips/images",
        files={"file": ("a.gif", b"GIF89a", "image/gif")},
    )

    assert response.status_code == 415


def test_get_upload_inexistent_returns_404(test_client, tmp_path, monkeypatch):
    monkeypatch.setattr("backend.config.UPLOADS_DIR", tmp_path / "uploads")

    response = test_client.get("/uploads/noexiste.jpg")

    assert response.status_code == 404


def test_get_upload_path_traversal_blocked(test_client, tmp_path, monkeypatch):
    uploads = tmp_path / "uploads"
    uploads.mkdir()
    secret = tmp_path / "secret.txt"
    secret.write_text("confidential")
    monkeypatch.setattr("backend.config.UPLOADS_DIR", uploads)

    response = test_client.get("/uploads/../secret.txt")

    assert response.status_code == 404
