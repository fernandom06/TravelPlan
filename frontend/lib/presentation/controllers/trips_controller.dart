import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ValueNotifier;

import '../../data/models/trip.dart';
import '../../data/models/trip_draft.dart';
import '../../data/models/trip_update.dart';
import '../../data/trip_api.dart';

class TripsState {
  const TripsState({required this.trips, required this.isLoading});

  final List<Trip> trips;
  final bool isLoading;
}

class TripsController extends ValueNotifier<TripsState> {
  TripsController(this._api)
    : super(const TripsState(trips: [], isLoading: false));

  final TripApi _api;

  Future<void> loadTrips() async {
    value = TripsState(trips: value.trips, isLoading: true);
    try {
      final trips = await _api.fetchTrips();
      value = TripsState(trips: trips, isLoading: false);
    } catch (_) {
      value = TripsState(trips: value.trips, isLoading: false);
      rethrow;
    }
  }

  Future<Trip> createTrip(TripDraft draft) async {
    final trip = await _api.createTrip(draft);
    value = TripsState(
      trips: [...value.trips, trip],
      isLoading: value.isLoading,
    );
    return trip;
  }

  Future<Trip> updateTrip(String id, TripUpdate update) async {
    final updated = await _api.updateTrip(id, update);
    value = TripsState(
      trips: [for (final t in value.trips) t.id == id ? updated : t],
      isLoading: value.isLoading,
    );
    return updated;
  }

  Future<void> deleteTrip(String id) async {
    await _api.deleteTrip(id);
    value = TripsState(
      trips: value.trips.where((t) => t.id != id).toList(),
      isLoading: value.isLoading,
    );
  }

  Future<String> uploadImage(
    Uint8List bytes,
    String filename,
    String contentType,
  ) {
    return _api.uploadImage(bytes, filename, contentType);
  }
}
