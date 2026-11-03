import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/presentation/widgets/itinerary_two_column_layout.dart';

Future<void> _pumpWide(
  WidgetTester tester,
  Widget left,
  Widget right, {
  double width = 1600,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ItineraryTwoColumnLayout(leftChild: left, rightChild: right),
      ),
    ),
  );
}

double _gutterBetween(WidgetTester tester) {
  final left = tester.getRect(find.byKey(const Key('left')));
  final right = tester.getRect(find.byKey(const Key('right')));
  return right.left - left.right;
}

void main() {
  testWidgets('places the left and right children side by side', (
    tester,
  ) async {
    await _pumpWide(
      tester,
      Container(key: const Key('left'), color: Colors.transparent),
      Container(key: const Key('right'), color: Colors.transparent),
    );

    final left = tester.getRect(find.byKey(const Key('left')));
    final right = tester.getRect(find.byKey(const Key('right')));
    expect(left.right, lessThan(right.left));
    expect(left.top, 0);
    expect(left.height, 1200);
    expect(right.height, 1200);
  });

  testWidgets('columns scroll independently', (tester) async {
    await _pumpWide(
      tester,
      SingleChildScrollView(
        key: const Key('left-scroll'),
        child: Container(
          key: const Key('left-content'),
          height: 2000,
          color: Colors.transparent,
        ),
      ),
      SingleChildScrollView(
        key: const Key('right-scroll'),
        child: Container(
          key: const Key('right-content'),
          height: 2000,
          color: Colors.transparent,
        ),
      ),
    );

    final leftScrollable = find.descendant(
      of: find.byKey(const Key('left-scroll')),
      matching: find.byType(Scrollable),
    );
    final leftScrollState = tester.state<ScrollableState>(leftScrollable);
    final rightContentBefore = tester
        .getTopLeft(find.byKey(const Key('right-content')))
        .dy;

    await tester.fling(
      find.byKey(const Key('left-content')),
      const Offset(0, -400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(leftScrollState.position.pixels, greaterThan(0));
    expect(
      tester.getTopLeft(find.byKey(const Key('right-content'))).dy,
      rightContentBefore,
    );

    // The right column manages its own scrolling.
    final rightScrollable = find.descendant(
      of: find.byKey(const Key('right-scroll')),
      matching: find.byType(Scrollable),
    );
    final rightScrollState = tester.state<ScrollableState>(rightScrollable);
    final leftContentBefore = tester
        .getTopLeft(find.byKey(const Key('left-content')))
        .dy;

    await tester.fling(
      find.byKey(const Key('right-scroll')),
      const Offset(0, -400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(rightScrollState.position.pixels, greaterThan(0));
    expect(
      tester.getTopLeft(find.byKey(const Key('left-content'))).dy,
      leftContentBefore,
    );
  });

  testWidgets('does not wrap the right child in its own scroll view', (
    tester,
  ) async {
    await _pumpWide(
      tester,
      const SizedBox(key: Key('left')),
      Container(
        key: const Key('right'),
        height: 3000,
        color: Colors.transparent,
      ),
    );

    expect(
      find.ancestor(
        of: find.byKey(const Key('right')),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    // Without a scroll wrapper the child is constrained to the available
    // height instead of growing to its natural 3000.
    expect(tester.getSize(find.byKey(const Key('right'))).height, 1200);
  });

  testWidgets('stretches the left column to the full height and width', (
    tester,
  ) async {
    await _pumpWide(
      tester,
      Container(key: const Key('left'), color: Colors.transparent),
      const SizedBox(key: Key('right')),
    );

    final left = tester.getRect(find.byKey(const Key('left')));
    expect(left.height, 1200);
    expect(left.width, closeTo(ItineraryTwoColumnLayout.leftWidth, 0.5));
    // Content is capped at maxContentWidth and centered: left starts at
    // (1600 - maxContentWidth) / 2 and is leftWidth wide.
    final contentStart = (1600 - ItineraryTwoColumnLayout.maxContentWidth) / 2;
    final leftCenter = contentStart + ItineraryTwoColumnLayout.leftWidth / 2;
    expect((left.center.dx - leftCenter).abs(), lessThan(1));
  });

  testWidgets('caps the left column at the max width on ultra-wide windows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(4000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ItineraryTwoColumnLayout(
            leftChild: const SizedBox(
              width: 3000,
              height: 100,
              key: Key('left'),
            ),
            rightChild: const SizedBox(key: Key('right')),
          ),
        ),
      ),
    );

    final left = tester.getRect(find.byKey(const Key('left')));
    expect(left.width, lessThanOrEqualTo(ItineraryTwoColumnLayout.leftWidth));
    // Content stays centered: left starts at (4000 - maxContentWidth) / 2.
    final contentStart = (4000 - ItineraryTwoColumnLayout.maxContentWidth) / 2;
    final leftCenter = contentStart + ItineraryTwoColumnLayout.leftWidth / 2;
    expect((left.center.dx - leftCenter).abs(), lessThan(1));
  });

  testWidgets('keeps the base gutter when there is no side space', (
    tester,
  ) async {
    await _pumpWide(
      tester,
      Container(key: const Key('left'), color: Colors.transparent),
      Container(key: const Key('right'), color: Colors.transparent),
      width: 1000,
    );

    expect(
      _gutterBetween(tester),
      closeTo(ItineraryTwoColumnLayout.gutter, 0.5),
    );
  });

  testWidgets('widens the gutter as the window gains side space', (
    tester,
  ) async {
    await _pumpWide(
      tester,
      Container(key: const Key('left'), color: Colors.transparent),
      Container(key: const Key('right'), color: Colors.transparent),
      width: 1300,
    );

    final midGutter = _gutterBetween(tester);
    expect(midGutter, greaterThan(ItineraryTwoColumnLayout.gutter));
    expect(midGutter, lessThan(ItineraryTwoColumnLayout.maxGutter));
  });

  testWidgets('caps the gutter at maxGutter on ultra-wide windows', (
    tester,
  ) async {
    await _pumpWide(
      tester,
      Container(key: const Key('left'), color: Colors.transparent),
      Container(key: const Key('right'), color: Colors.transparent),
      width: 1600,
    );

    expect(
      _gutterBetween(tester),
      closeTo(ItineraryTwoColumnLayout.maxGutter, 0.5),
    );
  });
}
