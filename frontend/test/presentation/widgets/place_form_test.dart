import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/place_api.dart';
import 'package:frontend/presentation/widgets/category_dropdown.dart';
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

Future<void> _openCategoryMenu(WidgetTester tester) async {
  await tester.tap(find.byType(CategoryDropdown));
  await tester.pumpAndSettle();
}

Future<void> _selectCategory(WidgetTester tester, String name) async {
  await _openCategoryMenu(tester);
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Future<void> _tapEditOn(WidgetTester tester, String name) async {
  final row = find.ancestor(
    of: find.text(name),
    matching: find.byType(ListTile),
  );
  await tester.tap(find.descendant(of: row, matching: find.byIcon(Icons.edit)));
  await tester.pumpAndSettle();
}

Future<void> _tapDeleteOn(WidgetTester tester, String name) async {
  final row = find.ancestor(
    of: find.text(name),
    matching: find.byType(ListTile),
  );
  await tester.tap(
    find.descendant(of: row, matching: find.byIcon(Icons.delete_outline)),
  );
  await tester.pumpAndSettle();
}

Future<void> _confirmInline(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.check));
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
    expect(find.byType(CategoryDropdown), findsOneWidget);
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

  testWidgets('pressing Enter on the name submits the form', (tester) async {
    String? savedName;
    int? savedCategoryId;
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (name, categoryId, _) {
            savedName = name;
            savedCategoryId = categoryId;
          },
          onCancel: () {},
        ),
      ),
    );

    await _selectCategory(tester, 'Monumento');
    await _fillName(tester);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(savedName, 'Mirador');
    expect(savedCategoryId, 2);
  });

  testWidgets('pressing Enter on the description submits the form', (
    tester,
  ) async {
    String? savedName;
    int? savedCategoryId;
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (name, categoryId, _) {
            savedName = name;
            savedCategoryId = categoryId;
          },
          onCancel: () {},
        ),
      ),
    );

    await _selectCategory(tester, 'Monumento');
    await _fillName(tester);
    await tester.enterText(find.byType(TextField).last, 'Vistas');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(savedName, 'Mirador');
    expect(savedCategoryId, 2);
  });

  testWidgets('pressing Enter does not submit when the form is invalid', (
    tester,
  ) async {
    var submitted = false;
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) => submitted = true,
          onCancel: () {},
        ),
      ),
    );

    await _fillName(tester);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted, isFalse);
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
    // The category dropdown is present, but tapping it does not open the menu.
    expect(find.byType(CategoryDropdown), findsOneWidget);
    await tester.tap(find.byType(CategoryDropdown));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNothing);
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
          onCreateCategory: (_, _) async =>
              const Category(id: 5, name: 'Playa'),
        ),
      ),
    );

    await _openCategoryMenu(tester);
    expect(find.text('Nueva categoría'), findsOneWidget);
  });

  testWidgets('creating a category autoselects it', (tester) async {
    String? createdName;
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) {},
          onCancel: () {},
          onCreateCategory: (name, icon) async {
            createdName = name;
            return const Category(id: 5, name: 'Playa');
          },
        ),
      ),
    );

    await _fillName(tester);
    await _selectCategory(tester, 'Naturaleza');

    await _openCategoryMenu(tester);
    await tester.tap(find.text('Nueva categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre de la categoría'),
      'Playa',
    );
    await _confirmInline(tester);

    expect(createdName, 'Playa');
    // Autoselected: the trigger and the menu row both show 'Playa'.
    expect(find.text('Playa'), findsNWidgets(2));
    // Guardar is enabled once a category is selected and the name is set.
    expect(_saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('shows an inline error when the category already exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) {},
          onCancel: () {},
          onCreateCategory: (_, _) async =>
              throw const DuplicateCategoryException('duplicate'),
        ),
      ),
    );

    await _openCategoryMenu(tester);
    await tester.tap(find.text('Nueva categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre de la categoría'),
      'Playa',
    );
    await _confirmInline(tester);

    expect(find.textContaining('Ya existe'), findsOneWidget);
    // The new category row is not added to the list.
    expect(find.widgetWithText(ListTile, 'Playa'), findsNothing);
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
          onCreateCategory: (_, _) async =>
              throw const PlaceApiException('boom'),
        ),
      ),
    );

    await _openCategoryMenu(tester);
    await tester.tap(find.text('Nueva categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre de la categoría'),
      'Playa',
    );
    await _confirmInline(tester);

    expect(find.textContaining('No se pudo crear'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Playa'), findsNothing);
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
            onCreateCategory: (_, _) async => throw Exception('Network error'),
          ),
        ),
      );

      await _openCategoryMenu(tester);
      await tester.tap(find.text('Nueva categoría'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre de la categoría'),
        'Playa',
      );
      await _confirmInline(tester);

      expect(find.textContaining('No se pudo crear'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Playa'), findsNothing);
    },
  );

  testWidgets('double tap on confirm does not call onCreateCategory twice', (
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
          onCreateCategory: (_, _) {
            callCount++;
            return completer.future;
          },
        ),
      ),
    );

    await _openCategoryMenu(tester);
    await tester.tap(find.text('Nueva categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre de la categoría'),
      'Playa',
    );

    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    final checkButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.check),
    );
    expect(checkButton.onPressed, isNull);

    await tester.tap(find.byIcon(Icons.check), warnIfMissed: false);
    await tester.pump();

    expect(callCount, 1);

    completer.complete(const Category(id: 5, name: 'Playa'));
    await tester.pumpAndSettle();

    expect(callCount, 1);
    expect(find.text('Playa'), findsNWidgets(2));
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
          onCreateCategory: (_, _) async =>
              const Category(id: 5, name: 'Playa'),
        ),
      ),
    );

    await _fillName(tester);
    await tester.enterText(find.byType(TextField).last, 'Vistas');
    await _openCategoryMenu(tester);
    await tester.tap(find.text('Nueva categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre de la categoría'),
      'Playa',
    );
    await _confirmInline(tester);

    expect(find.text('Mirador'), findsOneWidget);
    expect(find.text('Vistas'), findsOneWidget);
  });

  group('rename/delete category', () {
    PlaceForm form({
      List<Place> places = const [],
      Future<Category> Function(int id, String name, String? icon)?
      onRenameCategory,
      Future<void> Function(int id, int? reassignTo)? onDeleteCategory,
    }) {
      return PlaceForm(
        categories: _categories,
        places: places,
        onSave: (_, _, _) {},
        onCancel: () {},
        onCreateCategory: (_, _) async => const Category(id: 9, name: 'Playa'),
        onRenameCategory: onRenameCategory,
        onDeleteCategory: onDeleteCategory,
      );
    }

    testWidgets('shows no edit/delete icons without callbacks', (tester) async {
      await tester.pumpWidget(_wrap(form()));

      await _fillName(tester);
      await _openCategoryMenu(tester);

      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('shows edit/delete icons per row when callbacks are present', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          form(
            onRenameCategory: (_, name, _) async =>
                const Category(id: 1, name: 'X'),
            onDeleteCategory: (_, _) async {},
          ),
        ),
      );

      await _fillName(tester);
      await _openCategoryMenu(tester);

      // One edit + one delete per row (2 rows).
      expect(find.byIcon(Icons.edit), findsNWidgets(2));
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });

    testWidgets('renaming updates the dropdown and keeps the selection', (
      tester,
    ) async {
      String? renamedId;
      String? renamedName;
      await tester.pumpWidget(
        _wrap(
          form(
            onRenameCategory: (id, name, icon) async {
              renamedId = '$id';
              renamedName = name;
              return const Category(id: 1, name: 'Costa');
            },
          ),
        ),
      );

      await _fillName(tester);
      await _selectCategory(tester, 'Naturaleza');

      await _openCategoryMenu(tester);
      await _tapEditOn(tester, 'Naturaleza');
      await tester.enterText(
        find.widgetWithText(TextField, 'Nuevo nombre'),
        'Costa',
      );
      await _confirmInline(tester);

      expect(renamedId, '1');
      expect(renamedName, 'Costa');
      // The trigger and the row show the new name; the menu stays open.
      expect(find.text('Costa'), findsNWidgets(2));
      expect(_saveButton(tester).onPressed, isNotNull);
    });

    testWidgets('shows an inline error when renaming to an existing name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          form(
            onRenameCategory: (_, _, _) async =>
                throw const DuplicateCategoryException('duplicate'),
          ),
        ),
      );

      await _fillName(tester);
      await _selectCategory(tester, 'Naturaleza');
      await _openCategoryMenu(tester);
      await _tapEditOn(tester, 'Naturaleza');
      await tester.enterText(
        find.widgetWithText(TextField, 'Nuevo nombre'),
        'Monumento',
      );
      await _confirmInline(tester);

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
              onRenameCategory: (_, _, _) async {
                called = true;
                return const Category(id: 1, name: 'X');
              },
            ),
          ),
        );

        await _fillName(tester);
        await _selectCategory(tester, 'Naturaleza');
        await _openCategoryMenu(tester);
        await _tapEditOn(tester, 'Naturaleza');
        await tester.enterText(
          find.widgetWithText(TextField, 'Nuevo nombre'),
          '',
        );
        await _confirmInline(tester);

        expect(find.text('El nombre no puede estar vacío'), findsOneWidget);
        expect(called, isFalse);
      },
    );

    testWidgets('shows an inline error when renaming fails', (tester) async {
      await tester.pumpWidget(
        _wrap(
          form(
            onRenameCategory: (_, _, _) async =>
                throw const PlaceApiException('boom'),
          ),
        ),
      );

      await _fillName(tester);
      await _selectCategory(tester, 'Naturaleza');
      await _openCategoryMenu(tester);
      await _tapEditOn(tester, 'Naturaleza');
      await tester.enterText(
        find.widgetWithText(TextField, 'Nuevo nombre'),
        'Costa',
      );
      await _confirmInline(tester);

      expect(find.text('No se pudo renombrar la categoría'), findsOneWidget);
    });

    testWidgets('double tap on confirm does not call rename twice', (
      tester,
    ) async {
      var callCount = 0;
      final completer = Completer<Category>();
      await tester.pumpWidget(
        _wrap(
          form(
            onRenameCategory: (_, _, _) {
              callCount++;
              return completer.future;
            },
          ),
        ),
      );

      await _fillName(tester);
      await _selectCategory(tester, 'Naturaleza');
      await _openCategoryMenu(tester);
      await _tapEditOn(tester, 'Naturaleza');
      await tester.enterText(
        find.widgetWithText(TextField, 'Nuevo nombre'),
        'Costa',
      );

      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();
      final checkButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.check),
      );
      expect(checkButton.onPressed, isNull);

      await tester.tap(find.byIcon(Icons.check), warnIfMissed: false);
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

        await _openCategoryMenu(tester);
        await _tapDeleteOn(tester, 'Monumento');

        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
        await tester.pumpAndSettle();

        expect(deletedId, 2);
        expect(reassignTo, isNull);
        // The deleted (selected) category is gone from the list.
        expect(find.widgetWithText(ListTile, 'Monumento'), findsNothing);
      },
    );

    testWidgets('deleting the selected category disables save', (tester) async {
      await tester.pumpWidget(
        _wrap(form(places: [_place], onDeleteCategory: (_, _) async {})),
      );

      await _fillName(tester);
      await _selectCategory(tester, 'Monumento');
      await _openCategoryMenu(tester);
      await _tapDeleteOn(tester, 'Monumento');
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
        await _openCategoryMenu(tester);
        await _tapDeleteOn(tester, 'Naturaleza');

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
      await _openCategoryMenu(tester);
      await _tapDeleteOn(tester, 'Naturaleza');

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
        await _openCategoryMenu(tester);
        await _tapDeleteOn(tester, 'Monumento');
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
        await _openCategoryMenu(tester);
        await _tapDeleteOn(tester, 'Monumento');
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
      await _openCategoryMenu(tester);
      await _tapDeleteOn(tester, 'Monumento');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo eliminar la categoría'), findsOneWidget);
    });
  });

  group('edit mode', () {
    testWidgets('PlaceDetails with onEdit shows Editar and calls it on tap', (
      tester,
    ) async {
      var edited = false;
      await tester.pumpWidget(
        _wrap(
          PlaceDetails(
            categories: _categories,
            place: _place,
            onClose: () {},
            onEdit: () {
              edited = true;
            },
          ),
        ),
      );

      expect(find.text('Editar'), findsOneWidget);
      await tester.tap(find.text('Editar'));
      await tester.pump();

      expect(edited, isTrue);
    });

    testWidgets('PlaceForm pre-fills name, category and enables Guardar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          PlaceForm(
            categories: _categories,
            initialName: 'Mirador',
            initialDescription: 'Vistas del canon',
            initialCategory: _naturaleza,
            onSave: (_, _, _) {},
            onCancel: () {},
          ),
        ),
      );

      expect(find.text('Mirador'), findsOneWidget);
      expect(find.text('Vistas del canon'), findsOneWidget);
      expect(find.text('Naturaleza'), findsOneWidget);
      expect(_saveButton(tester).onPressed, isNotNull);
    });

    testWidgets('Eliminar shows a confirm dialog and cancelling does nothing', (
      tester,
    ) async {
      var deleted = false;
      await tester.pumpWidget(
        _wrap(
          PlaceForm(
            categories: _categories,
            initialName: 'Mirador',
            initialCategory: _naturaleza,
            onSave: (_, _, _) {},
            onCancel: () {},
            onDelete: () {
              deleted = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('¿Eliminar este lugar?'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cancelar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(deleted, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('confirming the delete dialog calls onDelete', (tester) async {
      var deleted = false;
      await tester.pumpWidget(
        _wrap(
          PlaceForm(
            categories: _categories,
            initialName: 'Mirador',
            initialCategory: _naturaleza,
            onSave: (_, _, _) {},
            onCancel: () {},
            onDelete: () {
              deleted = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });
  });
}
