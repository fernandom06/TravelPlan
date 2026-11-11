import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/presentation/widgets/place_pin.dart';

void main() {
  Future<void> hoverPin(WidgetTester tester, Finder pinFinder) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(10, 10));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(pinFinder));
    await tester.pump();
    addTearDown(gesture.removePointer);
  }

  Widget wrap({required String label, Widget? child}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: PinHoverTooltip(
            label: label,
            child: child ?? const PlacePin(icon: Icons.place),
          ),
        ),
      ),
    );
  }

  group('PinHoverTooltip', () {
    testWidgets('shows the full long label wider than the pin', (tester) async {
      final label = 'x' * 60;
      await tester.pumpWidget(wrap(label: label));

      await hoverPin(tester, find.byType(PlacePin));

      expect(find.text(label), findsOneWidget);
      final tooltipSize = tester.getSize(
        find.byKey(const Key('place-pin-tooltip')),
      );
      expect(tooltipSize.width, greaterThan(40));
    });

    testWidgets('grows centered over the pin', (tester) async {
      await tester.pumpWidget(wrap(label: 'x' * 60));

      await hoverPin(tester, find.byType(PlacePin));

      final tooltipCenter = tester.getCenter(
        find.byKey(const Key('place-pin-tooltip')),
      );
      final pinCenter = tester.getCenter(find.byType(PlacePin));
      expect(tooltipCenter.dx, moreOrLessEquals(pinCenter.dx, epsilon: 1.0));
    });

    testWidgets('short label shows the full name centered', (tester) async {
      const label = 'Mirador';
      await tester.pumpWidget(wrap(label: label));

      await hoverPin(tester, find.byType(PlacePin));

      expect(find.text(label), findsOneWidget);
      final tooltipCenter = tester.getCenter(
        find.byKey(const Key('place-pin-tooltip')),
      );
      final pinCenter = tester.getCenter(find.byType(PlacePin));
      expect(tooltipCenter.dx, moreOrLessEquals(pinCenter.dx, epsilon: 1.0));
    });

    testWidgets('shows no tooltip without hover', (tester) async {
      await tester.pumpWidget(wrap(label: 'Mirador'));

      expect(find.byKey(const Key('place-pin-tooltip')), findsNothing);
    });

    testWidgets('taps pass through to the child while hovering', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PinHoverTooltip(
                label: 'Mirador',
                child: GestureDetector(
                  onTap: () => taps++,
                  child: const PlacePin(icon: Icons.place),
                ),
              ),
            ),
          ),
        ),
      );

      await hoverPin(tester, find.byType(PlacePin));
      expect(find.byKey(const Key('place-pin-tooltip')), findsOneWidget);

      await tester.tap(find.byType(PlacePin));
      expect(taps, 1);
    });
  });
}
