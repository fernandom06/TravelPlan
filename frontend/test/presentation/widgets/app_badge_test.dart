import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/presentation/widgets/app_badge.dart';

void main() {
  testWidgets('renders the label uppercased with tracking and bold weight', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppBadge(
            label: 'próximamente',
            color: AppColors.primary,
            textColor: Colors.white,
          ),
        ),
      ),
    );

    expect(find.text('PRÓXIMAMENTE'), findsOneWidget);
    final text = tester.widget<Text>(find.text('PRÓXIMAMENTE'));
    final style = text.style!;
    expect(style.fontWeight, FontWeight.w700);
    expect(style.fontSize, 10);
    expect(style.letterSpacing, greaterThan(0));
    expect(style.color, Colors.white);
    expect(style.fontFamily, 'Lora');
  });

  testWidgets('applies the badge background color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppBadge(
            label: 'EN CURSO',
            color: AppColors.accent,
            textColor: Colors.white,
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.ancestor(of: find.text('EN CURSO'), matching: find.byType(Container)),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.accent);
    expect(decoration.borderRadius, AppRadii.pill);
  });

  testWidgets('renders an optional leading icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppBadge(
            label: 'PASADO',
            color: AppColors.muted,
            textColor: AppColors.text,
            icon: Icons.check,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}