import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';

void main() {
  group('Place', () {
    final json = {
      'id': 1,
      'name': 'Mirador',
      'description': 'Vistas del canon',
      'latitude': 42.5,
      'longitude': -3.1,
      'category': {'id': 2, 'name': 'Monumento'},
    };

    test('fromJson parses all fields including nested category', () {
      final place = Place.fromJson(json);

      expect(place.id, 1);
      expect(place.name, 'Mirador');
      expect(place.description, 'Vistas del canon');
      expect(place.latitude, 42.5);
      expect(place.longitude, -3.1);
      expect(place.category.id, 2);
      expect(place.category.name, 'Monumento');
    });

    test('fromJson handles a null description', () {
      final place = Place.fromJson({...json, 'description': null});

      expect(place.description, isNull);
    });

    test('toJson produces the expected map', () {
      const place = Place(
        id: 1,
        name: 'Mirador',
        description: 'Vistas del canon',
        latitude: 42.5,
        longitude: -3.1,
        category: Category(id: 2, name: 'Monumento'),
      );

      expect(place.toJson(), {
        'id': 1,
        'name': 'Mirador',
        'description': 'Vistas del canon',
        'latitude': 42.5,
        'longitude': -3.1,
        'category': {'id': 2, 'name': 'Monumento', 'icon': null},
      });
    });

    test('latLng getter returns LatLng(latitude, longitude)', () {
      const place = Place(
        id: 1,
        name: 'Mirador',
        description: null,
        latitude: 42.5,
        longitude: -3.1,
        category: Category(id: 2, name: 'Monumento'),
      );

      expect(place.latLng, const LatLng(42.5, -3.1));
    });

    test('places with same id are equal', () {
      const a = Place(
        id: 1,
        name: 'Mirador',
        description: null,
        latitude: 42.5,
        longitude: -3.1,
        category: Category(id: 2, name: 'Monumento'),
      );
      const b = Place(
        id: 1,
        name: 'Otro nombre',
        description: 'x',
        latitude: 1.0,
        longitude: 2.0,
        category: Category(id: 3, name: 'Restaurante'),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('places with different id are not equal', () {
      const a = Place(
        id: 1,
        name: 'Mirador',
        description: null,
        latitude: 42.5,
        longitude: -3.1,
        category: Category(id: 2, name: 'Monumento'),
      );
      const b = Place(
        id: 2,
        name: 'Mirador',
        description: null,
        latitude: 42.5,
        longitude: -3.1,
        category: Category(id: 2, name: 'Monumento'),
      );

      expect(a, isNot(b));
    });
  });
}
