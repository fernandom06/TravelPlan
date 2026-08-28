import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/itinerary_slot.dart';

void main() {
  test('ItinerarySlot exposes wire values', () {
    expect(ItinerarySlot.morning.wireValue, 'morning');
    expect(ItinerarySlot.afternoon.wireValue, 'afternoon');
    expect(ItinerarySlot.night.wireValue, 'night');
  });

  test('ItinerarySlot exposes spanish labels', () {
    expect(ItinerarySlot.morning.label, 'Mañana');
    expect(ItinerarySlot.afternoon.label, 'Tarde');
    expect(ItinerarySlot.night.label, 'Noche');
  });

  test('fromWireValue parses known strings', () {
    expect(ItinerarySlot.fromWireValue('morning'), ItinerarySlot.morning);
    expect(ItinerarySlot.fromWireValue('afternoon'), ItinerarySlot.afternoon);
    expect(ItinerarySlot.fromWireValue('night'), ItinerarySlot.night);
  });

  test('fromWireValue returns null for unknown or null', () {
    expect(ItinerarySlot.fromWireValue('evening'), isNull);
    expect(ItinerarySlot.fromWireValue(null), isNull);
  });

  test('there are exactly three slots', () {
    expect(ItinerarySlot.values, hasLength(3));
  });
}