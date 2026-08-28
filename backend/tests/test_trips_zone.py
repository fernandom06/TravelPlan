def _valid_trip(**overrides):
    payload = {
        "name": "Viaje a Galicia",
        "start_date": "2026-06-01",
        "end_date": "2026-06-10",
    }
    payload.update(overrides)
    return payload


def _square_zone():
    return {
        "points": [
            {"latitude": 42.0, "longitude": -4.0},
            {"latitude": 42.0, "longitude": -3.0},
            {"latitude": 43.0, "longitude": -3.0},
            {"latitude": 43.0, "longitude": -4.0},
        ]
    }


def test_create_trip_with_zone_less_than_3_points_returns_422(test_client):
    response = test_client.post(
        "/trips",
        json=_valid_trip(zone={"points": [
            {"latitude": 42.0, "longitude": -4.0},
            {"latitude": 42.0, "longitude": -3.0},
        ]}),
    )

    assert response.status_code == 422


def test_create_trip_with_zone_out_of_range_coords_returns_422(test_client):
    response = test_client.post(
        "/trips",
        json=_valid_trip(zone={"points": [
            {"latitude": 100.0, "longitude": -4.0},
            {"latitude": 42.0, "longitude": -3.0},
            {"latitude": 43.0, "longitude": -3.0},
        ]}),
    )

    assert response.status_code == 422


def test_create_trip_with_valid_zone_succeeds(test_client):
    response = test_client.post(
        "/trips",
        json=_valid_trip(zone=_square_zone()),
    )

    assert response.status_code == 201