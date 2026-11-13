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
import 'package:frontend/presentation/widgets/import_url_dialog.dart';
import 'package:frontend/presentation/widgets/map_constants.dart';
import 'package:frontend/presentation/widgets/place_form.dart';
import 'package:frontend/presentation/widgets/place_label_layer.dart';
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
  Future<void> Function(PlaceDraft draft)? onCreatePlace,
  Future<void> Function(int id, PlaceUpdate update)? onUpdatePlace,
  Future<void> Function(int id)? onDeletePlace,
  Future<LatLng> Function(String url)? onResolveMapUrl,
}) {
  return MaterialApp(
    home: Scaffold(
      body: TravelMap(
        places: places,
        categories: _categories,
        onCreatePlace: onCreatePlace ?? _noopCreate,
        onUpdatePlace: onUpdatePlace ?? _noopUpdate,
        onDeletePlace: onDeletePlace ?? _noopDelete,
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

  testWidgets('uses OSM tiles with visible attribution', (tester) async {
    await _pump(tester, _map());

    final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer).first);
    expect(tileLayer.urlTemplate, kOsmTileUrlTemplate);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is RichAttributionWidget &&
            w.attributions.any(
              (a) =>
                  a is TextSourceAttribution &&
                  a.text.contains('OpenStreetMap contributors'),
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

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(10, 10));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byType(PlacePin).first));
    await tester.pump();

    expect(find.byKey(const Key('place-pin-tooltip')), findsOneWidget);

    await gesture.removePointer();
    await tester.pump();
    expect(find.byKey(const Key('place-pin-tooltip')), findsNothing);
  });

  testWidgets('hovering a pin with a long name shows the full name tooltip', (
    tester,
  ) async {
    final longPlace = Place(
      id: 1,
      name: 'x' * 60,
      description: null,
      latitude: 42.0414,
      longitude: -3.0428,
      category: _naturaleza,
    );
    await _pump(tester, _map(places: [longPlace]));

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(10, 10));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byType(PlacePin).first));
    await tester.pump();

    expect(find.text('x' * 60), findsOneWidget);
    final tooltipSize = tester.getSize(
      find.byKey(const Key('place-pin-tooltip')),
    );
    expect(tooltipSize.width, greaterThan(40));

    await gesture.removePointer();
    await tester.pump();
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
    await _pump(
      tester,
      _map(
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
    await _pump(
      tester,
      _map(
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
    await _pump(
      tester,
      _map(
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
    await _pump(
      tester,
      _map(
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
    await _pump(
      tester,
      _map(
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
      await _pump(
        tester,
        _map(
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

      expect(
        find.text('Sin conexión: el cambio no se ha guardado.'),
        findsOneWidget,
      );
      expect(updated, isFalse);
      expect(find.byType(PlaceForm), findsOneWidget);
      expect(find.text('Nuevo nombre'), findsOneWidget);
    },
  );

  testWidgets(
    'offline Eliminar keeps the panel open after the confirmation dialog',
    (tester) async {
      var deleted = false;
      await _pump(
        tester,
        _map(
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

      expect(
        find.text('Sin conexión: el lugar no se ha eliminado.'),
        findsOneWidget,
      );
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

  group('offline and failed saves keep the draft', () {
    testWidgets(
      'offline Guardar keeps the form and draft, with a persistent retry',
      (tester) async {
        final drafts = <PlaceDraft>[];
        await _pump(
          tester,
          _map(
            isOnline: false,
            onCreatePlace: (draft) async => drafts.add(draft),
          ),
        );

        await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.enterText(find.byType(TextField).first, 'Mirador nuevo');
        await tester.tap(find.text('Naturaleza'));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Guardar Lugar'));
        // Let the snackbar's entrance animation settle so Reintentar is
        // hittable (pumps without duration leave it mid-slide).
        await tester.pumpAndSettle();

        // Field-truthful: the error names what did NOT happen, the draft
        // stays on screen and the notice does not vanish on its own.
        expect(
          find.text('Sin conexión: el lugar no se ha guardado.'),
          findsOneWidget,
        );
        expect(find.text('Reintentar'), findsOneWidget);
        expect(find.byType(PlaceForm), findsOneWidget);
        expect(find.text('Mirador nuevo'), findsOneWidget);
        expect(drafts, isEmpty);

        // Back online, Reintentar recreates the exact draft and closes.
        await tester.pumpWidget(
          _map(
            isOnline: true,
            onCreatePlace: (draft) async => drafts.add(draft),
          ),
        );
        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();

        expect(drafts, hasLength(1));
        expect(drafts.single.name, 'Mirador nuevo');
        expect(find.byType(PlaceForm), findsNothing);
      },
    );

    testWidgets(
      'a failed save keeps the form open and Reintentar retries the draft',
      (tester) async {
        var fail = true;
        final drafts = <PlaceDraft>[];
        await _pump(
          tester,
          _map(
            onCreatePlace: (draft) async {
              if (fail) throw Exception('boom');
              drafts.add(draft);
            },
          ),
        );

        await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.enterText(find.byType(TextField).first, 'Mirador nuevo');
        await tester.tap(find.text('Naturaleza'));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Guardar Lugar'));
        await tester.pumpAndSettle();

        expect(
          find.text('No se pudo guardar el lugar. Revisa tu conexión.'),
          findsOneWidget,
        );
        expect(find.byType(PlaceForm), findsOneWidget);

        fail = false;
        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();

        expect(drafts, hasLength(1));
        expect(drafts.single.name, 'Mirador nuevo');
        expect(find.byType(PlaceForm), findsNothing);
      },
    );
  });

  group('draft protection on the map', () {
    testWidgets('panning while creating keeps the form and draft', (
      tester,
    ) async {
      await _pump(tester, _map());

      await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.enterText(find.byType(TextField).first, 'Mirador nuevo');
      await tester.pump();

      await tester.drag(find.byType(FlutterMap), const Offset(-50, 0));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(PlaceForm), findsOneWidget);
      expect(find.text('Mirador nuevo'), findsOneWidget);
    });

    testWidgets(
      'tapping the map with typed content asks before discarding the draft',
      (tester) async {
        await _pump(tester, _map());

        await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.enterText(find.byType(TextField).first, 'Mirador nuevo');
        await tester.pump();

        await tester.tapAt(
          tester.getCenter(find.byType(FlutterMap)) + const Offset(60, 60),
        );
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('¿Descartar el lugar?'), findsOneWidget);

        // Seguir editando keeps everything.
        await tester.tap(find.text('Seguir editando'));
        await tester.pumpAndSettle();
        expect(find.byType(PlaceForm), findsOneWidget);
        expect(find.text('Mirador nuevo'), findsOneWidget);

        // Descartar closes and removes the marker.
        await tester.tapAt(
          tester.getCenter(find.byType(FlutterMap)) + const Offset(60, 60),
        );
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text('Descartar'));
        await tester.pumpAndSettle();

        expect(find.byType(PlaceForm), findsNothing);
        expect(_markers(tester), isEmpty);
      },
    );

    testWidgets('tapping the map with an empty create form closes silently', (
      tester,
    ) async {
      await _pump(tester, _map());

      await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(PlaceForm), findsOneWidget);

      await tester.tapAt(
        tester.getCenter(find.byType(FlutterMap)) + const Offset(60, 60),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('¿Descartar el lugar?'), findsNothing);
      expect(find.byType(PlaceForm), findsNothing);
    });
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

  testWidgets('PlaceDetails is shown inside the right panel on desktop', (
    tester,
  ) async {
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
  });

  group('import from Google Maps', () {
    testWidgets('no FAB when onResolveMapUrl is not provided', (tester) async {
      await _pump(tester, _map());

      expect(find.byIcon(Icons.link), findsNothing);
    });

    testWidgets('shows the FAB when onResolveMapUrl is provided', (
      tester,
    ) async {
      await _pump(
        tester,
        _map(
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
      await _pump(
        tester,
        _map(
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
        await _pump(
          tester,
          _map(
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
      await _pump(
        tester,
        _map(
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
        find.text(
          'No se pudo importar la ubicación. '
          'Comprueba el enlace e inténtalo de nuevo.',
        ),
        findsOneWidget,
      );
      expect(find.byType(PlaceForm), findsNothing);
    });

    testWidgets('Cancelar after import closes the form without creating', (
      tester,
    ) async {
      await _pump(
        tester,
        _map(
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

    testWidgets('long label renders the truncated name, not the full one', (
      tester,
    ) async {
      final name = 'x' * 30;
      final longPlace = Place(
        id: 1,
        name: name,
        description: null,
        latitude: 42.0414,
        longitude: -3.0428,
        category: _naturaleza,
      );
      await _pump(tester, _map(places: [longPlace]));

      expect(find.text(truncatePlaceLabel(name)), findsOneWidget);
      expect(find.text(name), findsNothing);
    });

    testWidgets('label of exactly 20 characters is read in full', (
      tester,
    ) async {
      final name = 'y' * 20;
      final twentyCharPlace = Place(
        id: 1,
        name: name,
        description: null,
        latitude: 42.0414,
        longitude: -3.0428,
        category: _naturaleza,
      );
      await _pump(tester, _map(places: [twentyCharPlace]));

      expect(find.text(name), findsOneWidget);
    });

    testWidgets('label marker width matches the truncated text geometry', (
      tester,
    ) async {
      final longPlace = Place(
        id: 1,
        name: 'x' * 30,
        description: null,
        latitude: 42.0414,
        longitude: -3.0428,
        category: _naturaleza,
      );
      await _pump(tester, _map(places: [longPlace]));

      final labelMarkers = tester
          .widget<MarkerLayer>(find.byType(MarkerLayer).last)
          .markers;
      expect(labelMarkers, hasLength(1));
      final expectedWidth =
          measureLabelSize(
            truncatePlaceLabel('x' * 30),
            kPlaceLabelStyle,
          ).width +
          2 * kLabelHPadding;
      expect(labelMarkers.first.width, expectedWidth);
    });

    testWidgets('overlap hides the second label with a long first name', (
      tester,
    ) async {
      final longFirst = Place(
        id: 1,
        name: 'x' * 30,
        description: null,
        latitude: 42.0414,
        longitude: -3.0428,
        category: _naturaleza,
      );
      const shortSecond = Place(
        id: 2,
        name: 'Otro',
        description: null,
        latitude: 42.0414,
        longitude: -3.0428,
        category: _naturaleza,
      );
      await _pump(tester, _map(places: [longFirst, shortSecond]));

      expect(_labelOpacity(tester, 1), 1.0);
      expect(_labelOpacity(tester, 2), 0.0);
    });

    testWidgets('label is hidden below zoom 9', (tester) async {
      final controller = MapController();
      await _pump(tester, _map(places: [_place], mapController: controller));
      await tester.pumpAndSettle();

      controller.move(kDefaultCenter, 8.0);
      await tester.pump();

      expect(_labelOpacity(tester, 1), 0.0);
    });

    testWidgets('label fades at intermediate zoom', (tester) async {
      final controller = MapController();
      await _pump(tester, _map(places: [_place], mapController: controller));
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
