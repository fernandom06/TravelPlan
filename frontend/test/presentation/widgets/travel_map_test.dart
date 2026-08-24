import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/models/place_draft.dart';
import 'package:frontend/data/models/place_update.dart';
import 'package:frontend/presentation/widgets/category_dropdown.dart';
import 'package:frontend/presentation/widgets/place_form.dart';
import 'package:frontend/presentation/widgets/travel_map.dart';

const _naturaleza = Category(id: 1, name: 'Naturaleza');
const _categories = [_naturaleza];

const _place = Place(
  id: 1,
  name: 'Mirador',
  description: null,
  latitude: 42.0414,
  longitude: -3.0428,
  category: _naturaleza,
);

Future<void> _noopCreate(PlaceDraft draft) async {}

Future<void> _noopUpdate(int id, PlaceUpdate update) async {}

Future<void> _noopDelete(int id) async {}

Widget _map({
  List<Place> places = const [],
  bool isOnline = true,
  Future<Category> Function(String name)? onCreateCategory,
  Future<Category> Function(int id, String name)? onRenameCategory,
  Future<void> Function(int id, int? reassignTo)? onDeleteCategory,
  Future<void> Function(int id, PlaceUpdate update)? onUpdatePlace,
  Future<void> Function(int id)? onDeletePlace,
}) {
  return MaterialApp(
    home: Scaffold(
      body: TravelMap(
        places: places,
        categories: _categories,
        onCreatePlace: _noopCreate,
        onUpdatePlace: onUpdatePlace ?? _noopUpdate,
        onDeletePlace: onDeletePlace ?? _noopDelete,
        onCreateCategory: onCreateCategory,
        onRenameCategory: onRenameCategory,
        onDeleteCategory: onDeleteCategory,
        isOnline: isOnline,
      ),
    ),
  );
}

List<Marker> _markers(WidgetTester tester) =>
    tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers;

Icon _markerIcon(Marker marker) {
  final child = marker.child;
  if (child is Icon) return child;
  return (child as GestureDetector).child as Icon;
}

void main() {
  testWidgets('renders FlutterMap with no markers when there are no places', (
    tester,
  ) async {
    await tester.pumpWidget(_map());

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(_markers(tester), isEmpty);
  });

  testWidgets('renders a blue marker per place', (tester) async {
    await tester.pumpWidget(_map(places: [_place]));

    expect(_markers(tester), hasLength(1));
    expect(_markerIcon(_markers(tester).first).color, Colors.blue);
  });

  testWidgets('tap on empty map shows a red marker and opens the form', (
    tester,
  ) async {
    await tester.pumpWidget(_map());

    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await tester.pump(const Duration(milliseconds: 350));

    expect(_markers(tester), hasLength(1));
    expect(_markerIcon(_markers(tester).first).color, Colors.red);
    expect(find.byType(PlaceForm), findsOneWidget);
  });

  testWidgets(
    'second tap while the form is open closes it without a new marker',
    (tester) async {
      await tester.pumpWidget(_map());

      await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(PlaceForm), findsOneWidget);

      await tester.tapAt(
        tester.getCenter(find.byType(FlutterMap)) + const Offset(40, 40),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(PlaceForm), findsNothing);
      expect(_markers(tester), isEmpty);
    },
  );

  testWidgets('tapping a blue marker opens a read-only form', (tester) async {
    await tester.pumpWidget(_map(places: [_place]));

    await tester.tap(find.byIcon(Icons.location_on).first);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PlaceDetails), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);
    expect(find.text('Guardar'), findsNothing);
  });

  testWidgets('tapping outside the form closes and discards it', (
    tester,
  ) async {
    await tester.pumpWidget(_map());

    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(PlaceForm), findsOneWidget);

    await tester.tapAt(
      tester.getCenter(find.byType(FlutterMap)) + const Offset(60, 60),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PlaceForm), findsNothing);
    expect(_markers(tester), isEmpty);
  });

  testWidgets('creates a category from the form opened on the map', (
    tester,
  ) async {
    String? createdName;
    await tester.pumpWidget(
      _map(
        onCreateCategory: (name) async {
          createdName = name;
          return const Category(id: 5, name: 'Playa');
        },
      ),
    );

    await tester.tapAt(
      tester.getCenter(find.byType(FlutterMap)) + const Offset(0, 220),
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(PlaceForm), findsOneWidget);

    await tester.tap(find.byType(CategoryDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre de la categoría'),
      'Playa',
    );
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(createdName, 'Playa');
    // 'Playa' is autoselected and appears in the open menu.
    expect(find.text('Playa'), findsNWidgets(2));
  });

  testWidgets('wires rename and delete callbacks to the form on the map', (
    tester,
  ) async {
    String? renamedId;
    String? renamedName;
    await tester.pumpWidget(
      _map(
        onRenameCategory: (id, name) async {
          renamedId = '$id';
          renamedName = name;
          return const Category(id: 1, name: 'Costa');
        },
        onDeleteCategory: (_, _) async {},
      ),
    );

    await tester.tapAt(
      tester.getCenter(find.byType(FlutterMap)) + const Offset(0, 220),
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(PlaceForm), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Mirador');
    await tester.pump();
    await tester.tap(find.byType(CategoryDropdown));
    await tester.pumpAndSettle();

    final row = find.ancestor(
      of: find.text('Naturaleza'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: row, matching: find.byIcon(Icons.edit)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nuevo nombre'),
      'Costa',
    );
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(renamedId, '1');
    expect(renamedName, 'Costa');
  });

  testWidgets('marker tap opens PlaceDetails with Editar and Cerrar', (
    tester,
  ) async {
    await tester.pumpWidget(_map(places: [_place]));

    await tester.tap(find.byIcon(Icons.location_on).first);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PlaceDetails), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);
    expect(find.text('Guardar'), findsNothing);
  });

  testWidgets('Editar opens a prefilled PlaceForm with Eliminar', (
    tester,
  ) async {
    await tester.pumpWidget(_map(places: [_place]));

    await tester.tap(find.byIcon(Icons.location_on).first);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Editar'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PlaceForm), findsOneWidget);
    expect(find.text('Mirador'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('Guardar in edit calls onUpdatePlace and closes the panel', (
    tester,
  ) async {
    int? updatedId;
    PlaceUpdate? sentUpdate;
    await tester.pumpWidget(
      _map(
        places: [_place],
        onUpdatePlace: (id, update) async {
          updatedId = id;
          sentUpdate = update;
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.location_on).first);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Editar'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(updatedId, 1);
    expect(sentUpdate!.name, 'Mirador');
    expect(sentUpdate!.categoryId, 1);
    expect(find.byType(PlaceForm), findsNothing);
    expect(find.byType(PlaceDetails), findsNothing);
  });

  testWidgets('Cancelar in edit returns to PlaceDetails without updating', (
    tester,
  ) async {
    var updated = false;
    await tester.pumpWidget(
      _map(
        places: [_place],
        onUpdatePlace: (_, _) async {
          updated = true;
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.location_on).first);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Editar'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Cancelar'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PlaceDetails), findsOneWidget);
    expect(find.byType(PlaceForm), findsNothing);
    expect(updated, isFalse);
  });

  testWidgets('confirming Eliminar calls onDeletePlace and closes the panel', (
    tester,
  ) async {
    int? deletedId;
    await tester.pumpWidget(
      _map(
        places: [_place],
        onDeletePlace: (id) async {
          deletedId = id;
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.location_on).first);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Editar'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(deletedId, 1);
    expect(find.byType(PlaceForm), findsNothing);
  });

  testWidgets('cancelling the delete dialog does not call onDeletePlace', (
    tester,
  ) async {
    var deleted = false;
    await tester.pumpWidget(
      _map(
        places: [_place],
        onDeletePlace: (_) async {
          deleted = true;
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.location_on).first);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Editar'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancelar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(deleted, isFalse);
    expect(find.byType(PlaceForm), findsOneWidget);
  });

  testWidgets(
    'offline Guardar in edit shows SnackBar and keeps the panel open',
    (tester) async {
      var updated = false;
      await tester.pumpWidget(
        _map(
          places: [_place],
          isOnline: false,
          onUpdatePlace: (_, _) async {
            updated = true;
          },
        ),
      );

      await tester.tap(find.byIcon(Icons.location_on).first);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Editar'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.enterText(find.byType(TextField).first, 'Nuevo nombre');
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Sin conexión'), findsOneWidget);
      expect(updated, isFalse);
      expect(find.byType(PlaceForm), findsOneWidget);
      expect(find.text('Nuevo nombre'), findsOneWidget);
    },
  );

  testWidgets(
    'offline Eliminar keeps the panel open after the confirmation dialog',
    (tester) async {
      var deleted = false;
      await tester.pumpWidget(
        _map(
          places: [_place],
          isOnline: false,
          onDeletePlace: (_) async {
            deleted = true;
          },
        ),
      );

      await tester.tap(find.byIcon(Icons.location_on).first);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Editar'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Sin conexión'), findsOneWidget);
      expect(deleted, isFalse);
      expect(find.byType(PlaceForm), findsOneWidget);
    },
  );

  testWidgets('tapping the map closes the edit panel', (tester) async {
    await tester.pumpWidget(_map(places: [_place]));

    await tester.tap(find.byIcon(Icons.location_on).first);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Editar'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(PlaceForm), findsOneWidget);

    await tester.tapAt(
      tester.getCenter(find.byType(FlutterMap)) + const Offset(60, 60),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PlaceForm), findsNothing);
    expect(find.byType(PlaceDetails), findsNothing);
  });

  testWidgets('tapping another marker closes the edit panel', (tester) async {
    const other = Place(
      id: 2,
      name: 'Otro',
      description: null,
      latitude: 42.02,
      longitude: -3.02,
      category: _naturaleza,
    );
    await tester.pumpWidget(_map(places: [_place, other]));

    await tester.tap(find.byIcon(Icons.location_on).first);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Editar'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(PlaceForm), findsOneWidget);

    await tester.tap(find.byIcon(Icons.location_on).last);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PlaceForm), findsNothing);
    expect(find.byType(PlaceDetails), findsNothing);
  });

  testWidgets('dragging the map closes the edit panel', (tester) async {
    await tester.pumpWidget(_map(places: [_place]));

    await tester.tap(find.byIcon(Icons.location_on).first);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Editar'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(PlaceForm), findsOneWidget);

    await tester.drag(find.byType(FlutterMap), const Offset(-50, 0));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PlaceForm), findsNothing);
  });

  testWidgets(
    'PlaceDetails overlay is positioned near the marker, not origin',
    (tester) async {
      await tester.pumpWidget(_map(places: [_place]));

      await tester.tap(find.byIcon(Icons.location_on).first);
      await tester.pump(const Duration(milliseconds: 350));

      final positioned = tester.widget<Positioned>(
        find.ancestor(
          of: find.byType(PlaceDetails),
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned.left, isNot(0));
      expect(positioned.top, isNot(0));
    },
  );
}
