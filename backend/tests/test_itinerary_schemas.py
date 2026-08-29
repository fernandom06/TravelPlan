from datetime import date

import pytest
from pydantic import ValidationError

from backend.schemas import (
    ItineraryItemCreate,
    ItineraryItemMove,
    ItinerarySlot,
)


def test_itinerary_slot_accepts_only_three_values():
    assert ItinerarySlot("morning").value == "morning"
    assert ItinerarySlot("afternoon").value == "afternoon"
    assert ItinerarySlot("night").value == "night"

    with pytest.raises(ValueError):
        ItinerarySlot("evening")


def test_itinerary_item_create_requires_place_id():
    item = ItineraryItemCreate(place_id=3)

    assert item.place_id == 3


def test_itinerary_item_create_rejects_missing_place_id():
    with pytest.raises(ValidationError):
        ItineraryItemCreate()


def test_itinerary_item_move_accepts_general_list_target():
    move = ItineraryItemMove(day_date=None, slot=None, position=0)

    assert move.day_date is None
    assert move.slot is None
    assert move.position == 0


def test_itinerary_item_move_accepts_placed_target():
    move = ItineraryItemMove(
        day_date=date(2026, 6, 1), slot=ItinerarySlot("morning"), position=2
    )

    assert move.day_date == date(2026, 6, 1)
    assert move.slot == ItinerarySlot("morning")
    assert move.position == 2


def test_itinerary_item_move_rejects_negative_position():
    with pytest.raises(ValidationError):
        ItineraryItemMove(day_date=None, slot=None, position=-1)


def test_itinerary_item_move_rejects_invalid_slot():
    with pytest.raises(ValidationError):
        ItineraryItemMove(day_date=None, slot="evening", position=0)


def test_itinerary_item_move_rejects_mixed_placement():
    # Convención: colocado ⇒ ambos con valor; sin colocar ⇒ ambos NULL.
    with pytest.raises(ValidationError):
        ItineraryItemMove(day_date=date(2026, 6, 1), slot=None, position=0)
    with pytest.raises(ValidationError):
        ItineraryItemMove(day_date=None, slot=ItinerarySlot("night"), position=0)