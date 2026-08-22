import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/place_api.dart';

void main() {
  group('PlaceApi', () {
    test('fetchCategories returns parsed categories', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/categories');
        return http.Response(
          jsonEncode([
            {'id': 1, 'name': 'Naturaleza'},
            {'id': 2, 'name': 'Monumento'},
          ]),
          200,
        );
      });
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      final categories = await api.fetchCategories();

      expect(categories, hasLength(2));
      expect(categories.first, const Category(id: 1, name: 'Naturaleza'));
    });

    test('fetchPlaces returns parsed places', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/places');
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'name': 'Mirador',
              'description': null,
              'latitude': 42.5,
              'longitude': -3.1,
              'category': {'id': 1, 'name': 'Naturaleza'},
            },
          ]),
          200,
        );
      });
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      final places = await api.fetchPlaces();

      expect(places, hasLength(1));
      expect(places.first.id, 1);
      expect(places.first.category.name, 'Naturaleza');
    });

    test('createPlace sends POST with correct body and returns parsed place', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/places');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Mirador');
        expect(body['category_id'], 2);
        expect(body['description'], 'Vistas');
        expect(body['latitude'], 42.5);
        expect(body['longitude'], -3.1);
        return http.Response(
          jsonEncode({
            'id': 7,
            'name': 'Mirador',
            'description': 'Vistas',
            'latitude': 42.5,
            'longitude': -3.1,
            'category': {'id': 2, 'name': 'Monumento'},
          }),
          201,
        );
      });
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      final place = await api.createPlace(
        name: 'Mirador',
        categoryId: 2,
        description: 'Vistas',
        latitude: 42.5,
        longitude: -3.1,
      );

      expect(place.id, 7);
      expect(place.category.id, 2);
    });

    test('fetchCategories throws PlaceApiException on 500', () async {
      final client = MockClient((request) async => http.Response('error', 500));
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(api.fetchCategories(), throwsA(isA<PlaceApiException>()));
    });

    test('createPlace throws PlaceApiException on 404', () async {
      final client = MockClient((request) async => http.Response('not found', 404));
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(
        api.createPlace(name: 'X', categoryId: 9999, latitude: 0, longitude: 0),
        throwsA(isA<PlaceApiException>()),
      );
    });
  });
}
