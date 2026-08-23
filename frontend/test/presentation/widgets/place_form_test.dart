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

  group('rename/delete category', () {
    PlaceForm form({
      List<Place> places = const [],
      Future<Category> Function(int id, String name)? onRenameCategory,
      Future<void> Function(int id, int? reassignTo)? onDeleteCategory,
    }) {
      return PlaceForm(
        categories: _categories,
        places: places,
        onSave: (_, _, _) {},
        onCancel: () {},
        onCreateCategory: (_) async => const Category(id: 9, name: 'Playa'),
        onRenameCategory: onRenameCategory,
        onDeleteCategory: onDeleteCategory,
      );
    }

    testWidgets(
      'shows rename and delete affordances only with a selection and callbacks',
      (tester) async {
        await tester.pumpWidget(_wrap(form()));

        await _fillName(tester);
        await _selectCategory(tester, 'Naturaleza');

        expect(find.byIcon(Icons.edit), findsNothing);
        expect(find.byIcon(Icons.delete_outline), findsNothing);

        await tester.pumpWidget(
          _wrap(
            form(
              onRenameCategory: (_, name) async =>
                  const Category(id: 1, name: 'X'),
              onDeleteCategory: (_, _) async {},
            ),
          ),
        );

        await _fillName(tester);
        await _selectCategory(tester, 'Naturaleza');

        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      },
    );

    testWidgets('renaming updates the dropdown and keeps the selection', (
      tester,
    ) async {
      String? renamedId;
      String? renamedName;
      await tester.pumpWidget(
        _wrap(
          form(
            onRenameCategory: (id, name) async {
              renamedId = '$id';
              renamedName = name;
              return const Category(id: 1, name: 'Costa');
            },
          ),
        ),
      );

      await _fillName(tester);
      await _selectCategory(tester, 'Naturaleza');

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nuevo nombre'),
        'Costa',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Renombrar'));
      await tester.pumpAndSettle();

      expect(renamedId, '1');
      expect(renamedName, 'Costa');
      final dropdown = tester.widget<DropdownButtonFormField<Category>>(
        find.byType(DropdownButtonFormField<Category>),
      );
      expect(dropdown.initialValue, const Category(id: 1, name: 'Costa'));
      expect(find.text('Costa'), findsOneWidget);
      expect(_saveButton(tester).onPressed, isNotNull);
    });

    testWidgets('shows an inline error when renaming to an existing name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          form(
            onRenameCategory: (_, _) async =>
                throw const DuplicateCategoryException('duplicate'),
          ),
        ),
      );

      await _fillName(tester);
      await _selectCategory(tester, 'Naturaleza');
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nuevo nombre'),
        'Monumento',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Renombrar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ya existe una categoría con ese nombre'),
        findsOneWidget,
      );
    });

    testWidgets(
      'empty rename shows an inline error and does not call the callback',
      (tester) async {
        var called = false;
        await tester.pumpWidget(
          _wrap(
            form(
              onRenameCategory: (_, _) async {
                called = true;
                return const Category(id: 1, name: 'X');
              },
            ),
          ),
        );

        await _fillName(tester);
        await _selectCategory(tester, 'Naturaleza');
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Nuevo nombre'),
          '',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Renombrar'));
        await tester.pumpAndSettle();

        expect(find.text('El nombre no puede estar vacío'), findsOneWidget);
        expect(called, isFalse);
      },
    );

    testWidgets('shows an inline error when renaming fails', (tester) async {
      await tester.pumpWidget(
        _wrap(
          form(
            onRenameCategory: (_, _) async =>
                throw const PlaceApiException('boom'),
          ),
        ),
      );

      await _fillName(tester);
      await _selectCategory(tester, 'Naturaleza');
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nuevo nombre'),
        'Costa',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Renombrar'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo renombrar la categoría'), findsOneWidget);
    });

    testWidgets('double tap on Renombrar does not call the callback twice', (
      tester,
    ) async {
      var callCount = 0;
      final completer = Completer<Category>();
      await tester.pumpWidget(
        _wrap(
          form(
            onRenameCategory: (_, _) {
              callCount++;
              return completer.future;
            },
          ),
        ),
      );

      await _fillName(tester);
      await _selectCategory(tester, 'Naturaleza');
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nuevo nombre'),
        'Costa',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Renombrar'));
      await tester.pump();
      final renameButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Renombrar'),
      );
      expect(renameButton.onPressed, isNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Renombrar'));
      await tester.pump();

      expect(callCount, 1);

      completer.complete(const Category(id: 1, name: 'Costa'));
      await tester.pumpAndSettle();
      expect(callCount, 1);
    });

    testWidgets(
      'deleting a category without places confirms, removes it and clears selection',
      (tester) async {
        int? deletedId;
        int? reassignTo;
        await tester.pumpWidget(
          _wrap(
            form(
              places: [_place],
              onDeleteCategory: (id, reassign) async {
                deletedId = id;
                reassignTo = reassign;
              },
            ),
          ),
        );

        await _fillName(tester);
        await _selectCategory(tester, 'Monumento');
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
        await tester.pumpAndSettle();

        expect(deletedId, 2);
        expect(reassignTo, isNull);

        await tester.tap(find.byType(DropdownButtonFormField<Category>));
        await tester.pumpAndSettle();
        expect(find.text('Monumento'), findsNothing);
        expect(find.text('Naturaleza'), findsOneWidget);
      },
    );

    testWidgets('deleting the selected category disables save', (tester) async {
      await tester.pumpWidget(
        _wrap(form(places: [_place], onDeleteCategory: (_, _) async {})),
      );

      await _fillName(tester);
      await _selectCategory(tester, 'Monumento');
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(_saveButton(tester).onPressed, isNull);
    });

    testWidgets(
      'deleting a category with places shows count and destination dropdown',
      (tester) async {
        int? deletedId;
        int? reassignTo;
        await tester.pumpWidget(
          _wrap(
            form(
              places: [_place],
              onDeleteCategory: (id, reassign) async {
                deletedId = id;
                reassignTo = reassign;
              },
            ),
          ),
        );

        await _fillName(tester);
        await _selectCategory(tester, 'Naturaleza');
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.textContaining('tiene 1 lugar'), findsOneWidget);

        await tester.tap(find.byType(DropdownButtonFormField<Category>).last);
        await tester.pumpAndSettle();
        final items = tester.widgetList<DropdownMenuItem<Category>>(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(DropdownMenuItem<Category>),
          ),
        );
        expect(items.map((i) => i.value!.id), isNot(contains(1)));
        expect(items.map((i) => i.value!.id), contains(2));

        await tester.tap(find.text('Monumento').last);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
        await tester.pumpAndSettle();

        expect(deletedId, 1);
        expect(reassignTo, 2);
      },
    );

    testWidgets('deleting the only category with places is blocked', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(
          PlaceForm(
            categories: [_naturaleza],
            places: [_place],
            onSave: (_, _, _) {},
            onCancel: () {},
            onDeleteCategory: (_, _) async {
              called = true;
            },
          ),
        ),
      );

      await _fillName(tester);
      await _selectCategory(tester, 'Naturaleza');
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.textContaining('única categoría'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Eliminar'),
        ),
        findsNothing,
      );
      expect(called, isFalse);
    });

    testWidgets(
      'shows a message when deleting fails with CategoryNotEmptyException',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            form(
              places: [_place],
              onDeleteCategory: (_, _) async =>
                  throw const CategoryNotEmptyException('conflict'),
            ),
          ),
        );

        await _fillName(tester);
        await _selectCategory(tester, 'Monumento');
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
        await tester.pumpAndSettle();

        expect(find.textContaining('lugares sin destino'), findsOneWidget);
      },
    );

    testWidgets(
      'shows a message when deleting fails with InvalidReassignTargetException',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            form(
              places: [_place],
              onDeleteCategory: (_, _) async =>
                  throw const InvalidReassignTargetException('invalid'),
            ),
          ),
        );

        await _fillName(tester);
        await _selectCategory(tester, 'Monumento');
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
        await tester.pumpAndSettle();

        expect(find.text('El destino no es válido'), findsOneWidget);
      },
    );

    testWidgets('shows a message when deleting fails with a generic error', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          form(
            places: [_place],
            onDeleteCategory: (_, _) async => throw Exception('boom'),
          ),
        ),
      );

      await _fillName(tester);
      await _selectCategory(tester, 'Monumento');
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo eliminar la categoría'), findsOneWidget);
    });
  });
}
