import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/trip.dart';
import 'package:frontend/data/models/trip_draft.dart';
import 'package:frontend/data/models/trip_update.dart';
import 'package:frontend/data/trip_api.dart';
import 'package:frontend/presentation/controllers/trips_controller.dart';

class _FakeTripApi extends TripApi {
  _FakeTripApi({
    this.trips = const [],
    this.error,
    this.createdTrip,
    this.updatedTrip,
    this.uploadError,
    this.uploadUrl,
    this.updateError,
    this.deleteError,
  }) : super(baseUrl: 'http://fake');

  final List<Trip> trips;
  final Object? error;
  final Trip? createdTrip;
  final Trip? updatedTrip;
  final Object? uploadError;
  final String? uploadUrl;
  final Object? updateError;
  final Object? deleteError;

  String? deletedTripId;

  @override
  Future<List<Trip>> fetchTrips() async {
    if (error != null) throw error!;
    return trips;
  }

  @override
  Future<Trip> createTrip(TripDraft draft) async {
    if (error != null) throw error!;
    return createdTrip!;
  }

  @override
  Future<Trip> updateTrip(String id, TripUpdate update) async {
    if (updateError != null) throw updateError!;
    return updatedTrip!;
  }

  @override
  Future<void> deleteTrip(String id) async {
    if (deleteError != null) throw deleteError!;
    deletedTripId = id;
  }

  @override
  Future<String> uploadImage(
    Uint8List bytes,
    String filename,
    String contentType,
  ) async {
    if (uploadError != null) throw uploadError!;
    return uploadUrl!;
  }
}

final _trip = Trip(
  id: 'abc',
  name: 'Viaje a Galicia',
  description: null,
  startDate: DateTime(2026, 6, 1),
  endDate: DateTime(2026, 6, 10),
  imageUrl: null,
  createdAt: '2026-01-01',
);

final _trip2 = Trip(
  id: 'def',
  name: 'Viaje a Madrid',
  description: 'Ciudad',
  startDate: DateTime(2026, 7, 1),
  endDate: DateTime(2026, 7, 5),
  imageUrl: null,
  createdAt: '2026-01-02',
);

final _updatedTrip = Trip(
  id: 'abc',
  name: 'Viaje nuevo',
  description: 'Otra',
  startDate: DateTime(2026, 8, 1),
  endDate: DateTime(2026, 8, 5),
  imageUrl: null,
  createdAt: '2026-01-01',
);

void main() {
  test('loadTrips populates trips and toggles isLoading', () async {
    final controller = TripsController(_FakeTripApi(trips: [_trip]));
    addTearDown(controller.dispose);

    expect(controller.value.isLoading, isFalse);

    final future = controller.loadTrips();
    expect(controller.value.isLoading, isTrue);

    await future;

    expect(controller.value.isLoading, isFalse);
    expect(controller.value.trips, [_trip]);
  });

  test('loadTrips propagates errors and resets isLoading', () async {
    final controller = TripsController(_FakeTripApi(error: Exception('boom')));
    addTearDown(controller.dispose);

    await expectLater(controller.loadTrips(), throwsA(isA<Exception>()));

    expect(controller.value.isLoading, isFalse);
    expect(controller.value.trips, isEmpty);
  });

  test('createTrip adds the created trip to state', () async {
    final controller = TripsController(_FakeTripApi(createdTrip: _trip));
    addTearDown(controller.dispose);

    final created = await controller.createTrip(
      TripDraft(
        name: 'Viaje a Galicia',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 10),
      ),
    );

    expect(created, _trip);
    expect(controller.value.trips, [_trip]);
  });

  test('createTrip propagates errors without changing state', () async {
    final controller = TripsController(_FakeTripApi(error: Exception('boom')));
    addTearDown(controller.dispose);

    await expectLater(
      controller.createTrip(
        TripDraft(
          name: 'X',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 10),
        ),
      ),
      throwsA(isA<Exception>()),
    );

    expect(controller.value.trips, isEmpty);
  });

  test('updateTrip replaces the trip in state keeping order', () async {
    final controller = TripsController(
      _FakeTripApi(trips: [_trip, _trip2], updatedTrip: _updatedTrip),
    );
    addTearDown(controller.dispose);
    await controller.loadTrips();

    final updated = await controller.updateTrip(
      'abc',
      TripUpdate(
        name: 'Viaje nuevo',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 5),
        description: 'Otra',
      ),
    );

    expect(updated, _updatedTrip);
    expect(controller.value.trips.map((t) => t.id), ['abc', 'def']);
    expect(controller.value.trips.first.name, 'Viaje nuevo');
  });

  test('updateTrip propagates errors without changing state', () async {
    final controller = TripsController(
      _FakeTripApi(trips: [_trip], updateError: Exception('boom')),
    );
    addTearDown(controller.dispose);
    await controller.loadTrips();
    final before = controller.value.trips;

    await expectLater(
      controller.updateTrip(
        'abc',
        TripUpdate(
          name: 'X',
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 5),
        ),
      ),
      throwsA(isA<Exception>()),
    );

    expect(controller.value.trips, before);
  });

  test('deleteTrip removes the trip from state', () async {
    final controller = TripsController(_FakeTripApi(trips: [_trip, _trip2]));
    addTearDown(controller.dispose);
    await controller.loadTrips();

    await controller.deleteTrip('abc');

    expect(controller.value.trips, [_trip2]);
  });

  test('deleteTrip propagates errors without changing state', () async {
    final controller = TripsController(
      _FakeTripApi(trips: [_trip], deleteError: Exception('boom')),
    );
    addTearDown(controller.dispose);
    await controller.loadTrips();
    final before = controller.value.trips;

    await expectLater(controller.deleteTrip('abc'), throwsA(isA<Exception>()));

    expect(controller.value.trips, before);
  });

  test('uploadImage returns the url without mutating state', () async {
    final controller = TripsController(
      _FakeTripApi(uploadUrl: '/uploads/x.jpg'),
    );
    addTearDown(controller.dispose);

    final url = await controller.uploadImage(
      Uint8List.fromList([1]),
      'a.jpg',
      'image/jpeg',
    );

    expect(url, '/uploads/x.jpg');
    expect(controller.value.trips, isEmpty);
  });

  test('uploadImage propagates errors', () async {
    final controller = TripsController(
      _FakeTripApi(uploadError: Exception('boom')),
    );
    addTearDown(controller.dispose);

    await expectLater(
      controller.uploadImage(Uint8List.fromList([1]), 'a.jpg', 'image/jpeg'),
      throwsA(isA<Exception>()),
    );
  });
}
