import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/category_icon_catalog.dart';
import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/place_api.dart';
import 'package:frontend/presentation/widgets/category_chip_strip.dart';

const _naturaleza = Category(id: 1, name: 'Naturaleza');
const _monumento = Category(id: 2, name: 'Monumento');

const _place = Place(
  id: 1,
  name: 'Mirador',
  description: null,
  latitude: 42.5,
  longitude: -3.1,
  category: _naturaleza,
);

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

/// Records the arguments passed to the category callbacks.
class _Record {
  String? renamedId;
  String? renamedName;
  String? renamedIcon;
  int? deletedId;
  int? reassignTo;
  String? createdName;
  String? createdIcon;
  int createCalls = 0;
  int renameCalls = 0;
  int deleteCalls = 0;
  Category? lastChanged;
}

/// A stateful harness that mirrors how `PlaceForm` keeps its category list and
/// selected value in sync with the strip's notifications.
class _Harness extends StatefulWidget {
  const _Harness({
    required this.categories,
    this.value,
    this.onCreate,
    this.onRename,
    this.onDelete,
    this.places = const [],
    this.record,
    this.width,
  });

  final List<Category> categories;
  final Category? value;
  final Future<Category> Function(String name, String? icon)? onCreate;
  final Future<Category> Function(int id, String name, String? icon)? onRename;
  final Future<void> Function(int id, int? reassignTo)? onDelete;
  final List<Place> places;
  final _Record? record;
  final double? width;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late List<Category> _categories;
  Category? _value;

  @override
  void initState() {
    super.initState();
    _categories = List.of(widget.categories);
    _value = widget.value;
  }

  void _handleChanged(Category? c) {
    setState(() => _value = c);
    widget.record?.lastChanged = c;
  }

  void _handleAdded(Category c) {
    setState(() => _categories = [..._categories, c]);
  }

  void _handleRenamed(Category c) {
    setState(() {
      _categories = [for (final x in _categories) x.id == c.id ? c : x];
      if (_value?.id == c.id) _value = c;
    });
  }

  void _handleDeleted(int id) {
    setState(() {
      _categories = _categories.where((x) => x.id != id).toList();
      if (_value?.id == id) _value = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strip = CategoryChipStrip(
      categories: _categories,
      value: _value,
      onChanged: _handleChanged,
      onCreate: widget.onCreate,
      onRename: widget.onRename,
      onDelete: widget.onDelete,
      places: widget.places,
      onCategoryAdded: _handleAdded,
      onCategoryRenamed: _handleRenamed,
      onCategoryDeleted: _handleDeleted,
    );
    if (widget.width != null) {
      return _wrap(SizedBox(width: widget.width, child: strip));
    }
    return _wrap(strip);
  }
}

Future<void> _openMenuOn(WidgetTester tester, String name) async {
  await tester.longPress(find.text(name));
  await tester.pumpAndSettle();
}

Future<void> _startRename(WidgetTester tester, String name) async {
  await _openMenuOn(tester, name);
  await tester.tap(find.text('Editar'));
  await tester.pumpAndSettle();
}

Future<void> _startDelete(WidgetTester tester, String name) async {
  await _openMenuOn(tester, name);
  await tester.tap(find.text('Borrar'));
  await tester.pumpAndSettle();
}

Future<void> _startCreate(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
}

Future<void> _confirm(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.check));
  await tester.pumpAndSettle();
}

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

  testWidgets('empty categories still renders the add chip', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CategoryChipStrip(
          categories: [],
          onChanged: (_) {},
          onCreate: (_, _) async => _naturaleza,
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('Naturaleza'), findsNothing);
  });

  group('inline create', () {
    testWidgets('add chip focuses the name input', (tester) async {
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          onCreate: (_, _) async => const Category(id: 5, name: 'Playa'),
        ),
      );

      await _startCreate(tester);

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.hasAnyClients, isTrue);
    });

    testWidgets('confirm via check adds category and autoselects', (
      tester,
    ) async {
      final record = _Record();
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          record: record,
          onCreate: (name, icon) async {
            record.createdName = name;
            record.createdIcon = icon;
            record.createCalls++;
            return const Category(id: 5, name: 'Playa');
          },
        ),
      );

      await _startCreate(tester);
      await tester.enterText(find.byType(TextField), 'Playa');
      await _confirm(tester);

      expect(record.createdName, 'Playa');
      expect(record.createCalls, 1);
      expect(record.lastChanged, const Category(id: 5, name: 'Playa'));
      // Autoselected: the chip appears with the new name.
      expect(find.text('Playa'), findsOneWidget);
    });

    testWidgets('confirm via Enter key', (tester) async {
      final record = _Record();
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          record: record,
          onCreate: (name, icon) async {
            record.createdName = name;
            return const Category(id: 5, name: 'Playa');
          },
        ),
      );

      await _startCreate(tester);
      await tester.enterText(find.byType(TextField), 'Playa');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(record.createdName, 'Playa');
      expect(record.lastChanged, const Category(id: 5, name: 'Playa'));
    });

    testWidgets('cancel via X discards', (tester) async {
      final record = _Record();
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          record: record,
          onCreate: (name, icon) async {
            record.createCalls++;
            return const Category(id: 5, name: 'Playa');
          },
        ),
      );

      await _startCreate(tester);
      await tester.enterText(find.byType(TextField), 'Playa');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(record.createCalls, 0);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Playa'), findsNothing);
    });

    testWidgets('cancel via Escape key', (tester) async {
      final record = _Record();
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          record: record,
          onCreate: (name, icon) async {
            record.createCalls++;
            return const Category(id: 5, name: 'Playa');
          },
        ),
      );

      await _startCreate(tester);
      await tester.enterText(find.byType(TextField), 'Playa');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(record.createCalls, 0);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('create duplicate shows inline error and stays editing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          onCreate: (_, _) async =>
              throw const DuplicateCategoryException('dup'),
        ),
      );

      await _startCreate(tester);
      await tester.enterText(find.byType(TextField), 'Playa');
      await _confirm(tester);

      expect(
        find.text('Ya existe una categoría con ese nombre'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('create empty name shows inline error and no callback', (
      tester,
    ) async {
      final record = _Record();
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          record: record,
          onCreate: (_, _) async => const Category(id: 5, name: 'Playa'),
        ),
      );

      await _startCreate(tester);
      await tester.enterText(find.byType(TextField), '   ');
      await _confirm(tester);

      expect(find.text('El nombre no puede estar vacío'), findsOneWidget);
      expect(record.createCalls, 0);
    });

    testWidgets('create network error shows inline error', (tester) async {
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          onCreate: (_, _) async => throw const PlaceApiException('boom'),
        ),
      );

      await _startCreate(tester);
      await tester.enterText(find.byType(TextField), 'Playa');
      await _confirm(tester);

      expect(find.text('No se pudo crear la categoría'), findsOneWidget);
    });

    testWidgets('double confirm does not call onCreate twice', (tester) async {
      final record = _Record();
      final completer = Completer<Category>();
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          record: record,
          onCreate: (_, _) {
            record.createCalls++;
            return completer.future;
          },
        ),
      );

      await _startCreate(tester);
      await tester.enterText(find.byType(TextField), 'Playa');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.check), warnIfMissed: false);
      await tester.pump();

      expect(record.createCalls, 1);

      completer.complete(const Category(id: 5, name: 'Playa'));
      await tester.pumpAndSettle();
      expect(record.createCalls, 1);
    });
  });

  group('inline rename', () {
    testWidgets('menu Editar opens a prefilled editor and confirms', (
      tester,
    ) async {
      final record = _Record();
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza, _monumento],
          value: _naturaleza,
          record: record,
          onRename: (id, name, icon) async {
            record.renamedId = '$id';
            record.renamedName = name;
            record.renamedIcon = icon;
            return const Category(id: 1, name: 'Costa');
          },
        ),
      );

      await _startRename(tester, 'Naturaleza');

      final field = find.widgetWithText(TextField, 'Naturaleza');
      expect(field, findsOneWidget);
      await tester.enterText(field, 'Costa');
      await _confirm(tester);

      expect(record.renamedId, '1');
      expect(record.renamedName, 'Costa');
      expect(record.lastChanged, const Category(id: 1, name: 'Costa'));
      expect(find.text('Costa'), findsOneWidget);
    });

    testWidgets('confirm via Enter key', (tester) async {
      final record = _Record();
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          value: _naturaleza,
          record: record,
          onRename: (id, name, icon) async {
            record.renamedId = '$id';
            record.renamedName = name;
            return const Category(id: 1, name: 'Costa');
          },
        ),
      );

      await _startRename(tester, 'Naturaleza');
      await tester.enterText(find.byType(TextField), 'Costa');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(record.renamedId, '1');
      expect(record.renamedName, 'Costa');
    });

    testWidgets('cancel via X discards and reverts', (tester) async {
      final record = _Record();
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          value: _naturaleza,
          record: record,
          onRename: (_, _, _) async {
            record.renameCalls++;
            return _naturaleza;
          },
        ),
      );

      await _startRename(tester, 'Naturaleza');
      await tester.enterText(find.byType(TextField), 'Costa');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(record.renameCalls, 0);
      expect(find.text('Naturaleza'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('cancel via Escape key', (tester) async {
      final record = _Record();
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          value: _naturaleza,
          record: record,
          onRename: (_, _, _) async {
            record.renameCalls++;
            return _naturaleza;
          },
        ),
      );

      await _startRename(tester, 'Naturaleza');
      await tester.enterText(find.byType(TextField), 'Costa');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(record.renameCalls, 0);
      expect(find.text('Naturaleza'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('rename to duplicate shows inline error', (tester) async {
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza, _monumento],
          value: _naturaleza,
          onRename: (_, _, _) async =>
              throw const DuplicateCategoryException('dup'),
        ),
      );

      await _startRename(tester, 'Naturaleza');
      await tester.enterText(find.byType(TextField), 'Monumento');
      await _confirm(tester);

      expect(
        find.text('Ya existe una categoría con ese nombre'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('rename to empty shows inline error and no callback', (
      tester,
    ) async {
      final record = _Record();
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          value: _naturaleza,
          record: record,
          onRename: (_, _, _) async {
            record.renameCalls++;
            return _naturaleza;
          },
        ),
      );

      await _startRename(tester, 'Naturaleza');
      await tester.enterText(find.byType(TextField), '   ');
      await _confirm(tester);

      expect(find.text('El nombre no puede estar vacío'), findsOneWidget);
      expect(record.renameCalls, 0);
    });

    testWidgets('rename network error shows inline error', (tester) async {
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          value: _naturaleza,
          onRename: (_, _, _) async => throw const PlaceApiException('boom'),
        ),
      );

      await _startRename(tester, 'Naturaleza');
      await tester.enterText(find.byType(TextField), 'Costa');
      await _confirm(tester);

      expect(find.text('No se pudo renombrar la categoría'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('delete', () {
    testWidgets(
      'delete category without places confirms, removes it and clears selection',
      (tester) async {
        final record = _Record();
        await tester.pumpWidget(
          _Harness(
            categories: [_naturaleza, _monumento],
            value: _monumento,
            record: record,
            onDelete: (id, reassign) async {
              record.deletedId = id;
              record.reassignTo = reassign;
              record.deleteCalls++;
            },
          ),
        );

        await _startDelete(tester, 'Monumento');

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Eliminar categoría'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
        await tester.pumpAndSettle();

        expect(record.deletedId, 2);
        expect(record.reassignTo, isNull);
        expect(record.lastChanged, isNull);
        expect(find.text('Monumento'), findsNothing);
      },
    );

    testWidgets(
      'delete category with places shows count and destination dropdown',
      (tester) async {
        final record = _Record();
        await tester.pumpWidget(
          _Harness(
            categories: [_naturaleza, _monumento],
            value: _naturaleza,
            places: [_place],
            record: record,
            onDelete: (id, reassign) async {
              record.deletedId = id;
              record.reassignTo = reassign;
            },
          ),
        );

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

        expect(record.deletedId, 1);
        expect(record.reassignTo, 2);
        expect(record.lastChanged, isNull);
      },
    );

    testWidgets('delete the only category with places is blocked', (
      tester,
    ) async {
      final record = _Record();
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          value: _naturaleza,
          places: [_place],
          record: record,
          onDelete: (_, _) async {
            record.deleteCalls++;
          },
        ),
      );

      await _startDelete(tester, 'Naturaleza');

      expect(find.textContaining('única categoría'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Eliminar'),
        ),
        findsNothing,
      );
      expect(record.deleteCalls, 0);
    });

    testWidgets('delete fails with CategoryNotEmptyException shows SnackBar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza, _monumento],
          value: _monumento,
          onDelete: (_, _) async =>
              throw const CategoryNotEmptyException('conflict'),
        ),
      );

      await _startDelete(tester, 'Monumento');
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('lugares sin destino'), findsOneWidget);
    });

    testWidgets(
      'delete fails with InvalidReassignTargetException shows SnackBar',
      (tester) async {
        await tester.pumpWidget(
          _Harness(
            categories: [_naturaleza, _monumento],
            value: _monumento,
            onDelete: (_, _) async =>
                throw const InvalidReassignTargetException('invalid'),
          ),
        );

        await _startDelete(tester, 'Monumento');
        await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
        await tester.pumpAndSettle();

        expect(find.text('El destino no es válido'), findsOneWidget);
      },
    );

    testWidgets('delete fails with generic error shows SnackBar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza, _monumento],
          value: _monumento,
          onDelete: (_, _) async => throw Exception('boom'),
        ),
      );

      await _startDelete(tester, 'Monumento');
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo eliminar la categoría'), findsOneWidget);
    });
  });

  group('icon pick', () {
    testWidgets('creating a category with an icon passes it to onCreate', (
      tester,
    ) async {
      final record = _Record();
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          record: record,
          onCreate: (name, icon) async {
            record.createdName = name;
            record.createdIcon = icon;
            return const Category(id: 5, name: 'Playa', icon: 'beach');
          },
        ),
      );

      await _startCreate(tester);
      await tester.enterText(find.byType(TextField), 'Playa');

      await tester.tap(find.byTooltip('Elegir icono'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.beach_access));
      await tester.pumpAndSettle();

      await _confirm(tester);

      expect(record.createdName, 'Playa');
      expect(record.createdIcon, 'beach');
    });

    testWidgets('editing a category preloads its icon and can change it', (
      tester,
    ) async {
      final record = _Record();
      const beach = Category(id: 1, name: 'Playa', icon: 'beach');
      await tester.pumpWidget(
        _Harness(
          categories: [beach],
          value: beach,
          record: record,
          onRename: (id, name, icon) async {
            record.renamedId = '$id';
            record.renamedName = name;
            record.renamedIcon = icon;
            return Category(id: 1, name: name, icon: icon);
          },
        ),
      );

      await _startRename(tester, 'Playa');
      await tester.tap(find.byTooltip('Elegir icono'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.account_balance));
      await tester.pumpAndSettle();

      await _confirm(tester);

      expect(record.renamedId, '1');
      expect(record.renamedName, 'Playa');
      expect(record.renamedIcon, 'monument');
    });

    testWidgets('"Sin icono" in the picker clears the icon', (tester) async {
      final record = _Record();
      const beach = Category(id: 1, name: 'Playa', icon: 'beach');
      await tester.pumpWidget(
        _Harness(
          categories: [beach],
          value: beach,
          record: record,
          onRename: (id, name, icon) async {
            record.renamedName = name;
            record.renamedIcon = icon;
            return Category(id: 1, name: name, icon: icon);
          },
        ),
      );

      await _startRename(tester, 'Playa');
      await tester.tap(find.byTooltip('Elegir icono'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sin icono'));
      await tester.pumpAndSettle();

      await _confirm(tester);

      expect(record.renamedIcon, isNull);
    });
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
        _Harness(
          categories: manyCategories(),
          value: const Category(id: 0, name: 'Categoría 0'),
          width: 300,
        ),
      );

      final scrollable = stripScrollable();
      expect(scrollable, findsOneWidget);
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('chips outside the initial viewport are manageable after '
        'scrolling and the editor is scrolled into view', (tester) async {
      final record = _Record();
      await tester.pumpWidget(
        _Harness(
          categories: manyCategories(),
          record: record,
          width: 300,
          onRename: (id, name, icon) async =>
              Category(id: id, name: name, icon: icon),
        ),
      );

      // The last chip starts off-screen (clipped beyond the viewport).
      final viewport = tester.getRect(stripScrollable());
      expect(
        tester.getRect(find.text('Categoría 11')).right,
        greaterThan(viewport.right),
      );

      await tester.scrollUntilVisible(
        find.text('Categoría 11'),
        200,
        scrollable: stripScrollable(),
      );
      await tester.pumpAndSettle();

      // Now it is visible and can be managed.
      expect(find.text('Categoría 11'), findsOneWidget);
      await _startRename(tester, 'Categoría 11');

      expect(find.byType(TextField), findsOneWidget);
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
      // The editor was scrolled into the viewport.
      final editorRect = tester.getRect(find.byType(TextField));
      final newViewport = tester.getRect(stripScrollable());
      expect(editorRect.left, lessThan(newViewport.right));
      expect(editorRect.right, greaterThan(newViewport.left));
    });
  });
}
