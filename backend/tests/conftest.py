import sqlite3

import pytest
from fastapi.testclient import TestClient

from backend.database import get_db, init_db
from backend.main import app


@pytest.fixture
def db_conn(monkeypatch):
    monkeypatch.setattr("backend.main.init_database", lambda: None)

    conn = sqlite3.connect(":memory:", check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    init_db(conn)
    yield conn
    conn.close()


@pytest.fixture
def test_client(db_conn):
    def override_get_db():
        yield db_conn

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()
