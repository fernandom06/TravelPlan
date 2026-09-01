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
import 'package:frontend/presentation/widgets/dashed_action_card.dart';
import 'package:frontend/presentation/widgets/day_pill_strip.dart';
import 'package:frontend/presentation/widgets/general_items_section.dart';
import 'package:frontend/presentation/widgets/itinerary_place_card.dart';
import 'package:frontend/presentation/widgets/itinerary_two_column_layout.dart';
import 'package:frontend/presentation/widgets/offline_banner.dart';
import 'package:frontend/presentation/widgets/place_picker_dialog.dart';

class _FakeItineraryApi extends ItineraryApi {
  _FakeItineraryApi({this.items = const [], this.createdItem, this.moveError})
    : super(baseUrl: 'http://fake');

  final List<ItineraryItem> items;
  final ItineraryItem? createdItem;
  final Object? moveError;

  final List<int> moveCalls = [];
  final List<ItineraryMove> movePayloads = [];
  final List<int> addCalls = [];
  final List<int> removeCalls = [];

  @override
  Future<List<ItineraryItem>> fetchItinerary(String tripId) async => items;

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

Future<void> _dragCard(WidgetTester tester, Finder card, Offset to) async {
  final gesture = await tester.startGesture(tester.getCenter(card));
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
  await gesture.moveTo(to);
  await tester.pump();
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

    expect(tabColor('Día 1 · 01 Jun'), AppColors.primary);
    expect(tabColor('Día 2 · 02 Jun'), AppColors.muted.withValues(alpha: 0.6));

    await tester.tap(find.text('Día 2 · 02 Jun'));
    await tester.pumpAndSettle();

    expect(tabColor('Día 1 · 01 Jun'), AppColors.muted.withValues(alpha: 0.6));
    expect(tabColor('Día 2 · 02 Jun'), AppColors.primary);
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
    expect(find.text('¿Añadimos un lugar?'), findsOneWidget);
    expect(find.text('Arrastra lugares aquí'), findsNWidgets(3));
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
    expect(find.text('Añade lugares al viaje'), findsNothing);
    expect(find.text('¿Añadimos un lugar?'), findsOneWidget);
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
    'add-place card opens the picker and adding calls the controller',
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

      await tester.tap(find.text('¿Añadimos un lugar?'));
      await tester.pumpAndSettle();
      expect(find.byType(PlacePickerDialog), findsOneWidget);

      await tester.tap(find.text('Lugar 1'));
      await tester.pumpAndSettle();

      expect(api.addCalls, [1]);
    },
  );

  testWidgets('itinerary screen shows no floating action button', (
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

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('¿Añadimos un lugar?'), findsOneWidget);
    expect(find.text('Añade lugares al viaje'), findsNothing);
    final sectionCenter = tester.getCenter(find.byType(GeneralItemsSection));
    final cardCenter = tester.getCenter(find.byType(DashedActionCard));
    expect((cardCenter.dx - sectionCenter.dx).abs(), lessThan(1));
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

    await tester.tap(find.text('¿Añadimos un lugar?'));
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
    expect((container.decoration as BoxDecoration).color, AppColors.primary);
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

  testWidgets('uses two columns with the vertical list on the left on wide '
      'screens', (tester) async {
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
    final strip = tester.getRect(find.byType(DayPillStrip));
    expect(general.right, lessThan(strip.left));
    final stripWidget = tester.widget<DayPillStrip>(find.byType(DayPillStrip));
    expect(stripWidget.centered, isTrue);
    final section = tester.widget<GeneralItemsSection>(
      find.byType(GeneralItemsSection),
    );
    expect(section.layout, GeneralItemsLayout.vertical);
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
}
