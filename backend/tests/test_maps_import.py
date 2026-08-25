import pytest
from pydantic import ValidationError

from backend.schemas import MapCoordsResponse, MapUrlRequest


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