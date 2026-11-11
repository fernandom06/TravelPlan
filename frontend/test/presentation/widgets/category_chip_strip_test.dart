import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/category_icon_catalog.dart';
import 'package:frontend/data/models/category.dart';
import 'package:frontend/presentation/widgets/category_chip_strip.dart';

const _naturaleza = Category(id: 1, name: 'Naturaleza');
const _monumento = Category(id: 2, name: 'Monumento');

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('renders a pill per category with its icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CategoryChipStrip(
          categories: [_naturaleza, _monumento],
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Naturaleza'), findsOneWidget);
    expect(find.text('Monumento'), findsOneWidget);
    expect(find.byIcon(categoryPlaceholderIcon), findsNWidgets(2));
  });

  testWidgets('tapping a chip selects it', (tester) async {
    Category? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Center(
                child: CategoryChipStrip(
                  categories: [_naturaleza, _monumento],
                  value: selected,
                  onChanged: (c) => setState(() => selected = c),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Monumento'));
    await tester.pumpAndSettle();

    expect(selected, _monumento);
  });

  testWidgets('selected chip is visually distinct (mint)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CategoryChipStrip(
          categories: [_naturaleza, _monumento],
          value: _naturaleza,
          onChanged: (_) {},
        ),
      ),
    );

    final selectedChip = tester.widget<AnimatedScale>(
      find.ancestor(
        of: find.text('Naturaleza'),
        matching: find.byType(AnimatedScale),
      ),
    );
    expect(selectedChip.scale, 1.05);
  });

  testWidgets('disabled strip shows no add chip and does not manage', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        CategoryChipStrip(
          categories: [_naturaleza],
          value: _naturaleza,
          enabled: false,
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Naturaleza'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);

    await tester.longPress(find.text('Naturaleza'));
    await tester.pumpAndSettle();
    expect(find.text('Editar'), findsNothing);
  });

  testWidgets('is a pure selector: no add chip and no management actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        CategoryChipStrip(
          categories: [_naturaleza, _monumento],
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsNothing);

    await tester.longPress(find.text('Naturaleza'));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsNothing);
    expect(find.text('Borrar'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });

  group('horizontal scrolling', () {
    List<Category> manyCategories() => [
      for (var i = 0; i < 12; i++) Category(id: i, name: 'Categoría $i'),
    ];

    Finder stripScrollable() => find
        .descendant(
          of: find.byType(CategoryChipStrip),
          matching: find.byType(Scrollable),
        )
        .first;

    testWidgets('strip scrolls horizontally with many categories', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 300,
            child: CategoryChipStrip(
              categories: manyCategories(),
              value: const Category(id: 0, name: 'Categoría 0'),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final scrollable = stripScrollable();
      expect(scrollable, findsOneWidget);
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('chips outside the initial viewport appear after scrolling', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 300,
            child: CategoryChipStrip(
              categories: manyCategories(),
              value: const Category(id: 0, name: 'Categoría 0'),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final scrollable = stripScrollable();
      final viewport = tester.getRect(scrollable);
      expect(
        tester.getRect(find.text('Categoría 11')).right,
        greaterThan(viewport.right),
      );

      await tester.scrollUntilVisible(
        find.text('Categoría 11'),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('Categoría 11'), findsOneWidget);
      final newViewport = tester.getRect(stripScrollable());
      expect(
        tester.getRect(find.text('Categoría 11')).right,
        lessThanOrEqualTo(newViewport.right + 1),
      );
    });
  });
}
