import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/trip_draft.dart';
import 'package:frontend/data/models/zone_point.dart';

const _points = [
  ZonePoint(latitude: 42.0, longitude: -4.0),
  ZonePoint(latitude: 43.0, longitude: -3.0),
  ZonePoint(latitude: 42.5, longitude: -3.5),
];

TripDraft _draft({List<ZonePoint>? zone}) => TripDraft(
  name: 'Viaje a Galicia',
  startDate: DateTime(2026, 6, 1),
  endDate: DateTime(2026, 6, 10),
  description: 'Costas',
  imageUrl: '/uploads/x.jpg',
  zone: zone,
);

void main() {
  group('TripDraft zone', () {
    test('toJson includes zone points when set', () {
      final json = _draft(zone: _points).toJson();

      expect(json['zone'], {
        'points': [
          {'latitude': 42.0, 'longitude': -4.0},
          {'latitude': 43.0, 'longitude': -3.0},
          {'latitude': 42.5, 'longitude': -3.5},
        ],
      });
    });

    test('toJson emits zone as null when omitted', () {
      final json = _draft().toJson();

      expect(json.containsKey('zone'), isTrue);
      expect(json['zone'], isNull);
    });

    test('copyWith with zone preserves base fields and sets zone', () {
      final updated = _draft().copyWith(zone: _points);

      expect(updated.name, 'Viaje a Galicia');
      expect(updated.startDate, DateTime(2026, 6, 1));
      expect(updated.endDate, DateTime(2026, 6, 10));
      expect(updated.description, 'Costas');
      expect(updated.imageUrl, '/uploads/x.jpg');
      expect(updated.zone, _points);
    });

    test('copyWith without zone keeps existing zone', () {
      final updated = _draft(zone: _points).copyWith();

      expect(updated.zone, _points);
    });
  });
}