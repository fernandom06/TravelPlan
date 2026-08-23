import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/category_draft.dart';
import 'package:frontend/data/models/place_draft.dart';
import 'package:frontend/data/models/place_update.dart';
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

    test(
      'createPlace sends POST with correct body and returns parsed place',
      () async {
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
          const PlaceDraft(
            name: 'Mirador',
            categoryId: 2,
            description: 'Vistas',
            latitude: 42.5,
            longitude: -3.1,
          ),
        );

        expect(place.id, 7);
        expect(place.category.id, 2);
      },
    );

    test('fetchCategories throws PlaceApiException on 500', () async {
      final client = MockClient((request) async => http.Response('error', 500));
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(
        api.fetchCategories(),
        throwsA(isA<PlaceApiException>()),
      );
    });

    test('createPlace throws PlaceApiException on 404', () async {
      final client = MockClient(
        (request) async => http.Response('not found', 404),
      );
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(
        api.createPlace(
          const PlaceDraft(
            name: 'X',
            categoryId: 9999,
            latitude: 0,
            longitude: 0,
          ),
        ),
        throwsA(isA<PlaceApiException>()),
      );
    });

    test(
      'createCategory sends POST with correct body and returns parsed category',
      () async {
        final client = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/categories');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {'name': 'Playa'});
          return http.Response(jsonEncode({'id': 5, 'name': 'Playa'}), 201);
        });
        final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

        final category = await api.createCategory(
          const CategoryDraft(name: 'Playa'),
        );

        expect(category, const Category(id: 5, name: 'Playa'));
      },
    );

    test('createCategory throws DuplicateCategoryException on 409', () async {
      final client = MockClient(
        (request) async => http.Response('duplicate', 409),
      );
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(
        api.createCategory(const CategoryDraft(name: 'Playa')),
        throwsA(isA<DuplicateCategoryException>()),
      );
    });

    test('createCategory throws PlaceApiException on 500', () async {
      final client = MockClient((request) async => http.Response('error', 500));
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(
        api.createCategory(const CategoryDraft(name: 'Playa')),
        throwsA(isA<PlaceApiException>()),
      );
    });

    test(
      'renameCategory sends PATCH with name and returns parsed category',
      () async {
        final client = MockClient((request) async {
          expect(request.method, 'PATCH');
          expect(request.url.path, '/categories/3');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {'name': 'Costa'});
          return http.Response(jsonEncode({'id': 3, 'name': 'Costa'}), 200);
        });
        final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

        final category = await api.renameCategory(
          3,
          const CategoryDraft(name: 'Costa'),
        );

        expect(category, const Category(id: 3, name: 'Costa'));
      },
    );

    test('renameCategory throws DuplicateCategoryException on 409', () async {
      final client = MockClient(
        (request) async => http.Response('duplicate', 409),
      );
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(
        api.renameCategory(3, const CategoryDraft(name: 'Costa')),
        throwsA(isA<DuplicateCategoryException>()),
      );
    });

    test('renameCategory throws PlaceApiException on 500', () async {
      final client = MockClient((request) async => http.Response('error', 500));
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(
        api.renameCategory(3, const CategoryDraft(name: 'Costa')),
        throwsA(isA<PlaceApiException>()),
      );
    });

    test('deleteCategory sends DELETE and resolves on 204', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/categories/3');
        expect(request.url.query, isEmpty);
        return http.Response('', 204);
      });
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await api.deleteCategory(3);
    });

    test('deleteCategory sends reassign_to query param', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/categories/3');
        expect(request.url.queryParameters['reassign_to'], '5');
        return http.Response('', 204);
      });
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await api.deleteCategory(3, reassignTo: 5);
    });

    test('deleteCategory throws CategoryNotEmptyException on 409', () async {
      final client = MockClient(
        (request) async => http.Response('conflict', 409),
      );
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(
        api.deleteCategory(3),
        throwsA(isA<CategoryNotEmptyException>()),
      );
    });

    test(
      'deleteCategory throws InvalidReassignTargetException on 422',
      () async {
        final client = MockClient(
          (request) async => http.Response('unprocessable', 422),
        );
        final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

        await expectLater(
          api.deleteCategory(3, reassignTo: 9999),
          throwsA(isA<InvalidReassignTargetException>()),
        );
      },
    );

    test('deleteCategory throws PlaceApiException on 404', () async {
      final client = MockClient(
        (request) async => http.Response('not found', 404),
      );
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(
        api.deleteCategory(3),
        throwsA(isA<PlaceApiException>()),
      );
    });

    test('deleteCategory throws PlaceApiException on 500', () async {
      final client = MockClient((request) async => http.Response('error', 500));
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(
        api.deleteCategory(3),
        throwsA(isA<PlaceApiException>()),
      );
    });

    test(
      'updatePlace sends PATCH with body and returns parsed place',
      () async {
        final client = MockClient((request) async {
          expect(request.method, 'PATCH');
          expect(request.url.path, '/places/3');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {
            'name': 'Mirador nuevo',
            'category_id': 2,
            'description': 'Otra vista',
          });
          return http.Response(
            jsonEncode({
              'id': 3,
              'name': 'Mirador nuevo',
              'description': 'Otra vista',
              'latitude': 42.5,
              'longitude': -3.1,
              'category': {'id': 2, 'name': 'Monumento'},
            }),
            200,
          );
        });
        final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

        final place = await api.updatePlace(
          3,
          const PlaceUpdate(
            name: 'Mirador nuevo',
            categoryId: 2,
            description: 'Otra vista',
          ),
        );

        expect(place.id, 3);
        expect(place.name, 'Mirador nuevo');
        expect(place.category.id, 2);
      },
    );

    test('updatePlace throws PlaceApiException on 404', () async {
      final client = MockClient(
        (request) async => http.Response('not found', 404),
      );
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(
        api.updatePlace(3, const PlaceUpdate(name: 'X', categoryId: 1)),
        throwsA(isA<PlaceApiException>()),
      );
    });

    test('updatePlace throws PlaceApiException on 500', () async {
      final client = MockClient((request) async => http.Response('error', 500));
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(
        api.updatePlace(3, const PlaceUpdate(name: 'X', categoryId: 1)),
        throwsA(isA<PlaceApiException>()),
      );
    });

    test('deletePlace sends DELETE and resolves on 204', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/places/3');
        return http.Response('', 204);
      });
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await api.deletePlace(3);
    });

    test('deletePlace throws PlaceApiException on 404', () async {
      final client = MockClient(
        (request) async => http.Response('not found', 404),
      );
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(api.deletePlace(3), throwsA(isA<PlaceApiException>()));
    });

    test('deletePlace throws PlaceApiException on 500', () async {
      final client = MockClient((request) async => http.Response('error', 500));
      final api = PlaceApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(api.deletePlace(3), throwsA(isA<PlaceApiException>()));
    });
  });
}
