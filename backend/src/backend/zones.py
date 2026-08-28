import sqlite3

from .schemas import ZonePoint


def point_in_polygon(
    latitude: float, longitude: float, points: list[ZonePoint]
) -> bool:
    """Ray casting determinista sobre un polígono definido por vértices.

    - Se acepta un anillo cerrado: si el primer vértice coincide con el último,
      el duplicado se ignora.
    - Con menos de 3 vértices (tras ignorar el duplicado) devuelve ``False``.
    - Un punto situado exactamente sobre una arista o un vértice se considera
      dentro del polígono (comprobación de pertenencia a segmento previa al
      conteo de intersecciones).
    - No se manejan antimeridiano ni polos; la app opera en una región local.
    """
    pts = points
    if len(pts) > 1 and pts[0] == pts[-1]:
        pts = pts[:-1]
    if len(pts) < 3:
        return False

    inside = False
    n = len(pts)
    for i in range(n):
        a = pts[i]
        b = pts[(i + 1) % n]
        if _on_segment(latitude, longitude, a, b):
            return True
        if (a.latitude > latitude) != (b.latitude > latitude):
            intersection = a.longitude + (
                latitude - a.latitude
            ) * (b.longitude - a.longitude) / (b.latitude - a.latitude)
            if longitude < intersection:
                inside = not inside
    return inside


def _on_segment(
    latitude: float, longitude: float, a: ZonePoint, b: ZonePoint
) -> bool:
    cross = (longitude - a.longitude) * (b.latitude - a.latitude) - (
        latitude - a.latitude
    ) * (b.longitude - a.longitude)
    if abs(cross) > 1e-9:
        return False
    return (
        min(a.latitude, b.latitude) - 1e-9
        <= latitude
        <= max(a.latitude, b.latitude) + 1e-9
        and min(a.longitude, b.longitude) - 1e-9
        <= longitude
        <= max(a.longitude, b.longitude) + 1e-9
    )


def link_places_in_zone(
    conn: sqlite3.Connection, trip_id: str, points: list[ZonePoint]
) -> int:
    """Vincula a ``trip_places`` los places que caen dentro de la zona.

    No hace commit propio: la transacción la cierra el router. La PK
    ``(trip_id, place_id)`` descarta duplicados si se llama dos veces.
    """
    rows = conn.execute(
        "SELECT id, latitude, longitude FROM places"
    ).fetchall()
    linked = 0
    for row in rows:
        if point_in_polygon(row["latitude"], row["longitude"], points):
            conn.execute(
                "INSERT INTO trip_places (trip_id, place_id) VALUES (?, ?)",
                (trip_id, row["id"]),
            )
            linked += 1
    return linked