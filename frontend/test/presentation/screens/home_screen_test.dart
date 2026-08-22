import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/presentation/screens/home_screen.dart';
import 'package:frontend/presentation/widgets/travel_map.dart';

void main() {
  testWidgets('shows AppBar title and map, no banner when online',
      (tester) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);

    await tester.pumpWidget(MaterialApp(home: HomeScreen(online: online)));

    expect(find.text('TravelPlan'), findsOneWidget);
    expect(find.byType(TravelMap), findsOneWidget);
    expect(find.text('Sin conexión a internet'), findsNothing);
  });

  testWidgets('shows offline banner and map when offline', (tester) async {
    final online = ValueNotifier<bool>(false);
    addTearDown(online.dispose);

    await tester.pumpWidget(MaterialApp(home: HomeScreen(online: online)));

    expect(find.text('Sin conexión a internet'), findsOneWidget);
    expect(find.byType(TravelMap), findsOneWidget);
  });

  testWidgets('banner toggles with connectivity changes', (tester) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);

    await tester.pumpWidget(MaterialApp(home: HomeScreen(online: online)));
    expect(find.text('Sin conexión a internet'), findsNothing);

    online.value = false;
    await tester.pump();
    expect(find.text('Sin conexión a internet'), findsOneWidget);

    online.value = true;
    await tester.pump();
    expect(find.text('Sin conexión a internet'), findsNothing);
  });
}
