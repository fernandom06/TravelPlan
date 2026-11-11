import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/category_icon_catalog.dart';
import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/place_api.dart';
import 'package:frontend/presentation/widgets/category_settings_section.dart';

const _playa = Category(id: 1, name: 'Playa');
const _restaurante = Category(id: 2, name: 'Restaurante', icon: 'restaurant');

/// Records the arguments passed to the category callbacks.
class _Record {
  String? createdName;
  String? createdIcon;
  int createCalls = 0;
  String? renamedId;
  String? renamedName;
  String? renamedIcon;
  int renameCalls = 0;
  int? deletedId;
  int? reassignTo;
  int deleteCalls = 0;
}

/// A stateful harness that mirrors how `HomeScreen` wires the settings
/// section to the shared `PlacesController` state.
class _Harness extends StatefulWidget {
  const _Harness({
    required this.record,
    this.categories = const [_playa, _restaurante],
    this.places = const [],
    this.isOnline = true,
    this.createBehavior,
    this.renameBehavior,
    this.deleteBehavior,
  });

  final _Record record;
  final List<Category> categories;
  final List<Place> places;
  final bool isOnline;
  final Future<Category> Function(String name, String? icon)? createBehavior;
  final Future<Category> Function(int id, String name, String? icon)?
  renameBehavior;
  final Future<void> Function(int id, int? reassignTo)? deleteBehavior;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late List<Category> _categories;
  int _nextId = 100;

  @override
  void initState() {
    super.initState();
    _categories = List.of(widget.categories);
  }

  Future<Category> _handleCreate(String name, String? icon) async {
    final record = widget.record;
    record.createdName = name;
    record.createdIcon = icon;
    record.createCalls++;
    final behavior = widget.createBehavior;
    final created = behavior != null
        ? await behavior(name, icon)
        : Category(id: _nextId++, name: name, icon: icon);
    if (!mounted) return created;
    setState(() => _categories = [..._categories, created]);
    return created;
  }

  Future<Category> _handleRename(int id, String name, String? icon) async {
    final record = widget.record;
    record.renamedId = '$id';
    record.renamedName = name;
    record.renamedIcon = icon;
    record.renameCalls++;
    final behavior = widget.renameBehavior;
    final renamed = behavior != null
        ? await behavior(id, name, icon)
        : Category(id: id, name: name, icon: icon);
    if (!mounted) return renamed;
    setState(
      () =>
          _categories = [for (final c in _categories) c.id == id ? renamed : c],
    );
    return renamed;
  }

  Future<void> _handleDelete(int id, int? reassignTo) async {
    final record = widget.record;
    record.deletedId = id;
    record.reassignTo = reassignTo;
    record.deleteCalls++;
    final behavior = widget.deleteBehavior;
    if (behavior != null) {
      await behavior(id, reassignTo);
    }
    if (!mounted) return;
    setState(() => _categories = _categories.where((c) => c.id != id).toList());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CategorySettingsSection(
            categories: _categories,
            places: widget.places,
            isOnline: widget.isOnline,
            onCreate: _handleCreate,
            onRename: _handleRename,
            onDelete: _handleDelete,
          ),
        ),
      ),
    );
  }
}

/// Finds the action button with [tooltip] inside the row of [categoryName].
Finder _rowAction(String categoryName, String tooltip) {
  return find.descendant(
    of: find.widgetWithText(ListTile, categoryName),
    matching: find.byTooltip(tooltip),
  );
}

/// Runs [body] with [platform] forced and restores the override afterwards.
Future<void> _withPlatform(
  TargetPlatform platform,
  Future<void> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  testWidgets('lists each category with its icon and placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(_Harness(record: _Record()));

    expect(find.text('Playa'), findsOneWidget);
    expect(find.text('Restaurante'), findsOneWidget);
    expect(find.byIcon(categoryPlaceholderIcon), findsOneWidget);
    expect(find.byIcon(Icons.restaurant), findsOneWidget);
  });

  testWidgets('long-pressing a row opens the Editar and Borrar actions', (
    tester,
  ) async {
    await tester.pumpWidget(_Harness(record: _Record()));

    await tester.longPress(find.text('Playa'));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Borrar'), findsOneWidget);
  });

  testWidgets('creates a category with an icon from the settings section', (
    tester,
  ) async {
    final record = _Record();
    await tester.pumpWidget(_Harness(record: record));

    await tester.tap(find.text('Añadir categoría'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect(tester.getSize(field).width, greaterThan(150));
    expect(find.byTooltip('Elegir icono'), findsOneWidget);

    await tester.enterText(field, 'Museo');
    await tester.tap(find.byTooltip('Elegir icono'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.museum));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(record.createdName, 'Museo');
    expect(record.createdIcon, 'museum');
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Museo'), findsOneWidget);
  });

  testWidgets('duplicate create shows an inline error and keeps the dialog', (
    tester,
  ) async {
    final record = _Record();
    await tester.pumpWidget(
      _Harness(
        record: record,
        createBehavior: (_, _) async =>
            throw const DuplicateCategoryException('dup'),
      ),
    );

    await tester.tap(find.text('Añadir categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Playa');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Ya existe una categoría con ese nombre'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(record.createCalls, 1);
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets('empty create shows an inline error without calling the api', (
    tester,
  ) async {
    final record = _Record();
    await tester.pumpWidget(_Harness(record: record));

    await tester.tap(find.text('Añadir categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('El nombre no puede estar vacío'), findsOneWidget);
    expect(record.createCalls, 0);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('create api failure shows an inline error', (tester) async {
    final record = _Record();
    await tester.pumpWidget(
      _Harness(
        record: record,
        createBehavior: (_, _) async => throw const PlaceApiException('boom'),
      ),
    );

    await tester.tap(find.text('Añadir categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Museo');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo crear la categoría'), findsOneWidget);
    expect(record.createCalls, 1);
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets('creating offline shows a SnackBar and keeps the dialog open', (
    tester,
  ) async {
    final record = _Record();
    await tester.pumpWidget(_Harness(record: record, isOnline: false));

    await tester.tap(find.text('Añadir categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Museo');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión'), findsOneWidget);
    expect(record.createCalls, 0);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Museo'), findsNothing);
  });

  testWidgets('editing a category renames it and keeps its places', (
    tester,
  ) async {
    final record = _Record();
    const playa = Category(id: 1, name: 'Playa', icon: 'beach');
    const monumento = Category(id: 3, name: 'Monumento', icon: 'monument');
    const places = [
      Place(
        id: 1,
        name: 'A',
        description: null,
        latitude: 1,
        longitude: 1,
        category: playa,
      ),
      Place(
        id: 2,
        name: 'B',
        description: null,
        latitude: 2,
        longitude: 2,
        category: playa,
      ),
    ];
    await tester.pumpWidget(
      _Harness(
        record: record,
        categories: const [playa, monumento],
        places: places,
      ),
    );

    await tester.tap(_rowAction('Playa', 'Editar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Playa'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byIcon(Icons.beach_access),
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'Costa');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(record.renamedId, '1');
    expect(record.renamedName, 'Costa');
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Costa'), findsOneWidget);
    expect(places, hasLength(2));
    expect(places.every((p) => p.category.id == 1), isTrue);
  });

  testWidgets('editing can change the icon without touching the name', (
    tester,
  ) async {
    final record = _Record();
    const playa = Category(id: 1, name: 'Playa', icon: 'beach');
    await tester.pumpWidget(
      _Harness(record: record, categories: const [playa]),
    );

    await tester.tap(_rowAction('Playa', 'Editar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Elegir icono'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.account_balance));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(record.renamedId, '1');
    expect(record.renamedName, 'Playa');
    expect(record.renamedIcon, 'monument');
  });

  testWidgets('"Sin icono" in the rename picker clears the icon', (
    tester,
  ) async {
    final record = _Record();
    const playa = Category(id: 1, name: 'Playa', icon: 'beach');
    await tester.pumpWidget(
      _Harness(record: record, categories: const [playa]),
    );

    await tester.tap(_rowAction('Playa', 'Editar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Elegir icono'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sin icono'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(record.renamedIcon, isNull);
  });

  testWidgets('empty rename shows an inline error without calling the api', (
    tester,
  ) async {
    final record = _Record();
    await tester.pumpWidget(_Harness(record: record));

    await tester.tap(_rowAction('Playa', 'Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('El nombre no puede estar vacío'), findsOneWidget);
    expect(record.renameCalls, 0);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('duplicate rename shows an inline error and keeps the list', (
    tester,
  ) async {
    final record = _Record();
    await tester.pumpWidget(
      _Harness(
        record: record,
        renameBehavior: (_, _, _) async =>
            throw const DuplicateCategoryException('dup'),
      ),
    );

    await tester.tap(_rowAction('Playa', 'Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Restaurante');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Ya existe una categoría con ese nombre'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.widgetWithText(ListTile, 'Playa'), findsOneWidget);
  });

  testWidgets('rename api failure shows an inline error', (tester) async {
    final record = _Record();
    await tester.pumpWidget(
      _Harness(
        record: record,
        renameBehavior: (_, _, _) async =>
            throw const PlaceApiException('boom'),
      ),
    );

    await tester.tap(_rowAction('Playa', 'Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Costa');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo renombrar la categoría'), findsOneWidget);
    expect(record.renameCalls, 1);
  });

  testWidgets('deleting a category with places asks for a destination', (
    tester,
  ) async {
    final record = _Record();
    const playa = Category(id: 3, name: 'Playa');
    const restaurante = Category(
      id: 2,
      name: 'Restaurante',
      icon: 'restaurant',
    );
    const places = [
      Place(
        id: 1,
        name: 'A',
        description: null,
        latitude: 1,
        longitude: 1,
        category: restaurante,
      ),
      Place(
        id: 2,
        name: 'B',
        description: null,
        latitude: 2,
        longitude: 2,
        category: restaurante,
      ),
      Place(
        id: 3,
        name: 'C',
        description: null,
        latitude: 3,
        longitude: 3,
        category: restaurante,
      ),
    ];
    await tester.pumpWidget(
      _Harness(
        record: record,
        categories: const [playa, restaurante],
        places: places,
      ),
    );

    await tester.tap(_rowAction('Restaurante', 'Borrar'));
    await tester.pumpAndSettle();

    expect(
      find.text('La categoría tiene 3 lugar(es). Elige el destino:'),
      findsOneWidget,
    );
    final dropdown = tester.widget<DropdownButtonFormField<Category>>(
      find.byType(DropdownButtonFormField<Category>),
    );
    expect(dropdown.initialValue?.id, 3);
    final items = tester.widgetList<DropdownMenuItem<Category>>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(DropdownMenuItem<Category>),
      ),
    );
    expect(items.map((i) => i.value!.id), isNot(contains(2)));
    expect(items.map((i) => i.value!.id), contains(3));

    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(record.deletedId, 2);
    expect(record.reassignTo, 3);
    expect(find.text('Restaurante'), findsNothing);
    expect(find.text('Playa'), findsOneWidget);
  });

  testWidgets('deleting a category without places asks for confirmation', (
    tester,
  ) async {
    final record = _Record();
    await tester.pumpWidget(_Harness(record: record));

    await tester.tap(_rowAction('Playa', 'Borrar'));
    await tester.pumpAndSettle();

    expect(find.text('Se eliminará "Playa"'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(record.deletedId, 1);
    expect(record.reassignTo, isNull);
    expect(find.text('Playa'), findsNothing);
  });

  testWidgets('the only category with places cannot be deleted', (
    tester,
  ) async {
    final record = _Record();
    const places = [
      Place(
        id: 1,
        name: 'A',
        description: null,
        latitude: 1,
        longitude: 1,
        category: _playa,
      ),
    ];
    await tester.pumpWidget(
      _Harness(record: record, categories: const [_playa], places: places),
    );

    await tester.tap(_rowAction('Playa', 'Borrar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Es la única categoría, crea otra antes de eliminar'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar'),
      ),
      findsNothing,
    );
    expect(record.deleteCalls, 0);
  });

  testWidgets('cancelling the delete dialog does not delete', (tester) async {
    final record = _Record();
    await tester.pumpWidget(_Harness(record: record));

    await tester.tap(_rowAction('Playa', 'Borrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(record.deleteCalls, 0);
    expect(find.text('Playa'), findsOneWidget);
  });

  testWidgets('delete conflict shows the existing SnackBar message', (
    tester,
  ) async {
    final record = _Record();
    await tester.pumpWidget(
      _Harness(
        record: record,
        deleteBehavior: (_, _) async =>
            throw const CategoryNotEmptyException('conflict'),
      ),
    );

    await tester.tap(_rowAction('Playa', 'Borrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudo eliminar: la categoría tiene lugares sin destino'),
      findsOneWidget,
    );
    expect(find.text('Playa'), findsOneWidget);
  });

  testWidgets('invalid reassign target shows the existing SnackBar message', (
    tester,
  ) async {
    final record = _Record();
    await tester.pumpWidget(
      _Harness(
        record: record,
        deleteBehavior: (_, _) async =>
            throw const InvalidReassignTargetException('invalid'),
      ),
    );

    await tester.tap(_rowAction('Playa', 'Borrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('El destino no es válido'), findsOneWidget);
    expect(find.text('Playa'), findsOneWidget);
  });

  testWidgets('generic delete failure shows the existing SnackBar message', (
    tester,
  ) async {
    final record = _Record();
    await tester.pumpWidget(
      _Harness(
        record: record,
        deleteBehavior: (_, _) async => throw Exception('boom'),
      ),
    );

    await tester.tap(_rowAction('Playa', 'Borrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo eliminar la categoría'), findsOneWidget);
    expect(find.text('Playa'), findsOneWidget);
  });

  testWidgets('deleting offline shows a SnackBar and keeps the row', (
    tester,
  ) async {
    final record = _Record();
    await tester.pumpWidget(_Harness(record: record, isOnline: false));

    await tester.tap(_rowAction('Playa', 'Borrar'));
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión'), findsOneWidget);
    expect(record.deleteCalls, 0);
    expect(find.text('Playa'), findsOneWidget);
  });

  testWidgets(
    'desktop rows show the edit and delete actions without hovering',
    (tester) async {
      await _withPlatform(TargetPlatform.macOS, () async {
        await tester.pumpWidget(_Harness(record: _Record()));

        expect(find.byTooltip('Editar'), findsNWidgets(2));
        expect(find.byTooltip('Borrar'), findsNWidgets(2));
        expect(_rowAction('Playa', 'Editar'), findsOneWidget);
        expect(_rowAction('Playa', 'Borrar'), findsOneWidget);
        expect(_rowAction('Restaurante', 'Editar'), findsOneWidget);
        expect(_rowAction('Restaurante', 'Borrar'), findsOneWidget);
        expect(find.byIcon(Icons.more_vert), findsNothing);
        expect(find.text('Borrar'), findsNothing);
      });
    },
  );

  testWidgets('desktop rows keep the actions visible in a narrow window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _withPlatform(TargetPlatform.macOS, () async {
      await tester.pumpWidget(_Harness(record: _Record()));

      expect(find.byTooltip('Editar'), findsNWidgets(2));
      expect(find.byTooltip('Borrar'), findsNWidgets(2));
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(find.text('Borrar'), findsNothing);
    });
  });

  testWidgets('touch rows show the edit and delete actions without a gesture', (
    tester,
  ) async {
    await _withPlatform(TargetPlatform.android, () async {
      await tester.pumpWidget(_Harness(record: _Record()));

      expect(find.byTooltip('Editar'), findsNWidgets(2));
      expect(find.byTooltip('Borrar'), findsNWidgets(2));
      expect(_rowAction('Playa', 'Editar'), findsOneWidget);
      expect(_rowAction('Playa', 'Borrar'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(find.text('Borrar'), findsNothing);
    });
  });

  testWidgets('long-pressing a touch row still deletes through the menu', (
    tester,
  ) async {
    await _withPlatform(TargetPlatform.android, () async {
      final record = _Record();

      await tester.pumpWidget(_Harness(record: record));

      await tester.longPress(find.text('Playa'));
      await tester.pumpAndSettle();

      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Borrar'), findsOneWidget);

      await tester.tap(find.text('Borrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(record.deletedId, 1);
      expect(find.text('Playa'), findsNothing);
    });
  });

  testWidgets('tapping the edit action renames the category', (tester) async {
    await _withPlatform(TargetPlatform.macOS, () async {
      final record = _Record();

      await tester.pumpWidget(_Harness(record: record));

      await tester.tap(_rowAction('Playa', 'Editar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Calas');
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(record.renamedName, 'Calas');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Calas'), findsOneWidget);
      expect(find.text('Playa'), findsNothing);
    });
  });

  testWidgets('renaming to an existing name keeps the dialog and the list', (
    tester,
  ) async {
    await _withPlatform(TargetPlatform.macOS, () async {
      final record = _Record();

      await tester.pumpWidget(
        _Harness(
          record: record,
          renameBehavior: (_, _, _) async =>
              throw const DuplicateCategoryException('dup'),
        ),
      );

      await tester.tap(_rowAction('Playa', 'Editar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Restaurante');
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ya existe una categoría con ese nombre'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Playa'), findsOneWidget);
    });
  });

  testWidgets('editing offline shows a SnackBar without opening the dialog', (
    tester,
  ) async {
    await _withPlatform(TargetPlatform.macOS, () async {
      await tester.pumpWidget(_Harness(record: _Record(), isOnline: false));

      await tester.tap(_rowAction('Playa', 'Editar'));
      await tester.pumpAndSettle();

      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  testWidgets('a very long category name does not break the row', (
    tester,
  ) async {
    final longName = List.filled(24, 'Costa').join();

    await _withPlatform(TargetPlatform.macOS, () async {
      await tester.pumpWidget(
        _Harness(
          record: _Record(),
          categories: [Category(id: 1, name: longName)],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(longName), findsOneWidget);
      expect(find.byTooltip('Editar'), findsOneWidget);
      expect(find.byTooltip('Borrar'), findsOneWidget);

      await tester.ensureVisible(find.byTooltip('Editar'));
      await tester.ensureVisible(find.byTooltip('Borrar'));
    });
  });
}
