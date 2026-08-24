import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/presentation/screens/trips_screen.dart';

void main() {
  testWidgets('shows the coming soon placeholder', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TripsScreen())),
    );

    expect(find.text('Próximamente'), findsOneWidget);
    expect(find.byIcon(Icons.flight), findsOneWidget);
  });
}
