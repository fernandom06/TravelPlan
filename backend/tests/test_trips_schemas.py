from datetime import date

import pytest
from pydantic import ValidationError

from backend.schemas import ImageUploadResponse, TripCreate, TripResponse, TripUpdate


def test_trip_create_valid():
    trip = TripCreate(
        name="Viaje a Galicia",
        start_date=date(2026, 6, 1),
        end_date=date(2026, 6, 10),
        description="Costas y comida",
        image_url="/uploads/x.jpg",
    )

    assert trip.name == "Viaje a Galicia"
    assert trip.start_date == date(2026, 6, 1)
    assert trip.end_date == date(2026, 6, 10)
    assert trip.description == "Costas y comida"
    assert trip.image_url == "/uploads/x.jpg"


def test_trip_create_end_before_start_rejected():
    with pytest.raises(ValidationError):
        TripCreate(
            name="Viaje",
            start_date=date(2026, 6, 10),
            end_date=date(2026, 6, 1),
        )


def test_trip_create_empty_name_rejected():
    with pytest.raises(ValidationError):
        TripCreate(
            name="",
            start_date=date(2026, 6, 1),
            end_date=date(2026, 6, 10),
        )


def test_trip_create_image_url_none_valid():
    trip = TripCreate(
        name="Viaje",
        start_date=date(2026, 6, 1),
        end_date=date(2026, 6, 10),
    )

    assert trip.image_url is None


def test_trip_update_validates_dates():
    with pytest.raises(ValidationError):
        TripUpdate(
            name="Viaje",
            start_date=date(2026, 6, 10),
            end_date=date(2026, 6, 1),
        )


def test_trip_response_serializes_start_date_iso():
    trip = TripResponse(
        id="abc",
        name="Viaje",
        start_date=date(2026, 6, 1),
        end_date=date(2026, 6, 10),
        description=None,
        image_url=None,
        created_at="2026-01-01 00:00:00",
    )

    data = trip.model_dump(mode="json")
    assert data["start_date"] == "2026-06-01"
    assert data["end_date"] == "2026-06-10"


def test_image_upload_response():
    resp = ImageUploadResponse(url="/uploads/x.jpg")
    assert resp.url == "/uploads/x.jpg"
