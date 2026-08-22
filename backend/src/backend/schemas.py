from pydantic import BaseModel, Field


class CategoryResponse(BaseModel):
    id: int
    name: str


class PlaceCreate(BaseModel):
    name: str = Field(min_length=1)
    category_id: int
    description: str | None = None
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)


class PlaceResponse(BaseModel):
    id: int
    name: str
    description: str | None
    latitude: float
    longitude: float
    category: CategoryResponse
