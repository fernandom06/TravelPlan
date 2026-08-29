import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/itinerary_item.dart';
import 'package:frontend/data/models/itinerary_slot.dart';
import 'package:frontend/data/models/place.dart';

Map<String, dynamic> _placeJson({int id = 1, String name = 'Mirador'}) => {
  'id': id,
  'name': name,
  'description': null,
  'latitude': 42.5,
  'longitude': -3.5,
  'category': {'id': 1, 'name': 'Naturaleza', 'icon': null},
};

void main() {
  test('fromJson parses a placed item', () {
    final item = ItineraryItem.fromJson({
      'id': 7,
      'day_date': '2026-06-01',
      'slot': 'morning',
      'position': 2,
      'place': _placeJson(),
    });

    expect(item.id, 7);
    expect(item.dayDate, DateTime(2026, 6, 1));
    expect(item.slot, ItinerarySlot.morning);
    expect(item.position, 2);
    expect(item.place, isA<Place>());
    expect(item.place.name, 'Mirador');
    expect(item.isUnassigned, isFalse);
  });

  test('fromJson parses a general-list item with null day and slot', () {
    final item = ItineraryItem.fromJson({
      'id': 3,
      'day_date': null,
      'slot': null,
      'position': 0,
      'place': _placeJson(),
    });

    expect(item.dayDate, isNull);
    expect(item.slot, isNull);
    expect(item.isUnassigned, isTrue);
  });

  test('toJson mirrors the response shape', () {
    final item = ItineraryItem.fromJson({
      'id': 7,
      'day_date': '2026-06-01',
      'slot': 'morning',
      'position': 2,
      'place': _placeJson(),
    });

    expect(item.toJson(), {
      'id': 7,
      'day_date': '2026-06-01',
      'slot': 'morning',
      'position': 2,
      'place': _placeJson(),
    });
  });

  test('equality is by id', () {
    final a = ItineraryItem.fromJson({
      'id': 1,
      'day_date': null,
      'slot': null,
      'position': 0,
      'place': _placeJson(),
    });
    final b = ItineraryItem.fromJson({
      'id': 1,
      'day_date': '2026-06-02',
      'slot': 'night',
      'position': 5,
      'place': _placeJson(name: 'Otro'),
    });

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
