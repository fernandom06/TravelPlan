import pytest
from pydantic import ValidationError

from backend.maps_import import parse_maps_coords
from backend.schemas import MapCoordsResponse, MapUrlRequest


class TestParseMapsCoords:
    def test_extracts_coords(self):
        result = parse_maps_coords(
            "https://www.google.com/maps/place/Zaragoza/"
            "@41.6474339,-0.8861451,17z/data=!3m1!4b1"
            "!4m6!3m5!1s0x0:0x0!8m2!3d41.6474339!4d-0.8861451"
        )
        assert result == (41.6474339, -0.8861451)

    def test_returns_none_without_coords(self):
        assert parse_maps_coords("https://www.google.com/maps/place/Zaragoza/") is None

    def test_takes_last_pair_when_multiple(self):
        result = parse_maps_coords(
            "https://www.google.com/maps/@41.1,-0.1,15z"
            "!3d41.6474339!4d-0.8861451"
        )
        assert result == (41.6474339, -0.8861451)

    def test_returns_out_of_range_values(self):
        result = parse_maps_coords("https://www.google.com/maps/@0,0,1z!3d91!4d200")
        assert result == (91.0, 200.0)


class TestMapUrlRequest:
    def test_accepts_https_url(self):
        payload = MapUrlRequest(url="https://maps.app.goo.gl/tpabGChzziYCfgjy5")
        assert payload.url == "https://maps.app.goo.gl/tpabGChzziYCfgjy5"

    def test_prepends_scheme_when_missing(self):
        payload = MapUrlRequest(url="maps.app.goo.gl/tpabGChzziYCfgjy5")
        assert payload.url == "https://maps.app.goo.gl/tpabGChzziYCfgjy5"

    def test_rejects_foreign_host(self):
        with pytest.raises(ValidationError):
            MapUrlRequest(url="https://example.com/x")

    def test_rejects_empty(self):
        with pytest.raises(ValidationError):
            MapUrlRequest(url="")

    def test_rejects_blank(self):
        with pytest.raises(ValidationError):
            MapUrlRequest(url="   ")


class TestMapCoordsResponse:
    def test_accepts_valid_coords(self):
        payload = MapCoordsResponse(latitude=41.6474339, longitude=-0.8861451)
        assert payload.latitude == 41.6474339
        assert payload.longitude == -0.8861451

    def test_rejects_latitude_out_of_range(self):
        with pytest.raises(ValidationError):
            MapCoordsResponse(latitude=91, longitude=0)

    def test_rejects_longitude_out_of_range(self):
        with pytest.raises(ValidationError):
            MapCoordsResponse(latitude=0, longitude=200)