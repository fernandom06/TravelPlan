import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/data/itinerary_api.dart';
import 'package:frontend/data/models/itinerary_move.dart';
import 'package:frontend/data/models/itinerary_slot.dart';

const _itemJson = {
  'id': 7,
  'day_date': '2026-06-01',
  'slot': 'morning',
  'position': 0,
  'place': {
    'id': 1,
    'name': 'Mirador',
    'description': null,
    'latitude': 42.5,
    'longitude': -3.5,
    'category': {'id': 1, 'name': 'Naturaleza', 'icon': null},
  },
};

void main() {
  group('ItineraryApi', () {
    test('fetchItinerary GETs and parses the list', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/trips/abc/itinerary');
        return http.Response(jsonEncode([_itemJson]), 200);
      });
      final api = ItineraryApi(baseUrl: 'http://localhost:8000', client: client);

      final items = await api.fetchItinerary('abc');

      expect(items, hasLength(1));
      expect(items.first.id, 7);
      expect(items.first.slot, ItinerarySlot.morning);
    });

    test('fetchItinerary throws on non-200', () async {
      final client = MockClient((request) async => http.Response('err', 500));
      final api = ItineraryApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(
        api.fetchItinerary('abc'),
        throwsA(isA<ItineraryApiException>()),
      );
    });

    test('addPlace POSTs place_id and returns the created item', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/trips/abc/itinerary');
        expect(request.headers['Content-Type'], 'application/json');
        expect(jsonDecode(request.body), {'place_id': 1});
        return http.Response(jsonEncode(_itemJson), 201);
      });
      final api = ItineraryApi(baseUrl: 'http://localhost:8000', client: client);

      final item = await api.addPlace('abc', 1);

      expect(item.id, 7);
    });

    test('addPlace throws on non-201', () async {
      final client = MockClient((request) async => http.Response('err', 404));
      final api = ItineraryApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(
        api.addPlace('abc', 1),
        throwsA(isA<ItineraryApiException>()),
      );
    });

    test('moveItem PATCHes a placed target', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/trips/abc/itinerary/7');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, {'day_date': '2026-06-02', 'slot': 'night', 'position': 3});
        return http.Response(jsonEncode(_itemJson), 200);
      });
      final api = ItineraryApi(baseUrl: 'http://localhost:8000', client: client);

      final item = await api.moveItem(
        'abc',
        7,
        ItineraryMove(
          dayDate: DateTime(2026, 6, 2),
          slot: ItinerarySlot.night,
          position: 3,
        ),
      );

      expect(item.id, 7);
    });

    test('moveItem serializes nulls for the general list', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/trips/abc/itinerary/7');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, {'day_date': null, 'slot': null, 'position': 0});
        return http.Response(jsonEncode(_itemJson), 200);
      });
      final api = ItineraryApi(baseUrl: 'http://localhost:8000', client: client);

      final item = await api.moveItem(
        'abc',
        7,
        ItineraryMove(dayDate: null, slot: null, position: 0),
      );

      expect(item.id, 7);
    });

    test('moveItem throws on non-200', () async {
      final client = MockClient((request) async => http.Response('err', 422));
      final api = ItineraryApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(
        api.moveItem(
          'abc',
          7,
          ItineraryMove(dayDate: null, slot: null, position: 0),
        ),
        throwsA(isA<ItineraryApiException>()),
      );
    });

    test('removeItem DELETEs and resolves on 204', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/trips/abc/itinerary/7');
        return http.Response('', 204);
      });
      final api = ItineraryApi(baseUrl: 'http://localhost:8000', client: client);

      await api.removeItem('abc', 7);
    });

    test('removeItem throws on non-204', () async {
      final client = MockClient((request) async => http.Response('err', 404));
      final api = ItineraryApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(
        api.removeItem('abc', 7),
        throwsA(isA<ItineraryApiException>()),
      );
    });
  });
}