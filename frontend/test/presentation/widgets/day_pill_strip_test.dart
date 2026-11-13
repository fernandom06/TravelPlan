import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/itinerary_item.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/presentation/widgets/day_pill_strip.dart';

ItineraryItem _item() {
  return ItineraryItem(
    id: 3,
    dayDate: null,
    slot: null,
    position: 0,
    place: Place(
      id: 1,
      name: 'Mirador de la Catedral',
      description: null,
      latitude: 42.5,
      longitude: -3.5,
      category: const Category(id: 1, name: 'Naturaleza', icon: 'nature'),
    ),
  );
}

List<DateTime> _days(int count) => [
  for (var i = 0; i < count; i++) DateTime(2026, 6, 1 + i),
];

Widget _wrap({
  required List<DateTime> days,
  required int selectedIndex,
  ValueChanged<int>? onSelect,
  void Function(ItineraryItem, DateTime)? onDropOnDay,
  void Function(int)? onHoverStart,
  VoidCallback? onHoverEnd,
  bool withSource = false,
  bool centered = false,
  List<int>? counts,
}) {
  final strip = DayPillStrip(
    days: days,
    selectedIndex: selectedIndex,
    onSelect: onSelect ?? (_) {},
    onDropOnDay: onDropOnDay ?? (_, _) {},
    onHoverStart: onHoverStart ?? (_) {},
    onHoverEnd: onHoverEnd ?? () {},
    centered: centered,
    counts: counts,
  );
  if (!withSource) {
    return MaterialApp(home: Scaffold(body: strip));
  }
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          LongPressDraggable<ItineraryItem>(
            data: _item(),
            feedback: const Material(child: SizedBox(width: 120, height: 40)),
            child: const SizedBox(
              width: 120,
              height: 40,
              child: Text('Lugar 1'),
            ),
          ),
          strip,
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('renders one pill per day with the day label', (tester) async {
    await tester.pumpWidget(_wrap(days: _days(3), selectedIndex: 0));
    await tester.pumpAndSettle();

    expect(find.text('Día 1 · 01 Jun'), findsOneWidget);
    expect(find.text('Día 2 · 02 Jun'), findsOneWidget);
    expect(find.text('Día 3 · 03 Jun'), findsOneWidget);
  });

  testWidgets('highlights the active pill in deep terracotta and the rest in '
      'sand', (tester) async {
    await tester.pumpWidget(_wrap(days: _days(3), selectedIndex: 0));
    await tester.pumpAndSettle();

    Color pillColor(String label) {
      final container = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text(label),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      return (container.decoration as BoxDecoration).color!;
    }

    // Deep terracotta, not plain primary: white 13px text on [primary] only
    // reaches ~2.9:1, which fails AA for small text.
    expect(pillColor('Día 1 · 01 Jun'), AppColors.primaryDeep);
    expect(pillColor('Día 2 · 02 Jun'), AppColors.muted.withValues(alpha: 0.6));
  });

  testWidgets('shows the per-day count as a badge, not a text segment', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(days: _days(3), selectedIndex: 0, counts: [2, 1, 0]),
    );
    await tester.pumpAndSettle();

    // Labels keep a single "Día N · dd Mmm" rhythm; counts are separate
    // badges and days with zero items show none.
    expect(find.text('Día 1 · 01 Jun'), findsOneWidget);
    expect(find.text('Día 2 · 02 Jun'), findsOneWidget);
    expect(find.text('Día 3 · 03 Jun'), findsOneWidget);
    expect(find.text('Día 1 · 01 Jun · 2'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('centered strip centers the pill block in the viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(days: _days(3), selectedIndex: 0, centered: true),
    );
    await tester.pumpAndSettle();

    final first = tester.getTopLeft(find.text('Día 1 · 01 Jun'));
    final last = tester.getTopRight(find.text('Día 3 · 03 Jun'));
    final blockCenter = (first.dx + last.dx) / 2;
    final stripCenter = tester.getCenter(find.byType(DayPillStrip)).dx;
    expect((blockCenter - stripCenter).abs(), lessThanOrEqualTo(1));
  });

  testWidgets('non-centered strip starts the pills at the left edge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(days: _days(3), selectedIndex: 0));
    await tester.pumpAndSettle();

    final firstPill = find
        .ancestor(
          of: find.text('Día 1 · 01 Jun'),
          matching: find.byType(AnimatedContainer),
        )
        .first;
    final firstPillLeft = tester.getTopLeft(firstPill).dx;
    final stripLeft = tester.getTopLeft(find.byType(DayPillStrip)).dx;
    expect(firstPillLeft - stripLeft, lessThan(20));
  });

  testWidgets('centered strip still scrolls to reveal a far selected day', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final days = _days(14);
    await tester.pumpWidget(
      _wrap(days: days, selectedIndex: 0, centered: true),
    );
    await tester.pumpAndSettle();

    final scrollableFinder = find.descendant(
      of: find.byType(DayPillStrip),
      matching: find.byType(Scrollable),
    );
    expect(scrollableFinder, findsOneWidget);
    expect(tester.state<ScrollableState>(scrollableFinder).position.pixels, 0);

    await tester.pumpWidget(
      _wrap(days: days, selectedIndex: 13, centered: true),
    );
    await tester.pumpAndSettle();

    final position = tester.state<ScrollableState>(scrollableFinder).position;
    expect(position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a pill selects its day', (tester) async {
    var selected = -1;
    await tester.pumpWidget(
      _wrap(days: _days(3), selectedIndex: 0, onSelect: (i) => selected = i),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Día 2 · 02 Jun'));
    expect(selected, 1);
  });

  testWidgets('announces pills as selectable buttons', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(days: _days(3), selectedIndex: 0));
    await tester.pumpAndSettle();

    final active = tester.getSemantics(find.text('Día 1 · 01 Jun'));
    expect(active.flagsCollection.isButton, isTrue);
    expect(active.flagsCollection.isSelected, Tristate.isTrue);
    expect(active.label, 'Día 1 · 01 Jun');

    final inactive = tester.getSemantics(find.text('Día 2 · 02 Jun'));
    expect(inactive.flagsCollection.isButton, isTrue);
    expect(inactive.flagsCollection.isSelected, Tristate.isFalse);
    semantics.dispose();
  });

  testWidgets('wraps the strip in a Scrollbar', (tester) async {
    await tester.pumpWidget(_wrap(days: _days(3), selectedIndex: 0));
    await tester.pumpAndSettle();

    expect(find.byType(Scrollbar), findsOneWidget);
  });

  testWidgets('selecting an off-screen day scrolls it into view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final days = _days(14);
    await tester.pumpWidget(_wrap(days: days, selectedIndex: 0));
    await tester.pumpAndSettle();

    final scrollableFinder = find.descendant(
      of: find.byType(DayPillStrip),
      matching: find.byType(Scrollable),
    );
    expect(tester.state<ScrollableState>(scrollableFinder).position.pixels, 0);

    await tester.pumpWidget(_wrap(days: days, selectedIndex: 13));
    await tester.pumpAndSettle();

    final position = tester.state<ScrollableState>(scrollableFinder).position;
    expect(position.pixels, greaterThan(0));
  });

  testWidgets('selecting a visible day does not scroll the strip', (
    tester,
  ) async {
    // 600px fits the first two pills (each ~233px wide) but not the last.
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final days = _days(14);
    await tester.pumpWidget(_wrap(days: days, selectedIndex: 0));
    await tester.pumpAndSettle();

    final scrollableFinder = find.descendant(
      of: find.byType(DayPillStrip),
      matching: find.byType(Scrollable),
    );

    await tester.pumpWidget(_wrap(days: days, selectedIndex: 1));
    await tester.pumpAndSettle();

    final position = tester.state<ScrollableState>(scrollableFinder).position;
    expect(position.pixels, 0);
  });

  testWidgets('dropping a card on a pill assigns it to that day', (
    tester,
  ) async {
    ItineraryItem? dropped;
    DateTime? droppedDay;
    await tester.pumpWidget(
      _wrap(
        days: _days(3),
        selectedIndex: 0,
        onDropOnDay: (item, day) {
          dropped = item;
          droppedDay = day;
        },
        withSource: true,
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Lugar 1')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(tester.getCenter(find.text('Día 3 · 03 Jun')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(dropped, _item());
    expect(droppedDay, DateTime(2026, 6, 3));
  });

  testWidgets('hovering a pill while dragging fires hover callbacks', (
    tester,
  ) async {
    final hovered = <int>[];
    var hoverEnds = 0;
    await tester.pumpWidget(
      _wrap(
        days: _days(3),
        selectedIndex: 0,
        onHoverStart: hovered.add,
        onHoverEnd: () => hoverEnds++,
        withSource: true,
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Lugar 1')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(tester.getCenter(find.text('Día 2 · 02 Jun')));
    await tester.pump();
    expect(hovered, contains(1));

    await gesture.moveTo(tester.getCenter(find.text('Lugar 1')));
    await tester.pump();
    expect(hoverEnds, greaterThan(0));

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
