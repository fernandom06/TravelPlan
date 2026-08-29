import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/itinerary_api.dart';
import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/models/trip.dart';
import 'package:frontend/data/models/trip_draft.dart';
import 'package:frontend/data/place_api.dart';
import 'package:frontend/data/trip_api.dart';
import 'package:frontend/presentation/controllers/places_controller.dart';
import 'package:frontend/presentation/controllers/trips_controller.dart';
import 'package:frontend/presentation/screens/home_screen.dart';
import 'package:frontend/presentation/screens/trips_screen.dart';
import 'package:frontend/presentation/screens/zone_map_screen.dart';
import 'package:frontend/presentation/widgets/app_shell.dart';
import 'package:frontend/presentation/widgets/travel_map.dart';

class _FakePlaceApi extends PlaceApi {
  _FakePlaceApi({this.error}) : super(baseUrl: 'http://fake');

  final Object? error;

  @override
  Future<List<Category>> fetchCategories() async {
    if (error != null) throw error!;
    return const [];
  }

  @override
  Future<List<Place>> fetchPlaces() async {
    if (error != null) throw error!;
    return const [];
  }
}

class _FakeTripApi extends TripApi {
  _FakeTripApi() : super(baseUrl: 'http://fake');

  final List<TripDraft> createDrafts = [];

  @override
  Future<List<Trip>> fetchTrips() async => const [];

  @override
  Future<Trip> createTrip(TripDraft draft) async {
    createDrafts.add(draft);
    return Trip(
      id: 'created-${createDrafts.length}',
      name: draft.name,
      description: draft.description,
      startDate: draft.startDate,
      endDate: draft.endDate,
      imageUrl: draft.imageUrl,
      createdAt: '2026-01-01 00:00:00',
    );
  }
}

const _mobileSize = Size(700, 844);
const _desktopSize = Size(1200, 800);

HomeScreen _homeScreen(
  ValueNotifier<bool> online,
  PlacesController placesController, {
  TripsController? tripsController,
}) {
  return HomeScreen(
    online: online,
    placesController: placesController,
    tripsController: tripsController ?? TripsController(_FakeTripApi()),
    itineraryApi: ItineraryApi(baseUrl: 'http://fake'),
    apiBaseUrl: 'http://fake',
  );
}

Future<void> _pumpHome(
  WidgetTester tester,
  ValueNotifier<bool> online,
  PlacesController controller, {
  Size size = _mobileSize,
  TripsController? tripsController,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: _homeScreen(online, controller, tripsController: tripsController)),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows map and no banner when online (mobile)', (tester) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await _pumpHome(tester, online, controller);

    expect(find.byType(TravelMap), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Sin conexión con el servidor'), findsNothing);
  });

  testWidgets('desktop layout shows the top bar with the app title', (
    tester,
  ) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await _pumpHome(tester, online, controller, size: _desktopSize);

    expect(find.text('TravelPlan'), findsOneWidget);
    expect(find.byKey(const Key('app-shell-desktop-top-bar')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(TravelMap).hitTestable(), findsOneWidget);
  });

  testWidgets('shows offline banner and map when offline', (tester) async {
    final online = ValueNotifier<bool>(false);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await _pumpHome(tester, online, controller);

    expect(find.text('Sin conexión con el servidor'), findsOneWidget);
    expect(find.byType(TravelMap), findsOneWidget);
  });

  testWidgets('banner toggles with connectivity changes', (tester) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await _pumpHome(tester, online, controller);
    expect(find.text('Sin conexión con el servidor'), findsNothing);

    online.value = false;
    await tester.pump();
    expect(find.text('Sin conexión con el servidor'), findsOneWidget);

    online.value = true;
    await tester.pump();
    expect(find.text('Sin conexión con el servidor'), findsNothing);
  });

  testWidgets('shows a snackbar when loading fails', (tester) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(
      _FakePlaceApi(error: Exception('boom')),
    );
    addTearDown(controller.dispose);

    await _pumpHome(tester, online, controller);
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
  });

  testWidgets('shows Mapa and Viajes navigation destinations with icons', (
    tester,
  ) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await _pumpHome(tester, online, controller);

    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Viajes'), findsOneWidget);
    expect(find.byIcon(Icons.map), findsOneWidget);
    expect(find.byIcon(Icons.flight_outlined), findsOneWidget);
  });

  testWidgets('shows the map by default in the Mapa tab', (tester) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await _pumpHome(tester, online, controller);

    expect(find.byType(TravelMap).hitTestable(), findsOneWidget);
    expect(find.byType(TripsScreen).hitTestable(), findsNothing);
  });

  testWidgets('tapping Viajes shows the trips content (mobile)', (tester) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await _pumpHome(tester, online, controller);

    await tester.tap(find.text('Viajes'));
    await tester.pumpAndSettle();

    expect(find.byType(TripsScreen).hitTestable(), findsOneWidget);
    expect(find.byType(TravelMap).hitTestable(), findsNothing);
    expect(find.text('No hay viajes'), findsOneWidget);
  });

  testWidgets('tapping Viajes in the desktop top bar shows trips content', (
    tester,
  ) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await _pumpHome(tester, online, controller, size: _desktopSize);

    await tester.tap(find.text('Viajes'));
    await tester.pumpAndSettle();

    expect(find.byType(TripsScreen).hitTestable(), findsOneWidget);
    expect(find.byType(TravelMap).hitTestable(), findsNothing);
  });

  testWidgets('shows offline banner in Viajes tab when offline', (
    tester,
  ) async {
    final online = ValueNotifier<bool>(false);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await _pumpHome(tester, online, controller);

    await tester.tap(find.text('Viajes'));
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión con el servidor'), findsOneWidget);
  });

  testWidgets('returning to Mapa preserves the TravelMap state', (
    tester,
  ) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await _pumpHome(tester, online, controller);

    await tester.tap(find.text('Viajes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();

    expect(find.byType(TravelMap).hitTestable(), findsOneWidget);
    expect(find.byType(TripsScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(TravelMap, skipOffstage: false), findsOneWidget);
  });

  testWidgets(
    'creating a trip with a drawn zone through the trips tab throws no hero '
    'exception and saves the 3 points',
    (tester) async {
      final online = ValueNotifier<bool>(true);
      addTearDown(online.dispose);
      final placesController = PlacesController(_FakePlaceApi());
      addTearDown(placesController.dispose);
      final tripsApi = _FakeTripApi();
      final tripsController = TripsController(tripsApi);
      addTearDown(tripsController.dispose);

      await _pumpHome(
        tester,
        online,
        placesController,
        tripsController: tripsController,
      );
      await tester.pump();

      await tester.tap(find.text('Viajes'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre'),
        'Viaje X',
      );
      await tester.pump();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.byType(ZoneMapScreen), findsOneWidget);

      final mapCenter = tester.getCenter(find.byType(FlutterMap));
      await tester.tapAt(mapCenter);
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.takeException(), isNull);
      await tester.tapAt(mapCenter + const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.takeException(), isNull);
      await tester.tapAt(mapCenter + const Offset(0, 40));
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Crear viaje'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(tripsApi.createDrafts, hasLength(1));
      expect(tripsApi.createDrafts.single.zone, hasLength(3));
      expect(find.byType(ZoneMapScreen), findsNothing);
    },
  );
}