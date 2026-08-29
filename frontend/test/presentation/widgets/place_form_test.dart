import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/place_api.dart';
import 'package:frontend/presentation/widgets/category_chip_strip.dart';
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
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardar Lugar'));

Future<void> _fillName(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'Mirador');
  await tester.pump();
}

Future<void> _selectCategory(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

Future<void> _startCreate(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
}

Future<void> _startRename(WidgetTester tester, String name) async {
  await tester.longPress(find.text(name));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Editar'));
  await tester.pumpAndSettle();
}

Future<void> _startDelete(WidgetTester tester, String name) async {
  await tester.longPress(find.text(name));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Borrar'));
  await tester.pumpAndSettle();
}

Future<void> _confirmInline(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.check));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('name field is a wireframe-style Fraunces input', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) {},
          onCancel: () {},
        ),
      ),
    );

    expect(find.text('Nombra este rincón...'), findsOneWidget);
    final nameField = tester.widget<TextField>(find.byType(TextField).first);
    expect(nameField.style?.fontFamily, 'Fraunces');
    expect(nameField.style?.fontWeight, FontWeight.w600);
    expect(nameField.style?.fontSize, 24);
  });

  testWidgets('description textarea sits on a paper tone', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) {},
          onCancel: () {},
        ),
      ),
    );

    final descriptionField = tester.widget<TextField>(
      find.byType(TextField).last,
    );
    expect(descriptionField.decoration?.filled, isTrue);
  });

  testWidgets('footer shows a terracotta Guardar Lugar button', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) {},
          onCancel: () {},
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Guardar Lugar'),
    );
    expect(button.style?.backgroundColor?.resolve({}), AppColors.primary);
    final size = tester.getSize(
      find.widgetWithText(FilledButton, 'Guardar Lugar'),
    );
    expect(size.height, greaterThanOrEqualTo(48));
  });

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
    expect(find.byType(CategoryChipStrip), findsOneWidget);
    expect(find.text('Guardar Lugar'), findsOneWidget);
  });

  testWidgets('autofocus on Nombre in create mode', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) {},
          onCancel: () {},
        ),
      ),
    );
    await tester.pump();

    final nameField = tester.widget<EditableText>(
      find.byType(EditableText).first,
    );
    expect(nameField.focusNode.hasFocus, isTrue);
  });

  testWidgets('autofocus on Nombre in edit mode', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          initialName: 'Mirador',
          initialCategory: _naturaleza,
          onSave: (_, _, _) {},
          onCancel: () {},
        ),
      ),
    );
    await tester.pump();

    final nameField = tester.widget<EditableText>(
      find.byType(EditableText).first,
    );
    expect(nameField.focusNode.hasFocus, isTrue);
  });

  testWidgets('PlaceDetails does not autofocus', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlaceDetails(
          categories: _categories,
          place: _place,
          onClose: () {},
        ),
      ),
    );
    await tester.pump();

    final editable = tester.widget<EditableText>(
      find.byType(EditableText).first,
    );
    expect(editable.focusNode.hasFocus, isFalse);
  });

  testWidgets('Tab from Nombre moves focus into the category chips', (
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
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final chipFocus = Focus.maybeOf(
      tester.element(find.text('Naturaleza')),
    );
    expect(chipFocus, isNotNull);
    expect(chipFocus!.hasPrimaryFocus, isTrue);
  });

  testWidgets('Tab traverses Nombre, chips and Descripcion', (tester) async {
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
    await tester.pump();

    // 1: Nombre -> first chip (Naturaleza).
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(
      Focus.maybeOf(tester.element(find.text('Naturaleza')))!
          .hasPrimaryFocus,
      isTrue,
    );

    // 2: Naturaleza -> Monumento.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(
      Focus.maybeOf(tester.element(find.text('Monumento')))!
          .hasPrimaryFocus,
      isTrue,
    );

    // 3: Monumento -> add chip.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(
      Focus.maybeOf(tester.element(find.byIcon(Icons.add)))!.hasPrimaryFocus,
      isTrue,
    );

    // 4: add chip -> Descripcion.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final descriptionField = tester.widget<EditableText>(
      find.byType(EditableText).at(1),
    );
    expect(descriptionField.focusNode.hasFocus, isTrue);
  });

  testWidgets('Shift+Tab from Descripcion returns focus to the chips', (
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
    await tester.pump();

    // Reach Descripcion via the tab sequence (Nombre -> 3 chips -> Descripcion).
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    final descriptionField = tester.widget<EditableText>(
      find.byType(EditableText).at(1),
    );
    expect(descriptionField.focusNode.hasFocus, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();

    // Focus returned to the add chip (last focusable of the strip).
    expect(
      Focus.maybeOf(tester.element(find.byIcon(Icons.add)))!
          .hasPrimaryFocus,
      isTrue,
    );
  });

  testWidgets('disabled Guardar is skipped by Tab', (tester) async {
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
    await tester.pump();

    // Name is empty so Guardar is disabled.
    expect(_saveButton(tester).onPressed, isNull);

    // Reach Descripcion: Nombre -> 3 chips -> Descripcion.
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    final descriptionField = tester.widget<EditableText>(
      find.byType(EditableText).at(1),
    );
    expect(descriptionField.focusNode.hasFocus, isTrue);

    // A Tab from Descripcion crosses the button row skipping the disabled
    // Guardar, landing on Cancelar.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final primary = FocusManager.instance.primaryFocus;
    final cancelFinder = find.widgetWithText(TextButton, 'Cancelar');
    final onCancel =
        primary != null &&
        find
            .descendant(
              of: cancelFinder,
              matching: find.byWidgetPredicate(
                (w) => w == primary.context?.widget,
              ),
            )
            .evaluate()
            .isNotEmpty;
    expect(onCancel, isTrue);

    final saveFinder = find.widgetWithText(FilledButton, 'Guardar Lugar');
    final onSave =
        primary != null &&
        find
            .descendant(
              of: saveFinder,
              matching: find.byWidgetPredicate(
                (w) => w == primary.context?.widget,
              ),
            )
            .evaluate()
            .isNotEmpty;
    expect(onSave, isFalse);
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

    await tester.tap(find.widgetWithText(FilledButton, 'Guardar Lugar'));

    expect(savedName, 'Mirador');
    expect(savedCategoryId, 2);
    expect(savedDescription, 'Vistas');
  });

  testWidgets('name field uses textInputAction next', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) {},
          onCancel: () {},
        ),
      ),
    );

    final nameField = tester.widget<TextField>(find.byType(TextField).first);
    expect(nameField.textInputAction, TextInputAction.next);
  });

  testWidgets('pressing next on name moves focus to category without saving', (
    tester,
  ) async {
    var saved = false;
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) => saved = true,
          onCancel: () {},
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final chipFocus = Focus.maybeOf(
      tester.element(find.text('Naturaleza')),
    );
    expect(chipFocus!.hasPrimaryFocus, isTrue);
    expect(saved, isFalse);
  });

  testWidgets('pressing next on the name does not save', (tester) async {
    var saved = false;
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (_, _, _) => saved = true,
          onCancel: () {},
        ),
      ),
    );

    await _fillName(tester);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    expect(saved, isFalse);
  });

  testWidgets('pressing Enter on the description submits the form', (
    tester,
  ) async {
    String? savedName;
    await tester.pumpWidget(
      _wrap(
        PlaceForm(
          categories: _categories,
          onSave: (name, _, _) => savedName = name,
          onCancel: () {},
        ),
      ),
    );

    await _fillName(tester);
    await _selectCategory(tester, 'Naturaleza');
    await tester.enterText(find.byType(TextField).last, 'Vistas');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(savedName, 'Mirador');
  });

  testWidgets('read-only mode disables fields and shows Cerrar', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlaceDetails(
          categories: _categories,
          place: _place,
          onClose: () {},
        ),
      ),
    );

    final nameField = tester.widget<TextField>(find.byType(TextField).first);
    expect(nameField.enabled, isFalse);
    expect(find.text('Cerrar'), findsOneWidget);
  });

  testWidgets('PlaceDetails muestra el nombre y la categoría del lugar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PlaceDetails(
          categories: _categories,
          place: _place,
          onClose: () {},
        ),
      ),
    );

    expect(find.text('Mirador'), findsOneWidget);
    expect(find.text('Naturaleza'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('pressing Cerrar calls onClose', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      _wrap(
        PlaceDetails(
          categories: _categories,
          place: _place,
          onClose: () => closed = true,
        ),
      ),
    );

    await tester.tap(find.text('Cerrar'));
    await tester.pump();

    expect(closed, isTrue);
  });

  testWidgets('shows an add chip to create a new category', (tester) async {
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

    expect(find.byIcon(Icons.add), findsOneWidget);
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

    await _startCreate(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre de la categoría'),
      'Playa',
    );
    await _confirmInline(tester);

    expect(createdName, 'Playa');
    // Autoselected: the new chip appears and is selected.
    expect(find.text('Playa'), findsOneWidget);
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

    await _startCreate(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre de la categoría'),
      'Playa',
    );
    await _confirmInline(tester);

    expect(find.textContaining('Ya existe'), findsOneWidget);

    // Cancel the editor: no Playa chip was created.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Playa'), findsNothing);
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

    await _startCreate(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre de la categoría'),
      'Playa',
    );
    await _confirmInline(tester);

    expect(find.textContaining('No se pudo crear'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Playa'), findsNothing);
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

      await _startCreate(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre de la categoría'),
        'Playa',
      );
      await _confirmInline(tester);

      expect(find.textContaining('No se pudo crear'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Playa'), findsNothing);
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

    await _startCreate(tester);
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
          onCreateCategory: (_, _) async =>
              const Category(id: 5, name: 'Playa'),
        ),
      ),
    );

    await _fillName(tester);
    await tester.enterText(find.byType(TextField).last, 'Vistas');
    await _startCreate(tester);
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

    testWidgets('no overflow menu is shown without callbacks', (tester) async {
      await tester.pumpWidget(_wrap(form()));

      await _fillName(tester);
      await tester.longPress(find.text('Naturaleza'));
      await tester.pumpAndSettle();

      expect(find.text('Editar'), findsNothing);
      expect(find.text('Borrar'), findsNothing);
    });

    testWidgets('long-press with callbacks opens the actions menu', (
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
      await tester.longPress(find.text('Naturaleza'));
      await tester.pumpAndSettle();

      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Borrar'), findsOneWidget);
    });

    testWidgets('renaming updates the strip and keeps the selection', (
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

      await _startRename(tester, 'Naturaleza');
      await tester.enterText(
        find.widgetWithText(TextField, 'Nuevo nombre'),
        'Costa',
      );
      await _confirmInline(tester);

      expect(renamedId, '1');
      expect(renamedName, 'Costa');
      expect(find.text('Costa'), findsOneWidget);
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
      await _startRename(tester, 'Naturaleza');
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
        await _startRename(tester, 'Naturaleza');
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
      await _startRename(tester, 'Naturaleza');
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
      await _startRename(tester, 'Naturaleza');
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
              onDeleteCategory: (id, reassign) async {
                deletedId = id;
                reassignTo = reassign;
              },
            ),
          ),
        );

        await _fillName(tester);
        await _selectCategory(tester, 'Monumento');

        await _startDelete(tester, 'Monumento');

        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
        await tester.pumpAndSettle();

        expect(deletedId, 2);
        expect(reassignTo, isNull);
        // The deleted (selected) category is gone from the strip.
        expect(find.text('Monumento'), findsNothing);
      },
    );

    testWidgets('deleting the selected category disables save', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(form(onDeleteCategory: (_, _) async {})),
      );

      await _fillName(tester);
      await _selectCategory(tester, 'Monumento');
      await _startDelete(tester, 'Monumento');
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
        await _startDelete(tester, 'Naturaleza');

        expect(find.textContaining('tiene 1 lugar'), findsOneWidget);

        final items = tester.widgetList<DropdownMenuItem<Category>>(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(DropdownMenuItem<Category>),
          ),
        );
        expect(items.map((i) => i.value!.id), isNot(contains(1)));
        expect(items.map((i) => i.value!.id), contains(2));

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
      await _startDelete(tester, 'Naturaleza');

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
        await _startDelete(tester, 'Monumento');
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
        await _startDelete(tester, 'Monumento');
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
      await _startDelete(tester, 'Monumento');
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