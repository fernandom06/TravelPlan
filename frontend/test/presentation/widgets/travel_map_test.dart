import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/presentation/widgets/place_form.dart';
import 'package:frontend/presentation/widgets/travel_map.dart';

const _naturaleza = Category(id: 1, name: 'Naturaleza');
const _categories = [_naturaleza];

const _place = Place(
  id: 1,
  name: 'Mirador',
  description: null,
  latitude: 42.0414,
  longitude: -3.0428,
  category: _naturaleza,
);

Future<void> _noopCreate({
  required String name,
  required int categoryId,
  String? description,
  required double latitude,
  required double longitude,
}) async {}

Widget _map({List<Place> places = const [], bool isOnline = true}) {
  return MaterialApp(
    home: Scaffold(
      body: TravelMap(
        places: places,
        categories: _categories,
        onCreatePlace: _noopCreate,
        isOnline: isOnline,
      ),
    ),
  );
}

List<Marker> _markers(WidgetTester tester) =>
    tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers;

Icon _markerIcon(Marker marker) {
  final child = marker.child;
  if (child is Icon) return child;
  return (child as GestureDetector).child as Icon;
}

void main() {
  testWidgets('renders FlutterMap with no markers when there are no places', (
    tester,
  ) async {
    await tester.pumpWidget(_map());

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(_markers(tester), isEmpty);
  });

  testWidgets('renders a blue marker per place', (tester) async {
    await tester.pumpWidget(_map(places: [_place]));

    expect(_markers(tester), hasLength(1));
    expect(_markerIcon(_markers(tester).first).color, Colors.blue);
  });

  testWidgets('tap on empty map shows a red marker and opens the form', (
    tester,
  ) async {
    await tester.pumpWidget(_map());

    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await tester.pump(const Duration(milliseconds: 350));

    expect(_markers(tester), hasLength(1));
    expect(_markerIcon(_markers(tester).first).color, Colors.red);
    expect(find.byType(PlaceForm), findsOneWidget);
  });

  testWidgets('second tap while the form is open closes it without a new marker', (
    tester,
  ) async {
    await tester.pumpWidget(_map());

    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(PlaceForm), findsOneWidget);

    await tester.tapAt(
      tester.getCenter(find.byType(FlutterMap)) + const Offset(40, 40),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PlaceForm), findsNothing);
    expect(_markers(tester), isEmpty);
  });

  testWidgets('tapping a blue marker opens a read-only form', (tester) async {
    await tester.pumpWidget(_map(places: [_place]));

    await tester.tap(find.byIcon(Icons.location_on).first);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PlaceForm), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);
    expect(find.text('Guardar'), findsNothing);
  });

  testWidgets('tapping outside the form closes and discards it', (tester) async {
    await tester.pumpWidget(_map());

    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(PlaceForm), findsOneWidget);

    await tester.tapAt(
      tester.getCenter(find.byType(FlutterMap)) + const Offset(60, 60),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PlaceForm), findsNothing);
    expect(_markers(tester), isEmpty);
  });
}
