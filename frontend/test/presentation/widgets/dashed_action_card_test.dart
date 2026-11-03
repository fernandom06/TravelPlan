import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/presentation/widgets/dashed_action_card.dart';
import 'package:frontend/presentation/widgets/dashed_border_container.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders the add icon, dashed border and the label', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const DashedActionCard(label: '¿Añadimos un lugar?', onTap: _noop)),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.add));
    expect(icon.size, 40);
    expect(find.text('¿Añadimos un lugar?'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is DashedBorderPainter,
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping the card invokes onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        DashedActionCard(label: '¿A dónde vamos?', onTap: () => tapped = true),
      ),
    );

    await tester.tap(find.text('¿A dónde vamos?'));
    expect(tapped, isTrue);
  });

  testWidgets('renders arbitrary labels verbatim', (tester) async {
    await tester.pumpWidget(
      wrap(const DashedActionCard(label: '¿A dónde vamos?', onTap: _noop)),
    );
    expect(find.text('¿A dónde vamos?'), findsOneWidget);

    await tester.pumpWidget(
      wrap(const DashedActionCard(label: '¿Añadimos un lugar?', onTap: _noop)),
    );
    expect(find.text('¿Añadimos un lugar?'), findsOneWidget);
  });

  testWidgets('compact variant uses a smaller icon', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DashedActionCard(
          label: '¿Añadimos un lugar?',
          onTap: _noop,
          compact: true,
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.add));
    expect(icon.size, 20);
    expect(find.text('¿Añadimos un lugar?'), findsOneWidget);
  });

  testWidgets('compact label uses the secondary text color', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DashedActionCard(
          label: '¿Añadimos un lugar?',
          onTap: _noop,
          compact: true,
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('¿Añadimos un lugar?'));
    expect(label.style?.color, AppColors.textSecondary);
  });

  testWidgets('full label keeps the primary text color', (tester) async {
    await tester.pumpWidget(
      wrap(const DashedActionCard(label: '¿A dónde vamos?', onTap: _noop)),
    );

    final label = tester.widget<Text>(find.text('¿A dónde vamos?'));
    expect(label.style?.color, AppColors.text);
  });
}

void _noop() {}
