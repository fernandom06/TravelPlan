import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/data/itinerary_api.dart';
import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/itinerary_item.dart';
import 'package:frontend/data/models/itinerary_move.dart';
import 'package:frontend/data/models/itinerary_slot.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/models/trip.dart';
import 'package:frontend/data/place_api.dart';
import 'package:frontend/presentation/controllers/itinerary_controller.dart';
import 'package:frontend/presentation/controllers/places_controller.dart';
import 'package:frontend/presentation/screens/itinerary_screen.dart';
import 'package:frontend/presentation/widgets/day_pill_strip.dart';
import 'package:frontend/presentation/widgets/general_items_section.dart';
import 'package:frontend/presentation/widgets/itinerary_place_card.dart';
import 'package:frontend/presentation/widgets/itinerary_slot_section.dart';
import 'package:frontend/presentation/widgets/itinerary_two_column_layout.dart';
import 'package:frontend/presentation/widgets/offline_banner.dart';
import 'package:frontend/presentation/widgets/place_picker_dialog.dart';

class _FakeItineraryApi extends ItineraryApi {
  _FakeItineraryApi({
    this.items = const [],
    this.createdItem,
    this.moveError,
    this.loadError,
  }) : super(baseUrl: 'http://fake');

  List<ItineraryItem> items;
  ItineraryItem? createdItem;
  Object? moveError;
  Object? loadError;

  /// When set, [moveItem] blocks on the completer so a test can inspect the
  /// optimistic state while the request is in flight.
  Completer<void>? hangMove;

  final List<int> moveCalls = [];
  final List<ItineraryMove> movePayloads = [];
  final List<int> addCalls = [];
  final List<int> removeCalls = [];

  @override
  Future<List<ItineraryItem>> fetchItinerary(String tripId) async {
    if (loadError != null) throw loadError!;
    return items;
  }

  @override
  Future<ItineraryItem> addPlace(String tripId, int placeId) async {
    addCalls.add(placeId);
    return createdItem ?? _item(placeId, position: 0);
  }

  @override
  Future<ItineraryItem> moveItem(
    String tripId,
    int itemId,
    ItineraryMove move,
  ) async {
    if (moveError != null) throw moveError!;
    if (hangMove != null) await hangMove!.future;
    moveCalls.add(itemId);
    movePayloads.add(move);
    return items.firstWhere((i) => i.id == itemId);
  }

  @override
  Future<void> removeItem(String tripId, int itemId) async {
    removeCalls.add(itemId);
  }
}

class _FakePlaceApi extends PlaceApi {
  _FakePlaceApi(this.places) : super(baseUrl: 'http://fake');

  final List<Place> places;

  @override
  Future<List<Category>> fetchCategories() async => const [];

  @override
  Future<List<Place>> fetchPlaces() async => places;
}

Category _category() =>
    const Category(id: 1, name: 'Naturaleza', icon: 'nature');

Place _place(int id) => Place(
  id: id,
  name: 'Lugar $id',
  description: null,
  latitude: 42.5,
  longitude: -3.5,
  category: _category(),
);

ItineraryItem _item(
  int id, {
  int position = 0,
  DateTime? day,
  ItinerarySlot? slot,
}) {
  return ItineraryItem(
    id: id,
    dayDate: day,
    slot: slot,
    position: position,
    place: _place(id),
  );
}

Trip _trip({DateTime? start, DateTime? end, String name = 'Viaje a Galicia'}) {
  return Trip(
    id: 'abc',
    name: name,
    description: null,
    startDate: start ?? DateTime(2026, 6, 1),
    endDate: end ?? DateTime(2026, 6, 10),
    imageUrl: null,
    createdAt: '2026-01-01',
  );
}

Future<ItineraryController> _controllerWith(
  _FakeItineraryApi api,
  Trip trip,
) async {
  final controller = ItineraryController(api);
  await controller.loadItinerary(trip);
  return controller;
}

Widget _wrap({
  required ItineraryController controller,
  required PlacesController places,
  required Trip trip,
  bool online = true,
}) {
  final onlineNotifier = ValueNotifier<bool>(online);
  addTearDown(onlineNotifier.dispose);
  return MaterialApp(
    theme: AppTheme.light(),
    home: ItineraryScreen(
      trip: trip,
      itineraryController: controller,
      placesController: places,
      online: onlineNotifier,
      baseUrl: 'http://localhost:8000',
    ),
  );
}

Future<PlacesController> _placesWith(List<Place> places) async {
  final controller = PlacesController(_FakePlaceApi(places));
  await controller.loadAll();
  return controller;
}

Future<TestGesture> _startDrag(
  WidgetTester tester,
  Finder card,
  Offset to,
) async {
  final from = tester.getCenter(card);
  final gesture = await tester.startGesture(from);
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
  for (var step = 1; step <= 6; step++) {
    await gesture.moveTo(Offset.lerp(from, to, step / 6)!);
    await tester.pump();
  }
  await gesture.moveTo(to);
  await tester.pump();
  return gesture;
}

Future<void> _dragCard(WidgetTester tester, Finder card, Offset to) async {
  final gesture = await _startDrag(tester, card, to);
  await gesture.up();
  await tester.pumpAndSettle();
}

/// Drags [card] onto [target] and drops, re-aiming at the target's live
/// centre: the preview hole changes the section height, which re-centres the
/// wide timeline, exactly like a user adjusting the drag.
Future<void> _dragOnto(WidgetTester tester, Finder card, Finder target) async {
  final gesture = await _startDrag(tester, card, tester.getCenter(target));
  for (var attempt = 0; attempt < 2; attempt++) {
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

int _tabIndex(WidgetTester tester) =>
    tester.widget<TabBarView>(find.byType(TabBarView)).controller!.index;

void main() {
  testWidgets('shows the trip name in the app bar', (tester) async {
    final api = _FakeItineraryApi();
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Viaje a Galicia'), findsOneWidget);
    final title = tester.widget<Text>(find.text('Viaje a Galicia'));
    expect(title.style?.fontSize, 28);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.centerTitle, isFalse);
    final theme = Theme.of(tester.element(find.byType(AppBar)));
    expect(theme.appBarTheme.centerTitle, isTrue);
    expect(theme.appBarTheme.titleTextStyle?.fontFamily, 'Fraunces');
  });

  testWidgets('shows one tab per day with date labels', (tester) async {
    final api = _FakeItineraryApi();
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Día 1 · 01 Jun'), findsOneWidget);
    expect(find.text('Día 10 · 10 Jun'), findsOneWidget);
    expect(find.text('Día 5 · 05 Jun'), findsOneWidget);
    final strip = tester.widget<DayPillStrip>(find.byType(DayPillStrip));
    expect(strip.days, hasLength(10));
  });

  testWidgets('day strip sits on a white surface with a divider above it', (
    tester,
  ) async {
    final api = _FakeItineraryApi();
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    final container = tester.widget<Container>(
      find
          .ancestor(
            of: find.byType(DayPillStrip),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.surface);
    expect(decoration.border!.top.color, AppColors.muted);
  });

  testWidgets('highlights the active day tab when switching days', (
    tester,
  ) async {
    final api = _FakeItineraryApi();
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    Color tabColor(String label) {
      final container = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text(label),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      return (container.decoration as BoxDecoration).color!;
    }

    expect(tabColor('Día 1 · 01 Jun'), AppColors.primaryDeep);
    expect(tabColor('Día 2 · 02 Jun'), AppColors.muted.withValues(alpha: 0.6));

    await tester.tap(find.text('Día 2 · 02 Jun'));
    await tester.pumpAndSettle();

    expect(tabColor('Día 1 · 01 Jun'), AppColors.muted.withValues(alpha: 0.6));
    expect(tabColor('Día 2 · 02 Jun'), AppColors.primaryDeep);
  });

  testWidgets('single-day trip shows one tab', (tester) async {
    final trip = _trip(start: DateTime(2026, 6, 1), end: DateTime(2026, 6, 1));
    final api = _FakeItineraryApi();
    final controller = await _controllerWith(api, trip);
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: trip),
    );
    await tester.pumpAndSettle();

    final strip = tester.widget<DayPillStrip>(find.byType(DayPillStrip));
    expect(strip.days, hasLength(1));
    expect(find.text('Día 1 · 01 Jun'), findsOneWidget);
  });

  testWidgets('shows empty states for general list and slots', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final api = _FakeItineraryApi();
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Añade lugares al viaje'), findsNothing);
    // The FAB is the single add affordance on this screen.
    expect(find.text('Añadir lugar'), findsOneWidget);
    // Tests run on the Android target platform, so the hint names the
    // long-press gesture.
    expect(
      find.text('Mantén pulsado y arrastra lugares aquí'),
      findsNWidgets(3),
    );
  });

  testWidgets('dragging a general card to a slot moves it (no copy)', (
    tester,
  ) async {
    final api = _FakeItineraryApi(
      items: [_item(1, position: 0), _item(2, position: 1)],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    await _dragCard(
      tester,
      find.text('Lugar 1'),
      tester.getCenter(find.text('Mañana')),
    );

    expect(api.moveCalls, [1]);
    expect(api.movePayloads.single.dayDate, DateTime(2026, 6, 1));
    expect(api.movePayloads.single.slot, ItinerarySlot.morning);
    expect(api.movePayloads.single.position, 0);

    // La general queda solo con el lugar 2; la franja muestra el 1.
    final generalSection = find.byType(GeneralItemsSection);
    expect(
      find.descendant(of: generalSection, matching: find.text('Lugar 1')),
      findsNothing,
    );
    expect(
      find.descendant(of: generalSection, matching: find.text('Lugar 2')),
      findsOneWidget,
    );
    expect(find.text('Lugar 1'), findsOneWidget);
  });

  testWidgets('dropping on another day tab moves to that day morning', (
    tester,
  ) async {
    final api = _FakeItineraryApi(items: [_item(1, position: 0)]);
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    await _dragCard(
      tester,
      find.text('Lugar 1'),
      tester.getCenter(find.text('Día 3 · 03 Jun')),
    );

    expect(api.moveCalls, [1]);
    expect(api.movePayloads.single.dayDate, DateTime(2026, 6, 3));
    expect(api.movePayloads.single.slot, ItinerarySlot.morning);
  });

  testWidgets('hovering a day tab while dragging opens that day', (
    tester,
  ) async {
    final api = _FakeItineraryApi(items: [_item(1, position: 0)]);
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Lugar 1')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(tester.getCenter(find.text('Día 3 · 03 Jun')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_tabIndex(tester), 0);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(_tabIndex(tester), 2);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('crossing a day tab quickly does not switch days', (
    tester,
  ) async {
    final api = _FakeItineraryApi(items: [_item(1, position: 0)]);
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    final origin = tester.getCenter(find.text('Lugar 1'));
    final gesture = await tester.startGesture(origin);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(tester.getCenter(find.text('Día 5 · 05 Jun')));
    await tester.pump();
    await gesture.moveTo(origin);
    await tester.pump(const Duration(milliseconds: 700));
    expect(_tabIndex(tester), 0);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('trash button removes the item', (tester) async {
    final api = _FakeItineraryApi(items: [_item(1, position: 0)]);
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(api.removeCalls, [1]);
    // Empty general section: the hint speaks for itself, the FAB adds.
    expect(
      find.text('Todavía no hay lugares por asignar. ¿Añadimos uno?'),
      findsOneWidget,
    );
  });

  testWidgets('removing shows a snackbar and Deshacer restores the placement', (
    tester,
  ) async {
    final api = _FakeItineraryApi(
      items: [
        _item(
          1,
          position: 0,
          day: DateTime(2026, 6, 1),
          slot: ItinerarySlot.afternoon,
        ),
      ],
      createdItem: _item(9, position: 0),
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('"Lugar 1" quitado del itinerario'), findsOneWidget);
    expect(find.text('Deshacer'), findsOneWidget);

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();

    // Undo re-creates the instance and asks the server to place it back in
    // the same day and slot it occupied.
    expect(api.addCalls, [1]);
    expect(api.moveCalls, [9]);
    expect(api.movePayloads.single.dayDate, DateTime(2026, 6, 1));
    expect(api.movePayloads.single.slot, ItinerarySlot.afternoon);
  });

  testWidgets('shows the offline banner when offline', (tester) async {
    final api = _FakeItineraryApi();
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(
        controller: controller,
        places: places,
        trip: _trip(),
        online: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión con el servidor'), findsOneWidget);
    final banner = tester.getTopLeft(find.byType(OfflineBanner));
    final strip = tester.getTopLeft(find.byType(DayPillStrip));
    expect(banner.dy, lessThan(strip.dy));
  });

  testWidgets(
    'add-place FAB opens the picker and adding calls the controller',
    (tester) async {
      final api = _FakeItineraryApi(
        items: const [],
        createdItem: _item(9, position: 0),
      );
      final controller = await _controllerWith(api, _trip());
      addTearDown(controller.dispose);
      final places = await _placesWith([_place(1), _place(2)]);
      addTearDown(places.dispose);

      await tester.pumpWidget(
        _wrap(controller: controller, places: places, trip: _trip()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Añadir lugar'));
      await tester.pumpAndSettle();
      expect(find.byType(PlacePickerDialog), findsOneWidget);

      await tester.tap(find.text('Lugar 1'));
      await tester.pumpAndSettle();

      expect(api.addCalls, [1]);
    },
  );

  testWidgets('shows a thumb-zone FAB that opens the picker', (tester) async {
    final api = _FakeItineraryApi();
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([_place(1), _place(2)]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.heroTag, 'itinerary-add-fab');
    expect(find.text('Añadir lugar'), findsOneWidget);

    await tester.tap(find.text('Añadir lugar'));
    await tester.pumpAndSettle();
    expect(find.byType(PlacePickerDialog), findsOneWidget);

    // The general picker adds without a target: no day/slot subtitle.
    expect(find.text('Mañana · Día 1 · 01 Jun'), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Lugar 1'),
      ),
    );
    await tester.pumpAndSettle();
    expect(api.addCalls, [1]);
  });

  testWidgets('picker stays open to add several places in a row', (
    tester,
  ) async {
    final api = _FakeItineraryApi(items: const []);
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([_place(1), _place(2)]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Añadir lugar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lugar 1'));
    await tester.pumpAndSettle();
    expect(find.byType(PlacePickerDialog), findsOneWidget);

    await tester.tap(find.text('Lugar 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    expect(api.addCalls, [1, 2]);
    final generalSection = find.byType(GeneralItemsSection);
    expect(
      find.descendant(of: generalSection, matching: find.text('Lugar 1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: generalSection, matching: find.text('Lugar 2')),
      findsOneWidget,
    );
  });

  testWidgets('shows a snackbar when the autosave move fails', (tester) async {
    final api = _FakeItineraryApi(
      items: [_item(1, position: 0)],
      moveError: Exception('boom'),
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    await _dragCard(
      tester,
      find.text('Lugar 1'),
      tester.getCenter(find.text('Mañana')),
    );

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('No se pudo guardar'), findsOneWidget);
  });

  testWidgets('tapping the last day of a long trip selects and highlights it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(4000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final trip = _trip(start: DateTime(2026, 6, 1), end: DateTime(2026, 6, 14));
    final api = _FakeItineraryApi();
    final controller = await _controllerWith(api, trip);
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: trip),
    );
    await tester.pumpAndSettle();

    // On a wide window the pill strip lives in the right column, which is
    // narrower than the full viewport: reveal the last pill before tapping.
    final stripScrollable = find.descendant(
      of: find.byType(DayPillStrip),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Día 14 · 14 Jun'),
      100,
      scrollable: stripScrollable,
    );
    await tester.tap(find.text('Día 14 · 14 Jun'));
    await tester.pumpAndSettle();

    expect(_tabIndex(tester), 13);
    final container = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('Día 14 · 14 Jun'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect(
      (container.decoration as BoxDecoration).color,
      AppColors.primaryDeep,
    );
  });

  testWidgets('uses the stacked layout below the 900dp breakpoint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final api = _FakeItineraryApi(items: [_item(1, position: 0)]);
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ItineraryTwoColumnLayout), findsNothing);
    final strip = tester.getTopLeft(find.byType(DayPillStrip));
    final general = tester.getTopLeft(find.byType(GeneralItemsSection));
    final timeline = tester.getTopLeft(find.byType(TabBarView));
    expect(strip.dy, lessThan(general.dy));
    expect(general.dy, lessThan(timeline.dy));
    final stripWidget = tester.widget<DayPillStrip>(find.byType(DayPillStrip));
    expect(stripWidget.centered, isFalse);
  });

  testWidgets('on wide screens the day strip spans the page above both '
      'columns', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final api = _FakeItineraryApi(items: [_item(1, position: 0)]);
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ItineraryTwoColumnLayout), findsOneWidget);
    expect(find.byType(GeneralItemsSection), findsOneWidget);
    final general = tester.getRect(find.byType(GeneralItemsSection));
    final timeline = tester.getRect(find.byType(TabBarView));
    final strip = tester.getRect(find.byType(DayPillStrip));
    final layout = tester.getRect(find.byType(ItineraryTwoColumnLayout));
    expect(strip.bottom, lessThanOrEqualTo(layout.top));
    expect(strip.left, 0);
    expect(strip.width, tester.view.physicalSize.width);
    expect(general.right, lessThanOrEqualTo(timeline.left));
    final stripWidget = tester.widget<DayPillStrip>(find.byType(DayPillStrip));
    expect(stripWidget.centered, isTrue);
    final section = tester.widget<GeneralItemsSection>(
      find.byType(GeneralItemsSection),
    );
    expect(section.layout, GeneralItemsLayout.vertical);
  });

  testWidgets('wide unassigned panel fills the column height instead of '
      'hugging its cards', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final api = _FakeItineraryApi(items: [_item(1, position: 0)]);
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    final general = tester.getRect(find.byType(GeneralItemsSection));
    final layout = tester.getRect(find.byType(ItineraryTwoColumnLayout));
    final card = tester.getRect(find.byType(ItineraryPlaceCard).first);
    expect(general.bottom, closeTo(layout.bottom, 1));
    expect(general.top, closeTo(layout.top, 1));
    expect(general.height, greaterThan(card.height * 2));
  });

  testWidgets('wide day timeline is centered vertically', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final api = _FakeItineraryApi(
      items: [_item(1, day: DateTime(2026, 6, 1), slot: ItinerarySlot.morning)],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    final timeline = tester.getRect(find.byType(TabBarView));
    final sections = find.byType(ItinerarySlotSection);
    final contentTop = tester.getRect(sections.first).top;
    final contentBottom = tester.getRect(sections.last).bottom;
    final contentCenter = (contentTop + contentBottom) / 2;
    expect((contentCenter - timeline.center.dy).abs(), lessThan(2));
  });

  testWidgets('stacked day timeline keeps its content top aligned', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final api = _FakeItineraryApi(
      items: [_item(1, day: DateTime(2026, 6, 1), slot: ItinerarySlot.morning)],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    final timeline = tester.getRect(find.byType(TabBarView));
    final sections = find.byType(ItinerarySlotSection);
    expect(tester.getRect(sections.first).top, closeTo(timeline.top, 1));
  });

  testWidgets('renders a single section and strip exactly at the 900dp '
      'breakpoint', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final api = _FakeItineraryApi(items: [_item(1, position: 0)]);
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ItineraryTwoColumnLayout), findsOneWidget);
    expect(find.byType(GeneralItemsSection), findsOneWidget);
    expect(find.byType(DayPillStrip), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide list renders one card per row at full width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(960, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final api = _FakeItineraryApi(
      items: [
        _item(1, position: 0),
        _item(2, position: 1),
        _item(3, position: 2),
      ],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    final cards = find.descendant(
      of: find.byType(GeneralItemsSection),
      matching: find.byType(ItineraryPlaceCard),
    );
    expect(cards, findsNWidgets(3));
    final row0 = tester.getTopLeft(cards.at(0)).dy;
    expect(tester.getTopLeft(cards.at(1)).dy, greaterThan(row0));
    expect(
      tester.getTopLeft(cards.at(2)).dy,
      greaterThan(tester.getTopLeft(cards.at(1)).dy),
    );
    final width0 = tester.getSize(cards.at(0)).width;
    expect(tester.getSize(cards.at(1)).width, width0);
    expect(tester.getSize(cards.at(2)).width, width0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide drag from the grid to the timeline moves the item', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final api = _FakeItineraryApi(
      items: [_item(1, position: 0), _item(2, position: 1)],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    await _dragCard(
      tester,
      find.text('Lugar 1'),
      tester.getCenter(find.text('Mañana')),
    );

    expect(api.moveCalls, [1]);
    expect(api.movePayloads.single.dayDate, DateTime(2026, 6, 1));
    expect(api.movePayloads.single.slot, ItinerarySlot.morning);
    expect(api.movePayloads.single.position, 0);
  });

  testWidgets('wide drag inside a day section reorders and clears the '
      'preview', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final day = DateTime(2026, 6, 1);
    final api = _FakeItineraryApi(
      items: [
        _item(1, position: 0, day: day, slot: ItinerarySlot.morning),
        _item(2, position: 1, day: day, slot: ItinerarySlot.morning),
      ],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    const placeholder = ValueKey('itinerary-drop-placeholder');
    final cards = find.descendant(
      of: find.byType(ItinerarySlotSection).first,
      matching: find.byType(ItineraryPlaceCard),
    );

    final gesture = await _startDrag(
      tester,
      cards.at(1),
      tester.getCenter(cards.at(0)),
    );

    // La sesión llega a la sección de la columna derecha a través del layout.
    expect(find.byKey(placeholder), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(api.moveCalls, [2]);
    expect(api.movePayloads.single.dayDate, day);
    expect(api.movePayloads.single.slot, ItinerarySlot.morning);
    expect(api.movePayloads.single.position, 0);
    expect(find.byKey(placeholder), findsNothing);
  });

  testWidgets('wide drag from the timeline back to the grid unassigns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final api = _FakeItineraryApi(
      items: [
        _item(
          1,
          position: 0,
          day: DateTime(2026, 6, 1),
          slot: ItinerarySlot.morning,
        ),
      ],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    await _dragCard(
      tester,
      find.text('Lugar 1'),
      tester.getCenter(find.byType(GeneralItemsSection)),
    );

    expect(api.moveCalls, [1]);
    expect(api.movePayloads.single.dayDate, isNull);
    expect(api.movePayloads.single.slot, isNull);
    expect(api.movePayloads.single.position, 0);
  });

  testWidgets('wide hovering a day pill while dragging opens that day', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final api = _FakeItineraryApi(items: [_item(1, position: 0)]);
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Lugar 1')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(tester.getCenter(find.text('Día 3 · 03 Jun')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_tabIndex(tester), 0);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(_tabIndex(tester), 2);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('wide dragging a night card over the first one reorders it '
      'with the preview on the target (EJ-1, AC-2)', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final day = DateTime(2026, 6, 3);
    final api = _FakeItineraryApi(
      items: [
        _item(1, position: 0, day: day, slot: ItinerarySlot.night),
        _item(2, position: 1, day: day, slot: ItinerarySlot.night),
      ],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Día 3 · 03 Jun'));
    await tester.pumpAndSettle();

    final nightSection = find.ancestor(
      of: find.text('Noche'),
      matching: find.byType(ItinerarySlotSection),
    );
    final cards = find.descendant(
      of: nightSection,
      matching: find.byType(ItineraryPlaceCard),
    );

    const placeholder = ValueKey('itinerary-drop-placeholder');
    final gesture = await _startDrag(
      tester,
      cards.at(1),
      tester.getCenter(cards.at(0)),
    );

    // AC-2: el hueco se ve en la posición destino, encima de la primera
    // tarjeta, mientras se arrastra.
    expect(find.byKey(placeholder), findsOneWidget);
    expect(
      tester.getCenter(find.byKey(placeholder)).dy,
      lessThan(tester.getCenter(find.text('Lugar 1')).dy),
    );

    await gesture.up();
    await tester.pumpAndSettle();

    expect(api.moveCalls, [2]);
    expect(api.movePayloads.single.dayDate, day);
    expect(api.movePayloads.single.slot, ItinerarySlot.night);
    expect(api.movePayloads.single.position, 0);
    expect(find.byKey(placeholder), findsNothing);
    // Noche queda [Lugar 2, Lugar 1].
    expect(
      tester.getCenter(find.text('Lugar 2')).dy,
      lessThan(tester.getCenter(find.text('Lugar 1')).dy),
    );
  });

  testWidgets('wide dragging the first morning card into the gap after the '
      'second one reorders it (EJ-2)', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final day = DateTime(2026, 6, 1);
    final api = _FakeItineraryApi(
      items: [
        _item(1, position: 0, day: day, slot: ItinerarySlot.morning),
        _item(2, position: 1, day: day, slot: ItinerarySlot.morning),
        _item(3, position: 2, day: day, slot: ItinerarySlot.morning),
      ],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    final morningSection = find.ancestor(
      of: find.text('Mañana'),
      matching: find.byType(ItinerarySlotSection),
    );
    final cards = find.descendant(
      of: morningSection,
      matching: find.byType(ItineraryPlaceCard),
    );
    expect(cards, findsNWidgets(3));

    // Punto medio entre la 2ª y la 3ª tarjeta: dos centros quedan por encima
    // del drop, así que el índice "insertar antes" es 2.
    Offset gap() => Offset(
      tester.getCenter(cards.at(0)).dx,
      (tester.getCenter(cards.at(1)).dy + tester.getCenter(cards.at(2)).dy) / 2,
    );

    final gesture = await _startDrag(tester, cards.at(0), gap());
    for (var attempt = 0; attempt < 3; attempt++) {
      await gesture.moveTo(gap());
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(api.moveCalls, [1]);
    expect(api.movePayloads.single.dayDate, day);
    expect(api.movePayloads.single.slot, ItinerarySlot.morning);
    expect(api.movePayloads.single.position, 2);
    // Mañana queda [Lugar 2, Lugar 1, Lugar 3].
    expect(
      tester.getCenter(find.text('Lugar 2')).dy,
      lessThan(tester.getCenter(find.text('Lugar 1')).dy),
    );
    expect(
      tester.getCenter(find.text('Lugar 1')).dy,
      lessThan(tester.getCenter(find.text('Lugar 3')).dy),
    );
  });

  testWidgets('wide dropping a general card on a night card inserts it '
      'before that card (EJ-4)', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final day = DateTime(2026, 6, 3);
    final api = _FakeItineraryApi(
      items: [
        _item(1, position: 0),
        _item(2, position: 0, day: day, slot: ItinerarySlot.night),
      ],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Día 3 · 03 Jun'));
    await tester.pumpAndSettle();

    final nightSection = find.ancestor(
      of: find.text('Noche'),
      matching: find.byType(ItinerarySlotSection),
    );
    final nightCard = find.descendant(
      of: nightSection,
      matching: find.byType(ItineraryPlaceCard),
    );

    await _dragCard(
      tester,
      find.descendant(
        of: find.byType(GeneralItemsSection),
        matching: find.text('Lugar 1'),
      ),
      tester.getCenter(nightCard),
    );

    expect(api.moveCalls, [1]);
    expect(api.movePayloads.single.dayDate, day);
    expect(api.movePayloads.single.slot, ItinerarySlot.night);
    // Insertado antes de la tarjeta destino, no al final.
    expect(api.movePayloads.single.position, 0);
  });

  testWidgets('wide dropping a general card below the last one appends it '
      '(EJ-5)', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final api = _FakeItineraryApi(
      items: [_item(1, position: 0), _item(2, position: 1)],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    final general = find.byType(GeneralItemsSection);
    final cards = find.descendant(
      of: general,
      matching: find.byType(ItineraryPlaceCard),
    );
    expect(cards, findsNWidgets(2));

    // Zona vacía por debajo de la última tarjeta: todos los centros quedan por
    // encima del drop, así que el índice "insertar antes" es `items.length`.
    Offset belowLast() => Offset(
      tester.getCenter(cards.at(1)).dx,
      tester.getBottomLeft(cards.at(1)).dy + 24,
    );

    final gesture = await _startDrag(tester, cards.at(0), belowLast());
    for (var attempt = 0; attempt < 3; attempt++) {
      await gesture.moveTo(belowLast());
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(api.moveCalls, [1]);
    expect(api.movePayloads.single.dayDate, isNull);
    expect(api.movePayloads.single.slot, isNull);
    expect(api.movePayloads.single.position, 2);
    // La general queda [Lugar 2, Lugar 1].
    expect(
      tester.getCenter(find.text('Lugar 2')).dy,
      lessThan(tester.getCenter(find.text('Lugar 1')).dy),
    );
  });

  testWidgets('wide dropping a night card on its own place does nothing '
      '(EJ-6)', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final day = DateTime(2026, 6, 3);
    final api = _FakeItineraryApi(
      items: [
        _item(1, position: 0, day: day, slot: ItinerarySlot.night),
        _item(2, position: 1, day: day, slot: ItinerarySlot.night),
      ],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Día 3 · 03 Jun'));
    await tester.pumpAndSettle();

    final card = find.descendant(
      of: find.ancestor(
        of: find.text('Noche'),
        matching: find.byType(ItinerarySlotSection),
      ),
      matching: find.byType(ItineraryPlaceCard),
    );
    await _dragCard(tester, card.first, tester.getCenter(card.first));

    expect(api.moveCalls, isEmpty);
    expect(
      tester.getCenter(find.text('Lugar 1')).dy,
      lessThan(tester.getCenter(find.text('Lugar 2')).dy),
    );
  });

  testWidgets('wide a single-item section can send its card away and back '
      '(CC-3)', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final day = DateTime(2026, 6, 1);
    final api = _FakeItineraryApi(
      items: [_item(1, position: 0, day: day, slot: ItinerarySlot.morning)],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    Finder section(String title) => find.ancestor(
      of: find.text(title),
      matching: find.byType(ItinerarySlotSection),
    );

    // Mañana (solo el lugar 1) -> Noche vacía: se añade al final (índice 0).
    await _dragCard(
      tester,
      find.text('Lugar 1'),
      tester.getCenter(
        find.descendant(
          of: section('Noche'),
          matching: find.text('Mantén pulsado y arrastra lugares aquí'),
        ),
      ),
    );

    expect(api.movePayloads.first.slot, ItinerarySlot.night);
    expect(api.movePayloads.first.position, 0);

    // De vuelta a la Mañana, ahora vacía: índice 0 y orden restaurado.
    await _dragCard(
      tester,
      find.text('Lugar 1'),
      tester.getCenter(
        find.descendant(
          of: section('Mañana'),
          matching: find.text('Mantén pulsado y arrastra lugares aquí'),
        ),
      ),
    );

    expect(api.moveCalls, [1, 1]);
    expect(api.movePayloads.last.dayDate, day);
    expect(api.movePayloads.last.slot, ItinerarySlot.morning);
    expect(api.movePayloads.last.position, 0);
  });

  testWidgets('wide two consecutive night drags produce one move each '
      '(CC-4)', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final day = DateTime(2026, 6, 3);
    final api = _FakeItineraryApi(
      items: [
        _item(1, position: 0, day: day, slot: ItinerarySlot.night),
        _item(2, position: 1, day: day, slot: ItinerarySlot.night),
        _item(3, position: 2, day: day, slot: ItinerarySlot.night),
      ],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Día 3 · 03 Jun'));
    await tester.pumpAndSettle();

    Finder nightCards() => find.descendant(
      of: find.ancestor(
        of: find.text('Noche'),
        matching: find.byType(ItinerarySlotSection),
      ),
      matching: find.byType(ItineraryPlaceCard),
    );

    // Lugar 3 al principio: [3, 1, 2].
    await _dragOnto(tester, nightCards().last, nightCards().first);
    // Lugar 2 (ahora último) al principio: [2, 3, 1].
    await _dragOnto(tester, nightCards().last, nightCards().first);

    expect(api.moveCalls, [3, 2]);
    expect(api.movePayloads.map((move) => move.position), [0, 0]);
    expect(
      api.movePayloads.every((move) => move.slot == ItinerarySlot.night),
      isTrue,
    );
    expect(
      tester.getCenter(find.text('Lugar 2')).dy,
      lessThan(tester.getCenter(find.text('Lugar 3')).dy),
    );
    expect(
      tester.getCenter(find.text('Lugar 3')).dy,
      lessThan(tester.getCenter(find.text('Lugar 1')).dy),
    );
  });

  testWidgets('wide a failing move rolls the night order back (EJ-8)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final day = DateTime(2026, 6, 3);
    final api = _FakeItineraryApi(
      items: [
        _item(1, position: 0, day: day, slot: ItinerarySlot.night),
        _item(2, position: 1, day: day, slot: ItinerarySlot.night),
      ],
      moveError: Exception('boom'),
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Día 3 · 03 Jun'));
    await tester.pumpAndSettle();

    final nightCards = find.descendant(
      of: find.ancestor(
        of: find.text('Noche'),
        matching: find.byType(ItinerarySlotSection),
      ),
      matching: find.byType(ItineraryPlaceCard),
    );

    await _dragOnto(tester, nightCards.last, nightCards.first);

    expect(
      find.text('No se pudo guardar el cambio. Revisa tu conexión.'),
      findsOneWidget,
    );
    // Rollback: la vista vuelve al orden previo.
    expect(
      tester.getCenter(find.text('Lugar 1')).dy,
      lessThan(tester.getCenter(find.text('Lugar 2')).dy),
    );
  });

  testWidgets('wide the new night order comes back when reopening the '
      'itinerary (EJ-7)', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final day = DateTime(2026, 6, 3);
    final api = _FakeItineraryApi(
      items: [
        _item(1, position: 0, day: day, slot: ItinerarySlot.night),
        _item(2, position: 1, day: day, slot: ItinerarySlot.night),
      ],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Día 3 · 03 Jun'));
    await tester.pumpAndSettle();

    Finder nightCards() => find.descendant(
      of: find.ancestor(
        of: find.text('Noche'),
        matching: find.byType(ItinerarySlotSection),
      ),
      matching: find.byType(ItineraryPlaceCard),
    );

    await _dragOnto(tester, nightCards().last, nightCards().first);
    expect(api.moveCalls, [2]);

    // El servidor aplica el PATCH: al reabrir el itinerario la verdad viene
    // de la API, no del estado optimista anterior.
    api.items = [
      _item(2, position: 0, day: day, slot: ItinerarySlot.night),
      _item(1, position: 1, day: day, slot: ItinerarySlot.night),
    ];
    final reopened = await _controllerWith(api, _trip());
    addTearDown(reopened.dispose);
    await tester.pumpWidget(
      _wrap(controller: reopened, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Día 3 · 03 Jun'));
    await tester.pumpAndSettle();

    expect(nightCards(), findsNWidgets(2));
    expect(
      tester.getCenter(find.text('Lugar 2')).dy,
      lessThan(tester.getCenter(find.text('Lugar 1')).dy),
    );
  });

  testWidgets('resizing across the breakpoint keeps the selected day', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final api = _FakeItineraryApi(items: [_item(1, position: 0)]);
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);
    final trip = _trip();

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: trip),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Día 2 · 02 Jun'));
    await tester.pumpAndSettle();
    expect(_tabIndex(tester), 1);

    tester.view.physicalSize = const Size(1600, 1200);
    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: trip),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ItineraryTwoColumnLayout), findsOneWidget);
    expect(_tabIndex(tester), 1);
    expect(find.text('Lugar 1'), findsOneWidget);
  });

  testWidgets('14-day trip on mobile keeps the pills scrollable without '
      'overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final trip = _trip(start: DateTime(2026, 6, 1), end: DateTime(2026, 6, 14));
    final api = _FakeItineraryApi();
    final controller = await _controllerWith(api, trip);
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: trip),
    );
    await tester.pumpAndSettle();

    final stripScrollable = find.descendant(
      of: find.byType(DayPillStrip),
      matching: find.byType(Scrollable),
    );
    expect(stripScrollable, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed load shows an explicit error state, not an empty '
      'plan', (tester) async {
    final api = _FakeItineraryApi(loadError: Exception('boom'));
    final controller = ItineraryController(api);
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se pudo cargar el itinerario'), findsOneWidget);
    expect(find.text('Comprueba tu conexión con el servidor.'), findsOneWidget);
    // The failure must not read as an empty itinerary.
    expect(find.text('Mantén pulsado y arrastra lugares aquí'), findsNothing);
    expect(
      find.text('Todavía no hay lugares por asignar. ¿Añadimos uno?'),
      findsNothing,
    );

    api.loadError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo cargar el itinerario'), findsNothing);
    expect(
      find.text('Todavía no hay lugares por asignar. ¿Añadimos uno?'),
      findsOneWidget,
    );
  });

  testWidgets('day pills show how many items each day holds', (tester) async {
    final api = _FakeItineraryApi(
      items: [
        _item(
          1,
          position: 0,
          day: DateTime(2026, 6, 1),
          slot: ItinerarySlot.morning,
        ),
        _item(
          2,
          position: 0,
          day: DateTime(2026, 6, 1),
          slot: ItinerarySlot.afternoon,
        ),
        _item(
          3,
          position: 0,
          day: DateTime(2026, 6, 2),
          slot: ItinerarySlot.morning,
        ),
      ],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Día 1 · 01 Jun'), findsOneWidget);
    expect(find.text('Día 2 · 02 Jun'), findsOneWidget);
    expect(find.text('Día 3 · 03 Jun'), findsOneWidget);
    // Counts render as small badges instead of a third "· N" text segment.
    expect(find.text('Día 1 · 01 Jun · 2'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('tapping a card opens the move sheet and moving calls the '
      'controller', (tester) async {
    final api = _FakeItineraryApi(items: [_item(1, position: 0)]);
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lugar 1'));
    await tester.pumpAndSettle();

    expect(find.text('Mover "Lugar 1"'), findsOneWidget);

    // Unassigned item: the slots target the selected day.
    final sheet = find.byType(BottomSheet);
    await tester.tap(find.descendant(of: sheet, matching: find.text('Mañana')));
    await tester.pumpAndSettle();

    expect(api.moveCalls, [1]);
    expect(api.movePayloads.single.dayDate, DateTime(2026, 6, 1));
    expect(api.movePayloads.single.slot, ItinerarySlot.morning);
  });

  testWidgets('the move sheet can retarget the day before moving', (
    tester,
  ) async {
    final api = _FakeItineraryApi(items: [_item(1, position: 0)]);
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lugar 1'));
    await tester.pumpAndSettle();

    // Unassigned item: slots target the current tab day by default; the
    // selector on top retargets them to any day without a drag.
    final sheet = find.byType(BottomSheet);
    await tester.tap(
      find.descendant(of: sheet, matching: find.text('Día 3 · 03 Jun')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: sheet, matching: find.text('Noche')));
    await tester.pumpAndSettle();

    expect(api.moveCalls, [1]);
    expect(api.movePayloads.single.dayDate, DateTime(2026, 6, 3));
    expect(api.movePayloads.single.slot, ItinerarySlot.night);
  });

  testWidgets('the move sheet marks the current slot as already there', (
    tester,
  ) async {
    final api = _FakeItineraryApi(
      items: [
        _item(
          1,
          position: 0,
          day: DateTime(2026, 6, 1),
          slot: ItinerarySlot.morning,
        ),
      ],
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lugar 1'));
    await tester.pumpAndSettle();

    expect(find.text('Ya está en este bloque'), findsOneWidget);
    expect(find.text('Por asignar'), findsOneWidget);
  });

  testWidgets('tapping an empty slot opens the picker pre-targeted to it', (
    tester,
  ) async {
    final api = _FakeItineraryApi(items: const [], createdItem: _item(9));
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([_place(1)]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    // Three empty drop zones (morning, afternoon, night); tap the first.
    await tester.tap(find.text('Mantén pulsado y arrastra lugares aquí').first);
    await tester.pumpAndSettle();
    expect(find.byType(PlacePickerDialog), findsOneWidget);
    // The subtitle names where the picked places will land.
    expect(find.text('Mañana · Día 1 · 01 Jun'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Lugar 1'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    expect(api.addCalls, [1]);
    expect(api.moveCalls, [9]);
    expect(api.movePayloads.single.dayDate, DateTime(2026, 6, 1));
    expect(api.movePayloads.single.slot, ItinerarySlot.morning);
  });

  testWidgets('the failure snackbar persists and Reintentar saves the move', (
    tester,
  ) async {
    final api = _FakeItineraryApi(
      items: [_item(1, position: 0)],
      moveError: Exception('boom'),
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    await _dragCard(
      tester,
      find.text('Lugar 1'),
      tester.getCenter(find.text('Mañana')),
    );

    expect(
      find.text('No se pudo guardar el cambio. Revisa tu conexión.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);

    api.moveError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(api.moveCalls, [1]);
    expect(api.movePayloads.single.dayDate, DateTime(2026, 6, 1));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('the picker allows adding the same place twice', (tester) async {
    final api = _FakeItineraryApi(
      items: [_item(1, position: 0)],
      createdItem: _item(9, position: 1),
    );
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([_place(1)]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Añadir lugar'));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    // Visiting the same spot twice is a legitimate plan: the picker must
    // not block repeated adds.
    await tester.tap(
      find.descendant(of: dialog, matching: find.text('Lugar 1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: dialog, matching: find.text('Lugar 1')),
    );
    await tester.pumpAndSettle();

    expect(api.addCalls, [1, 1]);
    expect(find.text('2 añadidos'), findsOneWidget);
  });

  testWidgets('shows the saving indicator while a mutation is in flight', (
    tester,
  ) async {
    final api = _FakeItineraryApi(items: [_item(1, position: 0)])
      ..hangMove = Completer<void>();
    final controller = await _controllerWith(api, _trip());
    addTearDown(controller.dispose);
    final places = await _placesWith([]);
    addTearDown(places.dispose);

    await tester.pumpWidget(
      _wrap(controller: controller, places: places, trip: _trip()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Guardando cambios'), findsNothing);

    final future = controller.moveItem(
      1,
      DateTime(2026, 6, 1),
      ItinerarySlot.morning,
      0,
    );
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Guardando cambios'), findsOneWidget);

    api.hangMove!.complete();
    await future;
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
