import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/presentation/widgets/itinerary_two_column_layout.dart';

Future<void> _pumpWide(WidgetTester tester, Widget left, Widget right) async {
  tester.view.physicalSize = const Size(1600, 1200);
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

void main() {
  testWidgets('places the left and right children side by side', (
    tester,
  ) async {
    await _pumpWide(
      tester,
      const SizedBox(width: 100, height: 100, key: Key('left')),
      const SizedBox(width: 100, height: 100, key: Key('right')),
    );

    final left = tester.getTopLeft(find.byKey(const Key('left')));
    final right = tester.getTopLeft(find.byKey(const Key('right')));
    expect(left.dx, lessThan(right.dx));
    expect(left.dy, right.dy);
  });

  testWidgets('columns scroll independently', (tester) async {
    await _pumpWide(
      tester,
      Container(
        key: const Key('left-content'),
        height: 2000,
        color: Colors.transparent,
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

    final leftScrollable = find.ancestor(
      of: find.byKey(const Key('left-content')),
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
}
