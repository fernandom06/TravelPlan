import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/category_icon_catalog.dart';
import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/place_api.dart';
import 'package:frontend/presentation/widgets/category_dropdown.dart';

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
/// selected value in sync with the dropdown's notifications.
class _Harness extends StatefulWidget {
  const _Harness({
    required this.categories,
    this.value,
    this.onCreate,
    this.onRename,
    this.onDelete,
    this.places = const [],
    this.record,
  });

  final List<Category> categories;
  final Category? value;
  final Future<Category> Function(String name, String? icon)? onCreate;
  final Future<Category> Function(int id, String name, String? icon)? onRename;
  final Future<void> Function(int id, int? reassignTo)? onDelete;
  final List<Place> places;
  final _Record? record;

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
    return _wrap(
      CategoryDropdown(
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
      ),
    );
  }
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byType(InputDecorator));
  await tester.pumpAndSettle();
}

Future<void> _startRename(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.edit).first);
  await tester.pumpAndSettle();
}

Future<void> _startCreate(WidgetTester tester) async {
  await tester.tap(find.text('Nueva categoría'));
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

void main() {
  testWidgets('renders the field with label Categoría', (tester) async {
    await tester.pumpWidget(
      _wrap(CategoryDropdown(categories: [_naturaleza], onChanged: (_) {})),
    );

    expect(find.text('Categoría'), findsOneWidget);
  });

  testWidgets('tap opens the menu showing the category names', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CategoryDropdown(
          categories: [_naturaleza, _monumento],
          onChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();

    expect(find.text('Naturaleza'), findsOneWidget);
    expect(find.text('Monumento'), findsOneWidget);
  });

  testWidgets('tap outside closes the menu', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CategoryDropdown(
          categories: [_naturaleza, _monumento],
          onChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    expect(find.text('Naturaleza'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Naturaleza'), findsNothing);
  });

  testWidgets(
    'renders disabled field with selected name and does not open on tap',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          CategoryDropdown(
            categories: [_naturaleza, _monumento],
            value: _naturaleza,
            enabled: false,
            onChanged: (_) {},
          ),
        ),
      );

      // The selected name is shown.
      expect(find.text('Naturaleza'), findsOneWidget);

      await tester.tap(find.text('Naturaleza'));
      await tester.pumpAndSettle();

      // The menu does not open: no unselected row appears.
      expect(find.text('Monumento'), findsNothing);
    },
  );

  testWidgets('tapping a category selects it and closes the menu', (
    tester,
  ) async {
    Category? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Center(
                child: CategoryDropdown(
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

    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monumento'));
    await tester.pumpAndSettle();

    expect(selected, _monumento);
    // The trigger now shows the selected name and the menu is closed.
    expect(find.text('Monumento'), findsOneWidget);
    // No other rows remain visible once closed.
    expect(find.text('Naturaleza'), findsNothing);
  });

  testWidgets('empty categories list still opens without crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(CategoryDropdown(categories: [], onChanged: (_) {})),
    );

    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();

    // No category rows are shown.
    expect(find.text('Naturaleza'), findsNothing);
    expect(find.text('Monumento'), findsNothing);
  });

  testWidgets(
    'edit/delete icons appear per row only when callbacks present and enabled',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          CategoryDropdown(
            categories: [_naturaleza, _monumento],
            onChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(InputDecorator));
      await tester.pumpAndSettle();
      // No callbacks → no icons.
      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    },
  );

  testWidgets('edit/delete icons appear when callbacks are present', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        CategoryDropdown(
          categories: [_naturaleza, _monumento],
          onChanged: (_) {},
          onCreate: (_, _) async => _naturaleza,
          onRename: (_, _, _) async => _naturaleza,
          onDelete: (_, _) async {},
        ),
      ),
    );

    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    // One edit + one delete per row (2 rows).
    expect(find.byIcon(Icons.edit), findsNWidgets(2));
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
  });

  testWidgets('edit/delete icons do not appear when disabled', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CategoryDropdown(
          categories: [_naturaleza],
          value: _naturaleza,
          enabled: false,
          onChanged: (_) {},
          onCreate: (_, _) async => _naturaleza,
          onRename: (_, _, _) async => _naturaleza,
          onDelete: (_, _) async {},
        ),
      ),
    );

    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('create affordance appears inside the open menu', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CategoryDropdown(
          categories: [_naturaleza],
          onChanged: (_) {},
          onCreate: (_, _) async => _naturaleza,
        ),
      ),
    );

    // Closed menu: no affordance.
    expect(find.text('Nueva categoría'), findsNothing);

    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    expect(find.text('Nueva categoría'), findsOneWidget);
  });

  testWidgets('create affordance hidden when onCreate is null or disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(CategoryDropdown(categories: [_naturaleza], onChanged: (_) {})),
    );

    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    expect(find.text('Nueva categoría'), findsNothing);
  });

  testWidgets(
    'menu panel stays within the screen when trigger is near the edge',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 220,
                child: CategoryDropdown(
                  categories: [_naturaleza],
                  value: _naturaleza,
                  onChanged: (_) {},
                  onRename: (_, _, _) async => _naturaleza,
                  onDelete: (_, _) async {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InputDecorator));
      await tester.pumpAndSettle();

      final screenWidth = tester.getSize(find.byType(MaterialApp)).width;
      // The edit/delete action icons must be hit-testable (on screen), not
      // pushed off the right edge by the expanding menu rows.
      for (final icon in [Icons.edit, Icons.delete_outline]) {
        final rect = tester.getRect(find.byIcon(icon).first);
        expect(rect.right, lessThanOrEqualTo(screenWidth));
      }
    },
  );

  group('rename inline', () {
    testWidgets('confirm via check icon updates list and keeps selection', (
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

      await _openMenu(tester);
      await _startRename(tester);

      // The TextField is pre-filled with the current name.
      final field = find.widgetWithText(TextField, 'Naturaleza');
      expect(field, findsOneWidget);
      await tester.enterText(field, 'Costa');

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(record.renamedId, '1');
      expect(record.renamedName, 'Costa');
      expect(record.lastChanged, const Category(id: 1, name: 'Costa'));
      // The trigger and the row now show the new name; the menu stays open.
      expect(find.text('Costa'), findsNWidgets(2));
      expect(find.text('Nueva categoría'), findsNothing);
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
            record.renamedIcon = icon;
            return const Category(id: 1, name: 'Costa');
          },
        ),
      );

      await _openMenu(tester);
      await _startRename(tester);
      await tester.enterText(find.byType(TextField), 'Costa');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(record.renamedId, '1');
      expect(record.renamedName, 'Costa');
      // Trigger and row show the new name; menu stays open.
      expect(find.text('Costa'), findsNWidgets(2));
    });

    testWidgets('cancel via X icon discards and reverts row', (tester) async {
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

      await _openMenu(tester);
      await _startRename(tester);
      await tester.enterText(find.byType(TextField), 'Costa');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(record.renameCalls, 0);
      // The row reverts to the original name; the menu stays open, so the
      // name appears in both the trigger and the row.
      expect(find.text('Naturaleza'), findsNWidgets(2));
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

      await _openMenu(tester);
      await _startRename(tester);
      await tester.enterText(find.byType(TextField), 'Costa');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(record.renameCalls, 0);
      expect(find.text('Naturaleza'), findsNWidgets(2));
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('rename to duplicate shows inline error and keeps menu open', (
      tester,
    ) async {
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza, _monumento],
          value: _naturaleza,
          onCreate: (_, _) async => _naturaleza,
          onRename: (_, _, _) async =>
              throw const DuplicateCategoryException('dup'),
        ),
      );

      await _openMenu(tester);
      await _startRename(tester);
      await tester.enterText(find.byType(TextField), 'Monumento');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(
        find.text('Ya existe una categoría con ese nombre'),
        findsOneWidget,
      );
      // Menu still open and row still editable.
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Nueva categoría'), findsOneWidget);
    });

    testWidgets(
      'rename to empty shows inline error and does not call callback',
      (tester) async {
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

        await _openMenu(tester);
        await _startRename(tester);
        await tester.enterText(find.byType(TextField), '   ');
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();

        expect(find.text('El nombre no puede estar vacío'), findsOneWidget);
        expect(record.renameCalls, 0);
        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets('rename network error shows inline error', (tester) async {
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          value: _naturaleza,
          onRename: (_, _, _) async => throw const PlaceApiException('boom'),
        ),
      );

      await _openMenu(tester);
      await _startRename(tester);
      await tester.enterText(find.byType(TextField), 'Costa');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo renombrar la categoría'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('double confirm does not call onRename twice', (tester) async {
      final record = _Record();
      final completer = Completer<Category>();
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          value: _naturaleza,
          record: record,
          onRename: (_, _, _) {
            record.renameCalls++;
            return completer.future;
          },
        ),
      );

      await _openMenu(tester);
      await _startRename(tester);
      await tester.enterText(find.byType(TextField), 'Costa');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.check), warnIfMissed: false);
      await tester.pump();

      expect(record.renameCalls, 1);

      completer.complete(const Category(id: 1, name: 'Costa'));
      await tester.pumpAndSettle();
      expect(record.renameCalls, 1);
    });
  });

  group('create inline', () {
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

      await _openMenu(tester);
      await _startCreate(tester);

      // Empty TextField is focused.
      final field = find.byType(TextField);
      expect(field, findsOneWidget);
      await tester.enterText(field, 'Playa');

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(record.createdName, 'Playa');
      expect(record.createCalls, 1);
      expect(record.lastChanged, const Category(id: 5, name: 'Playa'));
      // Autoselected: the trigger shows 'Playa'; menu stays open with the row.
      expect(find.text('Playa'), findsNWidgets(2));
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

      await _openMenu(tester);
      await _startCreate(tester);
      await tester.enterText(find.byType(TextField), 'Playa');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(record.createdName, 'Playa');
      expect(record.lastChanged, const Category(id: 5, name: 'Playa'));
      expect(find.text('Playa'), findsNWidgets(2));
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

      await _openMenu(tester);
      await _startCreate(tester);
      await tester.enterText(find.byType(TextField), 'Playa');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(record.createCalls, 0);
      expect(find.byType(TextField), findsNothing);
      // No 'Playa' row appears and nothing is selected.
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

      await _openMenu(tester);
      await _startCreate(tester);
      await tester.enterText(find.byType(TextField), 'Playa');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(record.createCalls, 0);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Playa'), findsNothing);
    });

    testWidgets('create duplicate shows inline error and keeps menu open', (
      tester,
    ) async {
      final record = _Record();
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          record: record,
          onCreate: (name, icon) async {
            record.createCalls++;
            throw const DuplicateCategoryException('dup');
          },
        ),
      );

      await _openMenu(tester);
      await _startCreate(tester);
      await tester.enterText(find.byType(TextField), 'Playa');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(
        find.text('Ya existe una categoría con ese nombre'),
        findsOneWidget,
      );
      // Menu open and the new category row is not in the list.
      expect(find.byType(TextField), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Playa'), findsNothing);
    });

    testWidgets('create network error shows inline error', (tester) async {
      final record = _Record();
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          record: record,
          onCreate: (name, icon) async {
            record.createCalls++;
            throw const PlaceApiException('boom');
          },
        ),
      );

      await _openMenu(tester);
      await _startCreate(tester);
      await tester.enterText(find.byType(TextField), 'Playa');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo crear la categoría'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Playa'), findsNothing);
    });

    testWidgets('create generic error shows inline error', (tester) async {
      await tester.pumpWidget(
        _Harness(
          categories: [_naturaleza],
          onCreate: (_, _) async => throw Exception('boom'),
        ),
      );

      await _openMenu(tester);
      await _startCreate(tester);
      await tester.enterText(find.byType(TextField), 'Playa');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo crear la categoría'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Playa'), findsNothing);
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

      await _openMenu(tester);
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

        await _openMenu(tester);
        await _tapDeleteOn(tester, 'Monumento');

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Eliminar categoría'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
        await tester.pumpAndSettle();

        expect(record.deletedId, 2);
        expect(record.reassignTo, isNull);
        // It was the selected category, so the selection was cleared.
        expect(record.lastChanged, isNull);
        // The row is gone from the menu; the menu stays open.
        expect(find.text('Monumento'), findsNothing);
        expect(find.text('Naturaleza'), findsOneWidget);
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

        await _openMenu(tester);
        await _tapDeleteOn(tester, 'Naturaleza');

        expect(find.textContaining('tiene 1 lugar'), findsOneWidget);
        // Destination dropdown with the other category as candidate.
        final items = tester.widgetList<DropdownMenuItem<Category>>(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(DropdownMenuItem<Category>),
          ),
        );
        expect(items.map((i) => i.value!.id), isNot(contains(1)));
        expect(items.map((i) => i.value!.id), contains(2));

        // The destination defaults to the first candidate (Monumento).
        await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
        await tester.pumpAndSettle();

        expect(record.deletedId, 1);
        expect(record.reassignTo, 2);
        // The selected category was deleted, so selection cleared.
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

      await _openMenu(tester);
      await _tapDeleteOn(tester, 'Naturaleza');

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

      await _openMenu(tester);
      await _tapDeleteOn(tester, 'Monumento');
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

        await _openMenu(tester);
        await _tapDeleteOn(tester, 'Monumento');
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

      await _openMenu(tester);
      await _tapDeleteOn(tester, 'Monumento');
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo eliminar la categoría'), findsOneWidget);
    });
  });

  group('icon display', () {
    testWidgets('trigger shows the selected category icon', (tester) async {
      const beach = Category(id: 1, name: 'Playa', icon: 'beach');
      await tester.pumpWidget(
        _wrap(
          CategoryDropdown(
            categories: [beach],
            value: beach,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.byIcon(Icons.beach_access), findsOneWidget);
    });

    testWidgets('rows show their category icon', (tester) async {
      const beach = Category(id: 1, name: 'Playa', icon: 'beach');
      const monument = Category(id: 2, name: 'Monumento', icon: 'monument');
      await tester.pumpWidget(
        _wrap(
          CategoryDropdown(
            categories: [beach, monument],
            onChanged: (_) {},
          ),
        ),
      );

      await _openMenu(tester);

      expect(find.byIcon(Icons.beach_access), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });

    testWidgets('categories without icon show the placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CategoryDropdown(
            categories: [_naturaleza],
            value: _naturaleza,
            onChanged: (_) {},
          ),
        ),
      );

      // Placeholder in the trigger + placeholder as the row leading icon.
      await _openMenu(tester);
      expect(find.byIcon(categoryPlaceholderIcon), findsNWidgets(2));
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

      await _openMenu(tester);
      await _startCreate(tester);
      await tester.enterText(find.byType(TextField), 'Playa');

      // Open the picker and choose the beach icon.
      await tester.tap(find.byTooltip('Elegir icono'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.beach_access));
      await tester.pumpAndSettle();

      // The picker button in the create row now shows the chosen icon.
      expect(find.byIcon(Icons.beach_access), findsOneWidget);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

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

      await _openMenu(tester);
      await _startRename(tester);

      // The edit row's icon button shows the preloaded icon.
      final editRow = find.ancestor(
        of: find.text('Nuevo nombre'),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: editRow, matching: find.byIcon(Icons.beach_access)),
        findsOneWidget,
      );

      // Change the icon to monument via the picker.
      await tester.tap(find.byTooltip('Elegir icono'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.account_balance));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

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

      await _openMenu(tester);
      await _startRename(tester);
      await tester.tap(find.byTooltip('Elegir icono'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sin icono'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(record.renamedIcon, isNull);
    });

    testWidgets('cancelling the picker keeps the previous icon', (
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
            record.renamedName = name;
            record.renamedIcon = icon;
            return Category(id: 1, name: name, icon: icon);
          },
        ),
      );

      await _openMenu(tester);
      await _startRename(tester);
      await tester.tap(find.byTooltip('Elegir icono'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(record.renamedIcon, 'beach');
    });
  });
}
