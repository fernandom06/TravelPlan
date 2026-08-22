import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/presentation/widgets/travel_map.dart';

void main() {
  testWidgets('renders FlutterMap with no initial marker', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TravelMap()));

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(
      tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
      isEmpty,
    );
  });

  testWidgets('tap places a single marker', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TravelMap()));

    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
      1,
    );
  });

  testWidgets('second tap replaces the marker', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TravelMap()));

    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tapAt(
      tester.getCenter(find.byType(FlutterMap)) + const Offset(40, 40),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
      1,
    );
  });
}
