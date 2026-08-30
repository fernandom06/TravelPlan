import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/presentation/widgets/app_shell.dart';

class _StateTracker extends StatefulWidget {
  const _StateTracker({required this.label, required this.counters});

  final String label;
  final Map<String, int> counters;

  @override
  State<_StateTracker> createState() => _StateTrackerState();
}

class _StateTrackerState extends State<_StateTracker> {
  @override
  void initState() {
    super.initState();
    widget.counters['${widget.label}-init'] =
        (widget.counters['${widget.label}-init'] ?? 0) + 1;
  }

  @override
  void dispose() {
    widget.counters['${widget.label}-dispose'] =
        (widget.counters['${widget.label}-dispose'] ?? 0) + 1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('${widget.label}_CONTENT'));
  }
}

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
        home: AppShell(onTabChanged: onTabChanged, children: children),
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

  testWidgets('wide layout shows top bar instead of bottom nav', (
    tester,
  ) async {
    await pumpShell(tester, size: const Size(1200, 800));

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const Key('app-shell-desktop-top-bar')), findsOneWidget);
    expect(find.byIcon(Icons.map), findsOneWidget);
    expect(find.byIcon(Icons.flight_outlined), findsOneWidget);
    expect(find.text('MAPA_CONTENT'), findsOneWidget);
  });

  testWidgets('desktop top bar swaps to filled icon on active section', (
    tester,
  ) async {
    await pumpShell(tester, size: const Size(1200, 800));

    await tester.tap(find.text('Viajes'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(find.byIcon(Icons.flight), findsOneWidget);
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

  testWidgets('crossing the breakpoint preserves tab and child state', (
    tester,
  ) async {
    final counters = <String, int>{};
    tester.view.physicalSize = const Size(700, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AppShell(
          children: [
            _StateTracker(label: 'A', counters: counters),
            _StateTracker(label: 'B', counters: counters),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(counters['A-init'], 1);
    expect(counters['B-init'], 1); // IndexedStack builds children eagerly

    // Switch to the trips tab, then cross into desktop layout.
    await tester.tap(find.text('Viajes'));
    await tester.pumpAndSettle();
    expect(counters['B-init'], 1);

    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpAndSettle();

    expect(counters['B-init'], 1, reason: 'child must not be recreated');
    expect(
      find.text('B_CONTENT').hitTestable(),
      findsOneWidget,
      reason: 'active tab preserved across the breakpoint',
    );
    expect(find.byType(NavigationBar), findsNothing);

    // Cross back into mobile layout.
    tester.view.physicalSize = const Size(700, 844);
    await tester.pumpAndSettle();

    expect(counters['A-init'], 1, reason: 'children survive both crossings');
    expect(counters['B-init'], 1);
    expect(find.text('B_CONTENT').hitTestable(), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
