import re

import httpx
from fastapi import APIRouter, HTTPException, status

from .schemas import MapCoordsResponse, MapUrlRequest

router = APIRouter(prefix="/maps", tags=["maps"])

_BROWSER_USER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/126.0 Safari/537.36"
)

_COORDS_PATTERN = re.compile(r"!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)")


def parse_maps_coords(url: str) -> tuple[float, float] | None:
    """Extract the last `!3d<lat>!4d<lng>` pair from a Google Maps URL."""
    matches = _COORDS_PATTERN.findall(url)
    if not matches:
        return None
    lat, lng = matches[-1]
    return float(lat), float(lng)


def follow_redirect(url: str, *, timeout: float = 8.0) -> str:
    """Resolve a short link to its final URL following redirects."""
    with httpx.Client(
        follow_redirects=True,
        timeout=timeout,
        headers={"User-Agent": _BROWSER_USER_AGENT},
    ) as client:
        return str(client.get(url).url)


@router.post("/resolve-url", response_model=MapCoordsResponse)
def resolve_url(payload: MapUrlRequest) -> MapCoordsResponse:
    try:
        final_url = follow_redirect(payload.url)
    except httpx.HTTPError:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="No se pudo resolver el enlace",
        )
    coords = parse_maps_coords(final_url)
    if coords is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="No se pudieron extraer coordenadas",
        )
    latitude, longitude = coords
    if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Coordenadas fuera de rango",
        )
    return MapCoordsResponse(latitude=latitude, longitude=longitude)