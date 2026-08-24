import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/place_api.dart';
import 'package:frontend/presentation/controllers/places_controller.dart';
import 'package:frontend/presentation/screens/home_screen.dart';
import 'package:frontend/presentation/screens/trips_screen.dart';
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

void main() {
  testWidgets('shows AppBar, map and no banner when online', (tester) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(online: online, placesController: controller),
      ),
    );
    await tester.pump();

    expect(find.text('TravelPlan'), findsOneWidget);
    expect(find.byType(TravelMap), findsOneWidget);
    expect(find.text('Sin conexión con el servidor'), findsNothing);
  });

  testWidgets('shows offline banner and map when offline', (tester) async {
    final online = ValueNotifier<bool>(false);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(online: online, placesController: controller),
      ),
    );
    await tester.pump();

    expect(find.text('Sin conexión con el servidor'), findsOneWidget);
    expect(find.byType(TravelMap), findsOneWidget);
  });

  testWidgets('banner toggles with connectivity changes', (tester) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(online: online, placesController: controller),
      ),
    );
    await tester.pump();
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

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(online: online, placesController: controller),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
  });

  testWidgets('shows Mapa and Viajes tabs with icons', (tester) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(online: online, placesController: controller),
      ),
    );
    await tester.pump();

    expect(find.text('TravelPlan'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Viajes'), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(find.byIcon(Icons.flight), findsOneWidget);
  });

  testWidgets('shows the map by default in the Mapa tab', (tester) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(online: online, placesController: controller),
      ),
    );
    await tester.pump();

    expect(find.byType(TravelMap).hitTestable(), findsOneWidget);
    expect(find.byType(TripsScreen).hitTestable(), findsNothing);
  });

  testWidgets('tapping Viajes shows the placeholder', (tester) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(online: online, placesController: controller),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Viajes'));
    await tester.pumpAndSettle();

    expect(find.byType(TripsScreen).hitTestable(), findsOneWidget);
    expect(find.byType(TravelMap).hitTestable(), findsNothing);
  });

  testWidgets('returning to Mapa preserves the TravelMap state', (
    tester,
  ) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);
    final controller = PlacesController(_FakePlaceApi());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(online: online, placesController: controller),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Viajes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();

    expect(find.byType(TravelMap).hitTestable(), findsOneWidget);
    expect(find.byType(TripsScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(TravelMap, skipOffstage: false), findsOneWidget);
  });
}
