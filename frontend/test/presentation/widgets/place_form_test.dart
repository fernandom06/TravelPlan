import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/presentation/widgets/place_form.dart';

const _naturaleza = Category(id: 1, name: 'Naturaleza');
const _monumento = Category(id: 2, name: 'Monumento');
const _categories = [_naturaleza, _monumento];

const _place = Place(
  id: 1,
  name: 'Mirador',
  description: 'Vistas del canon',
  latitude: 42.5,
  longitude: -3.1,
  category: _naturaleza,
);

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

FilledButton _saveButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardar'));

Future<void> _fillName(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'Mirador');
  await tester.pump();
}

Future<void> _selectCategory(WidgetTester tester, String name) async {
  await tester.tap(find.byType(DropdownButtonFormField<Category>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders name, category, description and save button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(categories: _categories, onSave: (_, _, _) {}, onCancel: () {}),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(DropdownButtonFormField<Category>), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('save is disabled when name is empty', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(categories: _categories, onSave: (_, _, _) {}, onCancel: () {}),
      ),
    );

    expect(_saveButton(tester).onPressed, isNull);
  });

  testWidgets('save is disabled when no category is selected', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(categories: _categories, onSave: (_, _, _) {}, onCancel: () {}),
      ),
    );

    await _fillName(tester);

    expect(_saveButton(tester).onPressed, isNull);
  });

  testWidgets('save is enabled when name and category are set', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(categories: _categories, onSave: (_, _, _) {}, onCancel: () {}),
      ),
    );

    await _fillName(tester);
    await _selectCategory(tester, 'Naturaleza');

    expect(_saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('pressing save calls onSave with the entered values', (
    tester,
  ) async {
    String? savedName;
    int? savedCategoryId;
    String? savedDescription;
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (name, categoryId, description) {
            savedName = name;
            savedCategoryId = categoryId;
            savedDescription = description;
          },
          onCancel: () {},
        ),
      ),
    );

    await _fillName(tester);
    await tester.enterText(find.byType(TextField).last, 'Vistas');
    await _selectCategory(tester, 'Monumento');

    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pump();

    expect(savedName, 'Mirador');
    expect(savedCategoryId, 2);
    expect(savedDescription, 'Vistas');
  });

  testWidgets('read-only mode disables fields and shows Cerrar', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          place: _place,
          onSave: (_, _, _) {},
          onCancel: () {},
        ),
      ),
    );

    expect(find.text('Guardar'), findsNothing);
    expect(find.text('Cerrar'), findsOneWidget);
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.enabled, isFalse);
    }
    final dropdown = tester.widget<DropdownButtonFormField<Category>>(
      find.byType(DropdownButtonFormField<Category>),
    );
    expect(dropdown.onChanged, isNull);
  });

  testWidgets('pressing Cerrar calls onCancel', (tester) async {
    var cancelled = false;
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          place: _place,
          onSave: (_, _, _) {},
          onCancel: () => cancelled = true,
        ),
      ),
    );

    await tester.tap(find.text('Cerrar'));
    await tester.pump();

    expect(cancelled, isTrue);
  });
}
