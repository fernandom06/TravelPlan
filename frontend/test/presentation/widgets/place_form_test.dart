import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
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

FilledButton _saveButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.widgetWithText(FilledButton, 'Guardar Lugar'),
);

Future<void> _fillName(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'Mirador');
  await tester.pump();
}

Future<void> _selectCategory(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

/// Hosts a [PlaceForm] whose category list can be swapped at runtime, mirroring
/// how the map rebuilds the form from the shared controller state.
class _FormHarness extends StatefulWidget {
  const _FormHarness({
    super.key,
    required this.categories,
    required this.onSave,
  });

  final List<Category> categories;
  final void Function(String name, int categoryId, String? description) onSave;

  @override
  State<_FormHarness> createState() => _FormHarnessState();
}

class _FormHarnessState extends State<_FormHarness> {
  late List<Category> _categories;

  @override
  void initState() {
    super.initState();
    _categories = widget.categories;
  }

  void setCategories(List<Category> categories) {
    setState(() => _categories = categories);
  }

  @override
  Widget build(BuildContext context) {
    return _wrap(
      PlaceForm(
        categories: _categories,
        onSave: widget.onSave,
        onCancel: () {},
      ),
    );
  }
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
        PlaceDetails(categories: _categories, place: _place, onClose: () {}),
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

    final chipFocus = Focus.maybeOf(tester.element(find.text('Naturaleza')));
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
        ),
      ),
    );
    await tester.pump();

    // 1: Nombre -> first chip (Naturaleza).
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(
      Focus.maybeOf(tester.element(find.text('Naturaleza')))!.hasPrimaryFocus,
      isTrue,
    );

    // 2: Naturaleza -> Monumento.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(
      Focus.maybeOf(tester.element(find.text('Monumento')))!.hasPrimaryFocus,
      isTrue,
    );

    // 3: Monumento -> Descripcion.
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
        ),
      ),
    );
    await tester.pump();

    // Reach Descripcion via the tab sequence (Nombre -> 2 chips -> Descripcion).
    for (var i = 0; i < 3; i++) {
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

    // Focus returned to the last focusable chip.
    expect(
      Focus.maybeOf(tester.element(find.text('Monumento')))!.hasPrimaryFocus,
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
        ),
      ),
    );
    await tester.pump();

    // Name is empty so Guardar is disabled.
    expect(_saveButton(tester).onPressed, isNull);

    // Reach Descripcion: Nombre -> 2 chips -> Descripcion.
    for (var i = 0; i < 3; i++) {
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

    final chipFocus = Focus.maybeOf(tester.element(find.text('Naturaleza')));
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

  testWidgets('read-only mode disables fields and shows Cerrar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PlaceDetails(categories: _categories, place: _place, onClose: () {}),
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
        PlaceDetails(categories: _categories, place: _place, onClose: () {}),
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

  testWidgets('category chips are a pure selector in the place form', (
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

    expect(find.byIcon(Icons.add), findsNothing);

    await tester.longPress(find.text('Naturaleza'));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsNothing);
    expect(find.text('Borrar'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('keeps the selection when the category is renamed upstream', (
    tester,
  ) async {
    int? savedCategoryId;
    final key = GlobalKey<_FormHarnessState>();
    await tester.pumpWidget(
      _FormHarness(
        key: key,
        categories: const [
          Category(id: 1, name: 'Playa'),
          Category(id: 2, name: 'Monumento'),
        ],
        onSave: (name, categoryId, description) => savedCategoryId = categoryId,
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Mirador');
    await tester.pump();
    await _selectCategory(tester, 'Playa');

    key.currentState!.setCategories(const [
      Category(id: 1, name: 'Costa'),
      Category(id: 2, name: 'Monumento'),
    ]);
    await tester.pump();

    expect(find.text('Costa'), findsOneWidget);
    expect(find.text('Playa'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Guardar Lugar'));
    await tester.pump();

    expect(savedCategoryId, 1);
  });

  testWidgets('clears the selection when the category is deleted upstream', (
    tester,
  ) async {
    final key = GlobalKey<_FormHarnessState>();
    await tester.pumpWidget(
      _FormHarness(key: key, categories: _categories, onSave: (_, _, _) {}),
    );

    await _fillName(tester);
    await _selectCategory(tester, 'Monumento');

    key.currentState!.setCategories(const [_naturaleza]);
    await tester.pump();

    expect(find.text('Monumento'), findsNothing);
    expect(_saveButton(tester).onPressed, isNull);
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
