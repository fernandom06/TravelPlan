import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/itinerary_api.dart';
import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/models/trip.dart';
import 'package:frontend/data/place_api.dart';
import 'package:frontend/data/trip_api.dart';
import 'package:frontend/main.dart';
import 'package:frontend/presentation/controllers/places_controller.dart';
import 'package:frontend/presentation/controllers/trips_controller.dart';

class _FakePlaceApi extends PlaceApi {
  _FakePlaceApi() : super(baseUrl: 'http://fake');

  @override
  Future<List<Category>> fetchCategories() async => const [];

  @override
  Future<List<Place>> fetchPlaces() async => const [];
}

class _FakeTripApi extends TripApi {
  _FakeTripApi() : super(baseUrl: 'http://fake');

  @override
  Future<List<Trip>> fetchTrips() async => const [];
}

void main() {
  testWidgets('TravelPlanApp smoke test', (tester) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);
    final tripsController = TripsController(_FakeTripApi());
    addTearDown(tripsController.dispose);

    await tester.pumpWidget(
      TravelPlanApp(
        online: online,
        placesController: controller,
        tripsController: tripsController,
        itineraryApi: ItineraryApi(baseUrl: 'http://fake'),
        apiBaseUrl: 'http://fake',
      ),
    );
    await tester.pump();

    expect(find.text('TravelPlan'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Viajes'), findsOneWidget);
  });
}
