import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/itinerary_api.dart';
import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/itinerary_item.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/models/trip.dart';
import 'package:frontend/data/models/trip_draft.dart';
import 'package:frontend/data/models/trip_update.dart';
import 'package:frontend/data/place_api.dart';
import 'package:frontend/data/trip_api.dart';
import 'package:frontend/presentation/controllers/places_controller.dart';
import 'package:frontend/presentation/controllers/trips_controller.dart';
import 'package:frontend/presentation/screens/itinerary_screen.dart';
import 'package:frontend/presentation/screens/trips_screen.dart';
import 'package:frontend/presentation/screens/zone_map_screen.dart';
import 'package:frontend/presentation/widgets/trip_card.dart';
import 'package:frontend/presentation/widgets/trip_form.dart';

class _FakeTripApi extends TripApi {
  _FakeTripApi({this.trips = const [], this.error})
    : super(baseUrl: 'http://fake');

  final List<Trip> trips;
  final Object? error;
  final List<TripDraft> createDrafts = [];
  final List<TripUpdate> updateCalls = [];
  Completer<void>? loadGate;

  @override
  Future<List<Trip>> fetchTrips() async {
    if (loadGate != null) await loadGate!.future;
    if (error != null) throw error!;
    return trips;
  }

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

  @override
  Future<Trip> updateTrip(String id, TripUpdate update) async {
    updateCalls.add(update);
    return Trip(
      id: id,
      name: update.name,
      description: update.description,
      startDate: update.startDate,
      endDate: update.endDate,
      imageUrl: update.imageUrl,
      createdAt: '2026-01-01 00:00:00',
    );
  }

  @override
  Future<void> deleteTrip(String id) async {}

  @override
  Future<String> uploadImage(
    Uint8List bytes,
    String filename,
    String contentType,
  ) async {
    return '/uploads/x.jpg';
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

class _EmptyPlaceApi extends PlaceApi {
  _EmptyPlaceApi() : super(baseUrl: 'http://fake');

  @override
  Future<List<Category>> fetchCategories() async => const [];

  @override
  Future<List<Place>> fetchPlaces() async => const [];
}

class _FakeItineraryApi extends ItineraryApi {
  _FakeItineraryApi() : super(baseUrl: 'http://fake');

  @override
  Future<List<ItineraryItem>> fetchItinerary(String tripId) async => const [];
}

Widget _wrap(
  TripsController controller, {
  bool online = true,
  ItineraryApi? itineraryApi,
  PlacesController? placesController,
}) {
  final onlineNotifier = ValueNotifier<bool>(online);
  addTearDown(onlineNotifier.dispose);
  return MaterialApp(
    home: TripsScreen(
      tripsController: controller,
      itineraryApi: itineraryApi ?? ItineraryApi(baseUrl: 'http://fake'),
      placesController: placesController ?? PlacesController(_EmptyPlaceApi()),
      online: onlineNotifier,
      baseUrl: 'http://localhost:8000',
    ),
  );
}

void main() {
  testWidgets('shows loader while loading', (tester) async {
    final api = _FakeTripApi(trips: [_trip])..loadGate = Completer<void>();
    final controller = TripsController(api);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(controller));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    api.loadGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('shows empty message when no trips', (tester) async {
    final controller = TripsController(_FakeTripApi());
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(find.text('No hay viajes'), findsOneWidget);
  });

  testWidgets('shows a TripCard per trip', (tester) async {
    final controller = TripsController(_FakeTripApi(trips: [_trip, _trip2]));
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(find.byType(TripCard), findsNWidgets(2));
    expect(find.text('Viaje a Galicia'), findsOneWidget);
    expect(find.text('Viaje a Madrid'), findsOneWidget);
  });

  testWidgets('tapping a trip card opens the itinerary screen', (tester) async {
    final controller = TripsController(_FakeTripApi(trips: [_trip]));
    addTearDown(controller.dispose);
    final places = PlacesController(_EmptyPlaceApi());
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(
        controller,
        itineraryApi: _FakeItineraryApi(),
        placesController: places,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Viaje a Galicia'));
    await tester.pumpAndSettle();

    expect(find.byType(ItineraryScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Viaje a Galicia'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('floating action button is present', (tester) async {
    final controller = TripsController(_FakeTripApi());
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.heroTag, 'trips-create-fab');
  });

  testWidgets('tapping FAB opens the trip form', (tester) async {
    final controller = TripsController(_FakeTripApi());
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(TripForm), findsOneWidget);
  });

  testWidgets('shows a snackbar when loading fails', (tester) async {
    final controller = TripsController(_FakeTripApi(error: Exception('boom')));
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(controller));
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
  });

  testWidgets('shows offline banner when offline', (tester) async {
    final controller = TripsController(_FakeTripApi());
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(controller, online: false));
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión con el servidor'), findsOneWidget);
  });

  group('create flow through the zone map', () {
    Future<void> openForm(WidgetTester tester) async {
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre'),
        'Viaje X',
      );
      await tester.pump();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
    }

    Future<void> drawPoint(WidgetTester tester, Offset offset) async {
      await tester.tapAt(tester.getCenter(find.byType(FlutterMap)) + offset);
      await tester.pump(const Duration(milliseconds: 350));
    }

    Future<void> confirmSkip(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Continuar'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Omitir'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('saving the form opens the zone map screen', (tester) async {
      final api = _FakeTripApi();
      final controller = TripsController(api);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_wrap(controller));
      await tester.pumpAndSettle();
      await openForm(tester);

      expect(find.byType(ZoneMapScreen), findsOneWidget);
      expect(api.createDrafts, isEmpty);
    });

    testWidgets('back from the map reopens the form with typed values', (
      tester,
    ) async {
      final api = _FakeTripApi();
      final controller = TripsController(api);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_wrap(controller));
      await tester.pumpAndSettle();
      await openForm(tester);
      expect(find.byType(ZoneMapScreen), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(TripForm), findsOneWidget);
      expect(find.text('Viaje X'), findsOneWidget);
      expect(api.createDrafts, isEmpty);

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.byType(ZoneMapScreen), findsOneWidget);
    });

    testWidgets('skipping the zone creates the trip with zone null', (
      tester,
    ) async {
      final api = _FakeTripApi();
      final controller = TripsController(api);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_wrap(controller));
      await tester.pumpAndSettle();
      await openForm(tester);
      await tester.tap(find.text('Omitir'));
      await tester.pumpAndSettle();
      await confirmSkip(tester);

      expect(api.createDrafts, hasLength(1));
      expect(api.createDrafts.single.zone, isNull);
      expect(find.byType(ZoneMapScreen), findsNothing);
      expect(find.byType(TripForm), findsNothing);
    });

    testWidgets('creating with a drawn zone sends the points', (tester) async {
      final api = _FakeTripApi();
      final controller = TripsController(api);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_wrap(controller));
      await tester.pumpAndSettle();
      await openForm(tester);

      await drawPoint(tester, Offset.zero);
      await drawPoint(tester, const Offset(40, 0));
      await drawPoint(tester, const Offset(0, 40));
      await tester.tap(find.text('Crear viaje'));
      await tester.pumpAndSettle();

      expect(api.createDrafts, hasLength(1));
      expect(api.createDrafts.single.zone, hasLength(3));
      expect(find.byType(ZoneMapScreen), findsNothing);
    });

    testWidgets('cancelling the form creates nothing', (tester) async {
      final api = _FakeTripApi();
      final controller = TripsController(api);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_wrap(controller));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(api.createDrafts, isEmpty);
      expect(find.byType(TripForm), findsNothing);
      expect(find.byType(ZoneMapScreen), findsNothing);
    });

    testWidgets('editing a trip updates without opening the zone map', (
      tester,
    ) async {
      final api = _FakeTripApi(trips: [_trip]);
      final controller = TripsController(api);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_wrap(controller));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Viaje a Galicia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      expect(find.byType(TripForm), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre'),
        'Viaje editado',
      );
      await tester.pump();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(api.updateCalls, hasLength(1));
      expect(api.updateCalls.single.name, 'Viaje editado');
      expect(api.createDrafts, isEmpty);
      expect(find.byType(ZoneMapScreen), findsNothing);
    });
  });
}
