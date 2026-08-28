from backend.schemas import ZonePoint
from backend.zones import point_in_polygon


def _pt(latitude, longitude):
    return ZonePoint(latitude=latitude, longitude=longitude)


def _square():
    return [
        _pt(42.0, -4.0),
        _pt(42.0, -3.0),
        _pt(43.0, -3.0),
        _pt(43.0, -4.0),
    ]


def test_point_inside_square():
    assert point_in_polygon(42.5, -3.5, _square()) is True


def test_point_outside_square():
    assert point_in_polygon(44.0, -3.5, _square()) is False
    assert point_in_polygon(42.5, -5.0, _square()) is False


def test_point_on_vertex_counts_as_inside():
    assert point_in_polygon(42.0, -4.0, _square()) is True


def test_point_on_horizontal_edge_counts_as_inside():
    assert point_in_polygon(42.0, -3.5, _square()) is True


def test_point_on_vertical_edge_counts_as_inside():
    assert point_in_polygon(42.5, -4.0, _square()) is True


def test_concave_polygon_distinguishes_regions():
    # Polígono en forma de C: la concavidad (zona central) queda fuera.
    concave = [
        _pt(0.0, 0.0),
        _pt(0.0, 4.0),
        _pt(4.0, 4.0),
        _pt(4.0, 3.0),
        _pt(1.0, 3.0),
        _pt(1.0, 1.0),
        _pt(4.0, 1.0),
        _pt(4.0, 0.0),
    ]
    assert point_in_polygon(2.0, 2.0, concave) is False  # en la concavidad
    assert point_in_polygon(0.5, 2.0, concave) is True  # en el brazo izquierdo
    assert point_in_polygon(2.0, 3.5, concave) is True  # en el brazo superior


def test_closed_ring_with_duplicate_first_point():
    points = [*_square(), _square()[0]]
    assert point_in_polygon(42.5, -3.5, points) is True
    assert point_in_polygon(44.0, -3.5, points) is False


def test_less_than_three_points_returns_false():
    assert point_in_polygon(42.5, -3.5, [_pt(42.0, -4.0)]) is False
    assert point_in_polygon(
        42.5, -3.5, [_pt(42.0, -4.0), _pt(42.0, -3.0)]
    ) is False


def test_collinear_points_return_false():
    collinear = [
        _pt(42.0, -4.0),
        _pt(42.0, -3.0),
        _pt(42.0, -2.0),
    ]
    assert point_in_polygon(42.5, -3.0, collinear) is False