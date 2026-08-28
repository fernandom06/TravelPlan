import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/data/models/trip_draft.dart';
import 'package:frontend/data/models/trip_update.dart';
import 'package:frontend/data/models/zone_point.dart';
import 'package:frontend/data/trip_api.dart';

const _tripJson = {
  'id': 'abc',
  'name': 'Viaje a Galicia',
  'description': 'Costas',
  'start_date': '2026-06-01',
  'end_date': '2026-06-10',
  'image_url': null,
  'created_at': '2026-01-01 00:00:00',
};

class _MultipartClient extends http.BaseClient {
  _MultipartClient(this.onSend);

  final Future<http.StreamedResponse> Function(http.BaseRequest) onSend;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      onSend(request);
}

void main() {
  group('TripApi', () {
    test('fetchTrips parses list', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/trips');
        return http.Response(jsonEncode([_tripJson]), 200);
      });
      final api = TripApi(baseUrl: 'http://localhost:8000', client: client);

      final trips = await api.fetchTrips();

      expect(trips, hasLength(1));
      expect(trips.first.id, 'abc');
      expect(trips.first.name, 'Viaje a Galicia');
    });

    test('fetchTrip returns trip by id', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/trips/abc');
        return http.Response(jsonEncode(_tripJson), 200);
      });
      final api = TripApi(baseUrl: 'http://localhost:8000', client: client);

      final trip = await api.fetchTrip('abc');

      expect(trip.id, 'abc');
    });

    test('createTrip sends POST with correct body and returns Trip', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/trips');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, {
          'name': 'Viaje a Galicia',
          'start_date': '2026-06-01',
          'end_date': '2026-06-10',
          'description': 'Costas',
          'image_url': null,
          'zone': null,
        });
        return http.Response(jsonEncode(_tripJson), 201);
      });
      final api = TripApi(baseUrl: 'http://localhost:8000', client: client);

      final trip = await api.createTrip(
        TripDraft(
          name: 'Viaje a Galicia',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 10),
          description: 'Costas',
        ),
      );

      expect(trip.id, 'abc');
    });

    test('createTrip sends zone points in body when draft has them', () async {
      const points = [
        ZonePoint(latitude: 42.0, longitude: -4.0),
        ZonePoint(latitude: 43.0, longitude: -3.0),
        ZonePoint(latitude: 42.5, longitude: -3.5),
      ];
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/trips');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['zone'], {
          'points': [
            {'latitude': 42.0, 'longitude': -4.0},
            {'latitude': 43.0, 'longitude': -3.0},
            {'latitude': 42.5, 'longitude': -3.5},
          ],
        });
        return http.Response(jsonEncode(_tripJson), 201);
      });
      final api = TripApi(baseUrl: 'http://localhost:8000', client: client);

      final trip = await api.createTrip(
        TripDraft(
          name: 'Viaje a Galicia',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 10),
          zone: points,
        ),
      );

      expect(trip.id, 'abc');
    });

    test('createTrip sends collinear 3-point zone unchanged', () async {
      const points = [
        ZonePoint(latitude: 42.0, longitude: -4.0),
        ZonePoint(latitude: 42.0, longitude: -3.0),
        ZonePoint(latitude: 42.0, longitude: -2.0),
      ];
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/trips');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['zone'], {
          'points': [
            {'latitude': 42.0, 'longitude': -4.0},
            {'latitude': 42.0, 'longitude': -3.0},
            {'latitude': 42.0, 'longitude': -2.0},
          ],
        });
        return http.Response(jsonEncode(_tripJson), 201);
      });
      final api = TripApi(baseUrl: 'http://localhost:8000', client: client);

      final trip = await api.createTrip(
        TripDraft(
          name: 'Viaje a Galicia',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 10),
          zone: points,
        ),
      );

      expect(trip.id, 'abc');
    });

    test('updateTrip sends PATCH with body', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/trips/abc');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, {
          'name': 'Viaje nuevo',
          'start_date': '2026-07-01',
          'end_date': '2026-07-05',
          'description': 'Otra',
          'image_url': 'https://example.com/x.jpg',
        });
        return http.Response(
          jsonEncode({..._tripJson, 'name': 'Viaje nuevo'}),
          200,
        );
      });
      final api = TripApi(baseUrl: 'http://localhost:8000', client: client);

      final trip = await api.updateTrip(
        'abc',
        TripUpdate(
          name: 'Viaje nuevo',
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 5),
          description: 'Otra',
          imageUrl: 'https://example.com/x.jpg',
        ),
      );

      expect(trip.name, 'Viaje nuevo');
    });

    test('deleteTrip sends DELETE and resolves on 204', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/trips/abc');
        return http.Response('', 204);
      });
      final api = TripApi(baseUrl: 'http://localhost:8000', client: client);

      await api.deleteTrip('abc');
    });

    test('fetchTrips throws TripApiException on 500', () async {
      final client = MockClient((request) async => http.Response('err', 500));
      final api = TripApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(api.fetchTrips(), throwsA(isA<TripApiException>()));
    });

    test('fetchTrip throws TripApiException on 404', () async {
      final client = MockClient(
        (request) async => http.Response('not found', 404),
      );
      final api = TripApi(baseUrl: 'http://localhost:8000', client: client);

      await expectLater(api.fetchTrip('abc'), throwsA(isA<TripApiException>()));
    });

    test('uploadImage posts multipart and returns url', () async {
      final client = _MultipartClient((request) async {
        expect(request.url.path, '/trips/images');
        expect(request.method, 'POST');
        final multipart = request as http.MultipartRequest;
        expect(multipart.files, hasLength(1));
        expect(multipart.files.single.filename, 'foto.jpg');
        expect(multipart.files.single.contentType.mimeType, 'image/jpeg');
        final body = await request.finalize().toBytes();
        expect(utf8.decode(body), contains('name="file"'));
        expect(utf8.decode(body), contains('foto.jpg'));
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({'url': '/uploads/x.jpg'}))),
          201,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = TripApi(baseUrl: 'http://localhost:8000', client: client);

      final url = await api.uploadImage(
        Uint8List.fromList([1, 2, 3]),
        'foto.jpg',
        'image/jpeg',
      );

      expect(url, '/uploads/x.jpg');
    });
  });
}
