import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/presentation/widgets/app_shell.dart';

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    required Size size,
    List<Widget> children = const [Text('MAPA_CONTENT'), Text('TRIPS_CONTENT')],
    ValueChanged<int>? onTabChanged,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AppShell(children: children, onTabChanged: onTabChanged),
      ),
    );
    await tester.pump();
  }

  test('kDesktopBreakpoint and isDesktopLayout', () {
    expect(kDesktopBreakpoint, 800.0);
    expect(isDesktopLayout(799.0), isFalse);
    expect(isDesktopLayout(800.0), isTrue);
    expect(isDesktopLayout(1200.0), isTrue);
  });

  testWidgets('narrow layout shows docked bottom navigation', (tester) async {
    await pumpShell(tester, size: const Size(700, 844));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const Key('app-shell-desktop-top-bar')), findsNothing);
    expect(find.byIcon(Icons.map), findsOneWidget);
    expect(find.byIcon(Icons.flight_outlined), findsOneWidget);
    expect(find.text('MAPA_CONTENT'), findsOneWidget);
  });

  testWidgets('wide layout shows top bar instead of bottom nav', (tester) async {
    await pumpShell(tester, size: const Size(1200, 800));

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const Key('app-shell-desktop-top-bar')), findsOneWidget);
    expect(find.text('MAPA_CONTENT'), findsOneWidget);
  });

  testWidgets('bottom nav switches content and notifies', (tester) async {
    int? changedTo;
    await pumpShell(
      tester,
      size: const Size(700, 844),
      onTabChanged: (i) => changedTo = i,
    );

    await tester.tap(find.text('Viajes'));
    await tester.pumpAndSettle();

    expect(changedTo, 1);
    expect(find.text('TRIPS_CONTENT').hitTestable(), findsOneWidget);
    expect(find.text('MAPA_CONTENT').hitTestable(), findsNothing);
  });

  testWidgets('top bar switches content and notifies', (tester) async {
    int? changedTo;
    await pumpShell(
      tester,
      size: const Size(1200, 800),
      onTabChanged: (i) => changedTo = i,
    );

    await tester.tap(find.text('Viajes'));
    await tester.pumpAndSettle();

    expect(changedTo, 1);
    expect(find.text('TRIPS_CONTENT').hitTestable(), findsOneWidget);
    expect(find.text('MAPA_CONTENT').hitTestable(), findsNothing);
  });
}