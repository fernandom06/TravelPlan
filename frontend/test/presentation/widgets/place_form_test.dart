import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/place_api.dart';
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

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

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
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) {},
          onCancel: () {},
        ),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(DropdownButtonFormField<Category>), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('save is disabled when name is empty', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) {},
          onCancel: () {},
        ),
      ),
    );

    expect(_saveButton(tester).onPressed, isNull);
  });

  testWidgets('save is disabled when no category is selected', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) {},
          onCancel: () {},
        ),
      ),
    );

    await _fillName(tester);

    expect(_saveButton(tester).onPressed, isNull);
  });

  testWidgets('save is enabled when name and category are set', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) {},
          onCancel: () {},
        ),
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

  testWidgets('read-only mode disables fields and shows Cerrar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PlaceDetails(categories: _categories, place: _place, onClose: () {}),
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

  testWidgets('PlaceDetails muestra el nombre y la categoría del lugar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PlaceDetails(categories: _categories, place: _place, onClose: () {}),
      ),
    );

    expect(find.text('Mirador'), findsOneWidget);
    expect(find.text('Naturaleza'), findsOneWidget);
  });

  testWidgets('pressing Cerrar calls onClose', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      _wrap(
        PlaceDetails(
          categories: _categories,
          place: _place,
          onClose: () {
            closed = true;
          },
        ),
      ),
    );

    await tester.tap(find.text('Cerrar'));
    await tester.pump();

    expect(closed, isTrue);
  });

  testWidgets('shows an affordance to create a new category', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) {},
          onCancel: () {},
          onCreateCategory: (_) async => const Category(id: 5, name: 'Playa'),
        ),
      ),
    );

    expect(find.text('Nueva categoría'), findsOneWidget);
  });

  testWidgets(
    'creating a category adds it to the dropdown without selecting it',
    (tester) async {
      String? createdName;
      await tester.pumpWidget(
        _wrap(
          PlaceForm(
            categories: _categories,
            onSave: (_, _, _) {},
            onCancel: () {},
            onCreateCategory: (name) async {
              createdName = name;
              return const Category(id: 5, name: 'Playa');
            },
          ),
        ),
      );

      await _fillName(tester);
      await _selectCategory(tester, 'Naturaleza');

      await tester.tap(find.text('Nueva categoría'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre de la categoría'),
        'Playa',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Crear'));
      await tester.pumpAndSettle();

      expect(createdName, 'Playa');
      expect(find.text('Naturaleza'), findsOneWidget);
      expect(find.text('Playa'), findsNothing);

      await tester.tap(find.byType(DropdownButtonFormField<Category>));
      await tester.pumpAndSettle();

      expect(find.text('Playa'), findsOneWidget);
    },
  );

  testWidgets('shows an inline error when the category already exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) {},
          onCancel: () {},
          onCreateCategory: (name) async =>
              throw const DuplicateCategoryException('duplicate'),
        ),
      ),
    );

    await tester.tap(find.text('Nueva categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre de la categoría'),
      'Playa',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Crear'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ya existe'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<Category>));
    await tester.pumpAndSettle();
    final items = tester.widgetList<DropdownMenuItem<Category>>(
      find.byType(DropdownMenuItem<Category>),
    );
    expect(items, hasLength(2));
  });

  testWidgets('shows an inline error when creating the category fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) {},
          onCancel: () {},
          onCreateCategory: (name) async =>
              throw const PlaceApiException('boom'),
        ),
      ),
    );

    await tester.tap(find.text('Nueva categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre de la categoría'),
      'Playa',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Crear'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo crear'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<Category>));
    await tester.pumpAndSettle();
    final items = tester.widgetList<DropdownMenuItem<Category>>(
      find.byType(DropdownMenuItem<Category>),
    );
    expect(items, hasLength(2));
  });

  testWidgets(
    'shows an inline error when creating a category fails with a generic exception',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          PlaceForm(
            categories: _categories,
            onSave: (_, _, _) {},
            onCancel: () {},
            onCreateCategory: (name) async => throw Exception('Network error'),
          ),
        ),
      );

      await tester.tap(find.text('Nueva categoría'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre de la categoría'),
        'Playa',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Crear'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No se pudo crear'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<Category>));
      await tester.pumpAndSettle();
      final items = tester.widgetList<DropdownMenuItem<Category>>(
        find.byType(DropdownMenuItem<Category>),
      );
      expect(items, hasLength(2));
    },
  );

  testWidgets('double tap on Crear does not call onCreateCategory twice', (
    tester,
  ) async {
    var callCount = 0;
    final completer = Completer<Category>();
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) {},
          onCancel: () {},
          onCreateCategory: (name) {
            callCount++;
            return completer.future;
          },
        ),
      ),
    );

    await tester.tap(find.text('Nueva categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre de la categoría'),
      'Playa',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Crear'));
    await tester.pump();

    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Crear'),
    );
    expect(createButton.onPressed, isNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Crear'));
    await tester.pump();

    expect(callCount, 1);

    completer.complete(const Category(id: 5, name: 'Playa'));
    await tester.pumpAndSettle();

    expect(callCount, 1);

    await tester.tap(find.byType(DropdownButtonFormField<Category>));
    await tester.pumpAndSettle();
    expect(find.text('Playa'), findsOneWidget);
  });

  testWidgets('keeps name and description when creating a category', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) {},
          onCancel: () {},
          onCreateCategory: (_) async => const Category(id: 5, name: 'Playa'),
        ),
      ),
    );

    await _fillName(tester);
    await tester.enterText(find.byType(TextField).last, 'Vistas');
    await tester.tap(find.text('Nueva categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre de la categoría'),
      'Playa',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Crear'));
    await tester.pumpAndSettle();

    expect(find.text('Mirador'), findsOneWidget);
    expect(find.text('Vistas'), findsOneWidget);
  });
}
