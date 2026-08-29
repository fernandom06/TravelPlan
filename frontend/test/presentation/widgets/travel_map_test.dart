import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/data/category_icon_catalog.dart';
import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/models/place_draft.dart';
import 'package:frontend/data/models/place_update.dart';
import 'package:frontend/presentation/widgets/category_chip_strip.dart';
import 'package:frontend/presentation/widgets/import_url_dialog.dart';
import 'package:frontend/presentation/widgets/map_constants.dart';
import 'package:frontend/presentation/widgets/place_form.dart';
import 'package:frontend/presentation/widgets/place_pin.dart';
import 'package:frontend/presentation/widgets/travel_map.dart';

const _naturaleza = Category(id: 1, name: 'Naturaleza');
const _categories = [_naturaleza];

class MapUrlResolveTestException implements Exception {
  const MapUrlResolveTestException(this.message);

  final String message;

  @override
  String toString() => message;
}

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
  MapController? mapController,
  Future<Category> Function(String name, String? icon)? onCreateCategory,
  Future<Category> Function(int id, String name, String? icon)?
  onRenameCategory,
  Future<void> Function(int id, int? reassignTo)? onDeleteCategory,
  Future<void> Function(int id, PlaceUpdate update)? onUpdatePlace,
  Future<void> Function(int id)? onDeletePlace,
  Future<LatLng> Function(String url)? onResolveMapUrl,
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
        onResolveMapUrl: onResolveMapUrl,
        mapController: mapController,
      ),
    ),
  );
}


Future<void> _pump(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(widget);
}

List<Marker> _markers(WidgetTester tester) =>
    tester.widget<MarkerLayer>(find.byType(MarkerLayer).first).markers;

PlacePin _pinOf(Marker marker) {
  var child = marker.child;
  if (child is GestureDetector && child.child != null) child = child.child!;
  if (child is PinHoverTooltip) child = child.child;
  return child as PlacePin;
}

double _labelOpacity(WidgetTester tester, int id) {
  final opacity = tester.widget<Opacity>(
    find
        .descendant(
          of: find.byKey(ValueKey('place-label-$id')),
          matching: find.byType(Opacity),
        )
        .first,
  );
  return opacity.opacity;
}

void main() {
  testWidgets('renders FlutterMap with no markers when there are no places', (
    tester,
  ) async {
    await _pump(tester, _map());

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(_markers(tester), isEmpty);
  });

  testWidgets('uses CartoDB Positron tiles with visible attribution', (
    tester,
  ) async {
    await _pump(tester, _map());

    final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer).first);
    expect(tileLayer.urlTemplate, kCartoTileUrlTemplate);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is RichAttributionWidget &&
            w.attributions.any(
              (a) =>
                  a is TextSourceAttribution &&
                  a.text.contains('OpenStreetMap contributors') &&
                  a.text.contains('CARTO'),
            ),
      ),
      findsWidgets,
    );
  });

  testWidgets('renders a teardrop pin per place with its category icon', (
    tester,
  ) async {
    await _pump(tester, _map(places: [_place]));

    expect(_markers(tester), hasLength(1));
    final pin = _pinOf(_markers(tester).first);
    expect(pin.color, AppColors.primary);
    expect(pin.icon, categoryIconFor(_place.category.icon));
    expect(pin.halo, isFalse);
  });

  testWidgets('hovering a saved pin shows a name tooltip on desktop', (
    tester,
  ) async {
    await _pump(tester, _map(places: [_place]));

    expect(find.byKey(const Key('place-pin-tooltip')), findsNothing);

    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: const Offset(10, 10));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byType(PlacePin).first));
    await tester.pump();

    expect(find.byKey(const Key('place-pin-tooltip')), findsOneWidget);

    await gesture.removePointer();
    await tester.pump();
    expect(find.byKey(const Key('place-pin-tooltip')), findsNothing);
  });

  testWidgets('tapping a wrapped pin still opens the details', (tester) async {
    await _pump(tester, _map(places: [_place]));

    await tester.tap(find.byType(PlacePin).first);
    await tester.pumpAndSettle();

    expect(find.byType(PlaceDetails), findsOneWidget);
  });

  testWidgets('tap on empty map shows a red marker and opens the form', (
    tester,
  ) async {
    await _pump(tester, _map());

    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await tester.pump(const Duration(milliseconds: 350));

    expect(_markers(tester), hasLength(1));
    final pin = _pinOf(_markers(tester).first);
    expect(pin.color, AppColors.accent);
    expect(pin.icon, Icons.add);
    expect(pin.halo, isTrue);
    expect(find.byType(PlaceForm), findsOneWidget);
  });

  testWidgets('autofocus on Nombre when creating via tap', (tester) async {
    await _pump(tester, _map());

    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceForm), findsOneWidget);
    final nameField = tester.widget<EditableText>(
      find.byType(EditableText).first,
    );
    expect(nameField.focusNode.hasFocus, isTrue);
  });

  testWidgets('autofocus on Nombre when editing', (tester) async {
    await _pump(tester, _map(places: [_place]));

    await tester.tap(find.byType(PlacePin).first);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Editar'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceForm), findsOneWidget);
    final nameField = tester.widget<EditableText>(
      find.byType(EditableText).first,
    );
    expect(nameField.focusNode.hasFocus, isTrue);
  });

  testWidgets('autofocus on Nombre when importing', (tester) async {
    await _pump(tester, _map(
        onResolveMapUrl: (url) async => const LatLng(41.6474339, -0.8861451),
      ),
    );

    await tester.tap(find.byIcon(Icons.link));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'https://maps.app.goo.gl/tpabGChzziYCfgjy5',
    );
    await tester.tap(find.text('Importar'));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceForm), findsOneWidget);
    final nameField = tester.widget<EditableText>(
      find.byType(EditableText).first,
    );
    expect(nameField.focusNode.hasFocus, isTrue);
  });

  testWidgets(
    'second tap while the form is open closes it without a new marker',
    (tester) async {
      await _pump(tester, _map());

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
    await _pump(tester, _map(places: [_place]));

    await tester.tap(find.byType(PlacePin).first);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PlaceDetails), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);
    expect(find.text('Guardar Lugar'), findsNothing);
  });

  testWidgets('tapping outside the form closes and discards it', (
    tester,
  ) async {
    await _pump(tester, _map());

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
    await _pump(tester, _map(
        onCreateCategory: (name, icon) async {
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

    await tester.tap(
      find.descendant(
        of: find.byType(CategoryChipStrip),
        matching: find.byIcon(Icons.add),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre de la categoría'),
      'Playa',
    );
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(createdName, 'Playa');
    // 'Playa' is autoselected and appears as a chip.
    expect(find.text('Playa'), findsOneWidget);
  });

  testWidgets('wires rename and delete callbacks to the form on the map', (
    tester,
  ) async {
    String? renamedId;
    String? renamedName;
    await _pump(tester, _map(
        onRenameCategory: (id, name, icon) async {
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
    await tester.longPress(find.text('Naturaleza'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
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
    await _pump(tester, _map(places: [_place]));

    await tester.tap(find.byType(PlacePin).first);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PlaceDetails), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);
    expect(find.text('Guardar Lugar'), findsNothing);
  });

  testWidgets('Editar opens a prefilled PlaceForm with Eliminar', (
    tester,
  ) async {
    await _pump(tester, _map(places: [_place]));

    await tester.tap(find.byType(PlacePin).first);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Editar'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PlaceForm), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PlaceForm),
        matching: find.text('Mirador'),
      ),
      findsOneWidget,
    );
    expect(find.text('Eliminar'), findsOneWidget);
    expect(find.text('Guardar Lugar'), findsOneWidget);
  });

  testWidgets('Guardar in edit calls onUpdatePlace and closes the panel', (
    tester,
  ) async {
    int? updatedId;
    PlaceUpdate? sentUpdate;
    await _pump(tester, _map(
        places: [_place],
        onUpdatePlace: (id, update) async {
          updatedId = id;
          sentUpdate = update;
        },
      ),
    );

    await tester.tap(find.byType(PlacePin).first);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Editar'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar Lugar'));
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
    await _pump(tester, _map(
        places: [_place],
        onUpdatePlace: (_, _) async {
          updated = true;
        },
      ),
    );

    await tester.tap(find.byType(PlacePin).first);
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
    await _pump(tester, _map(
        places: [_place],
        onDeletePlace: (id) async {
          deletedId = id;
        },
      ),
    );

    await tester.tap(find.byType(PlacePin).first);
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
    await _pump(tester, _map(
        places: [_place],
        onDeletePlace: (_) async {
          deleted = true;
        },
      ),
    );

    await tester.tap(find.byType(PlacePin).first);
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
      await _pump(tester, _map(
          places: [_place],
          isOnline: false,
          onUpdatePlace: (_, _) async {
            updated = true;
          },
        ),
      );

      await tester.tap(find.byType(PlacePin).first);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Editar'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.enterText(find.byType(TextField).first, 'Nuevo nombre');
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar Lugar'));
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
      await _pump(tester, _map(
          places: [_place],
          isOnline: false,
          onDeletePlace: (_) async {
            deleted = true;
          },
        ),
      );

      await tester.tap(find.byType(PlacePin).first);
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
    await _pump(tester, _map(places: [_place]));

    await tester.tap(find.byType(PlacePin).first);
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
    await _pump(tester, _map(places: [_place, other]));

    await tester.tap(find.byType(PlacePin).first);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Editar'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(PlaceForm), findsOneWidget);

    await tester.tap(find.byType(PlacePin).last);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PlaceForm), findsNothing);
    expect(find.byType(PlaceDetails), findsNothing);
  });

  testWidgets('dragging the map closes the edit panel', (tester) async {
    await _pump(tester, _map(places: [_place]));

    await tester.tap(find.byType(PlacePin).first);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Editar'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(PlaceForm), findsOneWidget);

    await tester.drag(find.byType(FlutterMap), const Offset(-50, 0));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PlaceForm), findsNothing);
  });

  testWidgets(
    'PlaceDetails is shown inside the right panel on desktop',
    (tester) async {
      await _pump(tester, _map(places: [_place]));

      await tester.tap(find.byType(PlacePin).first);
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        find.ancestor(
          of: find.byType(PlaceDetails),
          matching: find.byKey(const Key('place-form-panel')),
        ),
        findsOneWidget,
      );
    },
  );

  group('import from Google Maps', () {
    testWidgets('no FAB when onResolveMapUrl is not provided', (tester) async {
      await _pump(tester, _map());

      expect(find.byIcon(Icons.link), findsNothing);
    });

    testWidgets('shows the FAB when onResolveMapUrl is provided', (
      tester,
    ) async {
      await _pump(tester, _map(
          onResolveMapUrl: (url) async => const LatLng(41.6474339, -0.8861451),
        ),
      );

      expect(find.byIcon(Icons.link), findsOneWidget);
      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.heroTag, 'map-import-fab');
    });

    testWidgets('offline tap shows SnackBar and does not open the dialog', (
      tester,
    ) async {
      await _pump(tester, _map(
          isOnline: false,
          onResolveMapUrl: (url) async => const LatLng(41.6474339, -0.8861451),
        ),
      );

      await tester.tap(find.byIcon(Icons.link));
      await tester.pump();

      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.byType(ImportUrlDialog), findsNothing);
    });

    testWidgets(
      'resolved URL centers the map and opens the create form with red marker',
      (tester) async {
        await _pump(tester, _map(
            onResolveMapUrl: (url) async =>
                const LatLng(41.6474339, -0.8861451),
          ),
        );

        await tester.tap(find.byIcon(Icons.link));
        await tester.pumpAndSettle();
        expect(find.byType(ImportUrlDialog), findsOneWidget);

        await tester.enterText(
          find.byType(TextField),
          'https://maps.app.goo.gl/tpabGChzziYCfgjy5',
        );
        await tester.tap(find.text('Importar'));
        await tester.pumpAndSettle();

        expect(find.byType(ImportUrlDialog), findsNothing);
        expect(find.byType(PlaceForm), findsOneWidget);
        expect(_markers(tester), hasLength(1));
        final pin = _pinOf(_markers(tester).first);
        expect(pin.color, AppColors.accent);
        expect(pin.icon, Icons.add);
      },
    );

    testWidgets('resolve error shows SnackBar and does not open the form', (
      tester,
    ) async {
      await _pump(tester, _map(
          onResolveMapUrl: (url) async =>
              throw MapUrlResolveTestException('No se pudo resolver el enlace'),
        ),
      );

      await tester.tap(find.byIcon(Icons.link));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'https://maps.app.goo.gl/x',
      );
      await tester.tap(find.text('Importar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Error al importar: No se pudo resolver el enlace'),
        findsOneWidget,
      );
      expect(find.byType(PlaceForm), findsNothing);
    });

    testWidgets('Cancelar after import closes the form without creating', (
      tester,
    ) async {
      await _pump(tester, _map(
          onResolveMapUrl: (url) async => const LatLng(41.6474339, -0.8861451),
        ),
      );

      await tester.tap(find.byIcon(Icons.link));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'https://maps.app.goo.gl/tpabGChzziYCfgjy5',
      );
      await tester.tap(find.text('Importar'));
      await tester.pumpAndSettle();
      expect(find.byType(PlaceForm), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(PlaceForm), findsNothing);
      expect(_markers(tester), isEmpty);
    });
  });

  group('place labels', () {
    testWidgets('label is visible with the place name at default zoom', (
      tester,
    ) async {
      await _pump(tester, _map(places: [_place]));

      expect(_labelOpacity(tester, 1), 1.0);
      expect(find.text('Mirador'), findsOneWidget);
    });

    testWidgets('label is hidden below zoom 9', (tester) async {
      final controller = MapController();
      await _pump(tester, _map(places: [_place], mapController: controller),
      );
      await tester.pumpAndSettle();

      controller.move(kDefaultCenter, 8.0);
      await tester.pump();

      expect(_labelOpacity(tester, 1), 0.0);
    });

    testWidgets('label fades at intermediate zoom', (tester) async {
      final controller = MapController();
      await _pump(tester, _map(places: [_place], mapController: controller),
      );
      await tester.pumpAndSettle();

      controller.move(kDefaultCenter, 10.0);
      await tester.pump();

      expect(_labelOpacity(tester, 1), closeTo(0.5, 0.001));
    });

    testWidgets('overlapping labels keep only the first place visible', (
      tester,
    ) async {
      const other = Place(
        id: 2,
        name: 'Otro',
        description: null,
        latitude: 42.0414,
        longitude: -3.0428,
        category: _naturaleza,
      );
      await _pump(tester, _map(places: [_place, other]));

      expect(_labelOpacity(tester, 1), 1.0);
      expect(_labelOpacity(tester, 2), 0.0);
    });

    testWidgets('open popup hides its own label', (tester) async {
      const other = Place(
        id: 2,
        name: 'Otro',
        description: null,
        latitude: 42.02,
        longitude: -3.02,
        category: _naturaleza,
      );
      await _pump(tester, _map(places: [_place, other]));

      await tester.tap(find.byType(PlacePin).first);
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(PlaceDetails), findsOneWidget);
      expect(_labelOpacity(tester, 1), 0.0);
      expect(_labelOpacity(tester, 2), 1.0);
    });

    testWidgets('editing keeps the open label hidden', (tester) async {
      const other = Place(
        id: 2,
        name: 'Otro',
        description: null,
        latitude: 42.02,
        longitude: -3.02,
        category: _naturaleza,
      );
      await _pump(tester, _map(places: [_place, other]));

      await tester.tap(find.byType(PlacePin).first);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Editar'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(PlaceForm), findsOneWidget);
      expect(_labelOpacity(tester, 1), 0.0);
    });

    testWidgets('closing the popup restores the label', (tester) async {
      const other = Place(
        id: 2,
        name: 'Otro',
        description: null,
        latitude: 42.02,
        longitude: -3.02,
        category: _naturaleza,
      );
      await _pump(tester, _map(places: [_place, other]));

      await tester.tap(find.byType(PlacePin).first);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Cerrar'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(PlaceDetails), findsNothing);
      expect(_labelOpacity(tester, 1), 1.0);
    });

    testWidgets('creating a place does not add a label', (tester) async {
      await _pump(tester, _map());

      await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(PlaceForm), findsOneWidget);
      expect(find.byKey(const ValueKey('place-label-1')), findsNothing);
    });

    testWidgets('runtime place updates refresh labels', (tester) async {
      const other = Place(
        id: 2,
        name: 'Otro',
        description: null,
        latitude: 42.02,
        longitude: -3.02,
        category: _naturaleza,
      );
      await _pump(tester, _map(places: [_place]));
      expect(find.byKey(const ValueKey('place-label-1')), findsOneWidget);

      await _pump(tester, _map(places: [_place, other]));
      expect(find.byKey(const ValueKey('place-label-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('place-label-2')), findsOneWidget);
    });
  });
}
