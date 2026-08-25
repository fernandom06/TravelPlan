from datetime import date
from typing import Annotated
from urllib.parse import urlparse

from pydantic import (
    BaseModel,
    Field,
    StringConstraints,
    field_validator,
    model_validator,
)


class CategoryResponse(BaseModel):
    id: int
    name: str
    icon: str | None = None


class CategoryCreate(BaseModel):
    name: Annotated[
        str,
        StringConstraints(strip_whitespace=True, min_length=1, max_length=100),
    ]
    icon: (
        Annotated[str, StringConstraints(strip_whitespace=True, max_length=64)] | None
    ) = None


class PlaceCreate(BaseModel):
    name: str = Field(min_length=1)
    category_id: int
    description: str | None = None
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)


class PlaceUpdate(BaseModel):
    name: str = Field(min_length=1)
    category_id: int
    description: str | None = None


class PlaceResponse(BaseModel):
    id: int
    name: str
    description: str | None
    latitude: float
    longitude: float
    category: CategoryResponse


class TripResponse(BaseModel):
    id: str
    name: str
    description: str | None
    start_date: date
    end_date: date
    image_url: str | None
    created_at: str


class TripCreate(BaseModel):
    name: str = Field(min_length=1)
    start_date: date
    end_date: date
    description: str | None = None
    image_url: str | None = None

    @model_validator(mode="after")
    def _validate_dates(self):
        if self.end_date < self.start_date:
            raise ValueError("end_date must be on or after start_date")
        return self


class TripUpdate(BaseModel):
    name: str = Field(min_length=1)
    start_date: date
    end_date: date
    description: str | None = None
    image_url: str | None = None

    @model_validator(mode="after")
    def _validate_dates(self):
        if self.end_date < self.start_date:
            raise ValueError("end_date must be on or after start_date")
        return self


class ImageUploadResponse(BaseModel):
    url: str


class MapUrlRequest(BaseModel):
    url: str

    @field_validator("url")
    @classmethod
    def _validate_url(cls, v: str) -> str:
        v = v.strip()
        if v.startswith("maps.app.goo.gl"):
            v = f"https://{v}"
        if urlparse(v).hostname != "maps.app.goo.gl":
            raise ValueError("URL must point to maps.app.goo.gl")
        return v


class MapCoordsResponse(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)


class HealthResponse(BaseModel):
    status: str
