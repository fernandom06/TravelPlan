from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .categories import router as categories_router
from .database import get_connection, init_db, seed_categories
from .places import router as places_router


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    conn = get_connection()
    try:
        init_db(conn)
        seed_categories(conn)
        conn.commit()
    finally:
        conn.close()
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


@app.get("/")
def read_root():
    return {"message": "Hello World"}
