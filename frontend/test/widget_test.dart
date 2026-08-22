import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('TravelPlanApp smoke test', (tester) async {
    final online = ValueNotifier<bool>(true);
    addTearDown(online.dispose);

    await tester.pumpWidget(TravelPlanApp(online: online));

    expect(find.text('TravelPlan'), findsOneWidget);
  });
}
