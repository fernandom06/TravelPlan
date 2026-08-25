from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from . import config
from .categories import router as categories_router
from .database import init_database
from .maps_import import router as maps_router
from .places import router as places_router
from .schemas import HealthResponse
from .trips import router as trips_router
from .uploads import router as uploads_router


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    init_database()
    config.UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
    yield


app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(categories_router)
app.include_router(places_router)
app.include_router(trips_router)
app.include_router(uploads_router)
app.include_router(maps_router)


@app.api_route("/health", methods=["GET", "HEAD"])
def health() -> HealthResponse:
    return HealthResponse(status="healthy")


@app.get("/")
def read_root():
    return {"message": "Hello World"}
