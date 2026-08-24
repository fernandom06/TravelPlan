import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/trip.dart';
import 'package:frontend/data/models/trip_draft.dart';
import 'package:frontend/data/models/trip_update.dart';
import 'package:frontend/data/trip_api.dart';
import 'package:frontend/presentation/controllers/trips_controller.dart';
import 'package:frontend/presentation/screens/trips_screen.dart';
import 'package:frontend/presentation/widgets/trip_card.dart';
import 'package:frontend/presentation/widgets/trip_form.dart';

class _FakeTripApi extends TripApi {
  _FakeTripApi({this.trips = const [], this.error})
    : super(baseUrl: 'http://fake');

  final List<Trip> trips;
  final Object? error;
  Completer<void>? loadGate;

  @override
  Future<List<Trip>> fetchTrips() async {
    if (loadGate != null) await loadGate!.future;
    if (error != null) throw error!;
    return trips;
  }

  @override
  Future<Trip> createTrip(TripDraft draft) async {
    throw UnimplementedError();
  }

  @override
  Future<Trip> updateTrip(String id, TripUpdate update) async {
    throw UnimplementedError();
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

Widget _wrap(TripsController controller, {bool online = true}) {
  final onlineNotifier = ValueNotifier<bool>(online);
  addTearDown(onlineNotifier.dispose);
  return MaterialApp(
    home: TripsScreen(
      tripsController: controller,
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

  testWidgets('floating action button is present', (tester) async {
    final controller = TripsController(_FakeTripApi());
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
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
}
