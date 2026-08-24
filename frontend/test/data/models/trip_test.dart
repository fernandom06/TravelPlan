import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/trip.dart';

void main() {
  group('Trip', () {
    final json = {
      'id': 'abc-123',
      'name': 'Viaje a Galicia',
      'description': 'Costas y comida',
      'start_date': '2026-06-01',
      'end_date': '2026-06-10',
      'image_url': '/uploads/x.jpg',
      'created_at': '2026-01-01 00:00:00',
    };

    test('fromJson parses all fields including null image_url', () {
      final trip = Trip.fromJson(json);

      expect(trip.id, 'abc-123');
      expect(trip.name, 'Viaje a Galicia');
      expect(trip.description, 'Costas y comida');
      expect(trip.startDate, DateTime(2026, 6, 1));
      expect(trip.endDate, DateTime(2026, 6, 10));
      expect(trip.imageUrl, '/uploads/x.jpg');
      expect(trip.createdAt, '2026-01-01 00:00:00');
    });

    test('fromJson handles null image_url', () {
      final trip = Trip.fromJson({...json, 'image_url': null});

      expect(trip.imageUrl, isNull);
    });

    test('toJson round-trips', () {
      final trip = Trip.fromJson(json);

      expect(trip.toJson(), json);
    });

    test('trips with same id are equal', () {
      final a = Trip.fromJson(json);
      final b = Trip.fromJson({...json, 'name': 'Otro'});

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('trips with different id are not equal', () {
      final a = Trip.fromJson(json);
      final b = Trip.fromJson({...json, 'id': 'other'});

      expect(a, isNot(b));
    });

    test('displayImageUrl prepends baseUrl for relative url', () {
      final trip = Trip.fromJson(json);

      expect(
        trip.displayImageUrl('http://localhost:8000'),
        'http://localhost:8000/uploads/x.jpg',
      );
    });

    test('displayImageUrl leaves absolute url intact', () {
      final trip = Trip.fromJson({
        ...json,
        'image_url': 'https://example.com/photo.jpg',
      });

      expect(
        trip.displayImageUrl('http://localhost:8000'),
        'https://example.com/photo.jpg',
      );
    });

    test('imageIsRelative is true for relative url', () {
      final trip = Trip.fromJson(json);

      expect(trip.imageIsRelative, isTrue);
    });

    test('imageIsRelative is false for absolute url', () {
      final trip = Trip.fromJson({
        ...json,
        'image_url': 'https://example.com/photo.jpg',
      });

      expect(trip.imageIsRelative, isFalse);
    });
  });
}
