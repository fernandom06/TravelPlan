import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/itinerary_api.dart';
import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/itinerary_item.dart';
import 'package:frontend/data/models/itinerary_move.dart';
import 'package:frontend/data/models/itinerary_slot.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/data/models/trip.dart';
import 'package:frontend/presentation/controllers/itinerary_controller.dart';

Place _place(int id) => Place(
  id: id,
  name: 'Place $id',
  description: null,
  latitude: 42.5,
  longitude: -3.5,
  category: Category(id: 1, name: 'Naturaleza', icon: null),
);

ItineraryItem _item(
  int id, {
  required int position,
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

final _day1 = DateTime(2026, 6, 1);
final _day3 = DateTime(2026, 6, 3);

class _FakeItineraryApi extends ItineraryApi {
  _FakeItineraryApi({
    this.items = const [],
    this.fetchError,
    this.addError,
    this.moveError,
    this.removeError,
    this.addedItem,
  }) : super(baseUrl: 'http://fake');

  final List<ItineraryItem> items;
  final Object? fetchError;
  final Object? addError;
  final Object? moveError;
  final Object? removeError;
  final ItineraryItem? addedItem;

  int? addPlaceId;
  int? movedItemId;
  ItineraryMove? lastMove;
  int? removedItemId;

  @override
  Future<List<ItineraryItem>> fetchItinerary(String tripId) async {
    if (fetchError != null) throw fetchError!;
    return items;
  }

  @override
  Future<ItineraryItem> addPlace(String tripId, int placeId) async {
    if (addError != null) throw addError!;
    addPlaceId = placeId;
    return addedItem!;
  }

  @override
  Future<ItineraryItem> moveItem(
    String tripId,
    int itemId,
    ItineraryMove move,
  ) async {
    if (moveError != null) throw moveError!;
    movedItemId = itemId;
    lastMove = move;
    return items.firstWhere((i) => i.id == itemId);
  }

  @override
  Future<void> removeItem(String tripId, int itemId) async {
    if (removeError != null) throw removeError!;
    removedItemId = itemId;
  }
}

final _trip = Trip(
  id: 'abc',
  name: 'Viaje',
  description: null,
  startDate: DateTime(2026, 6, 1),
  endDate: DateTime(2026, 6, 10),
  imageUrl: null,
  createdAt: '2026-01-01',
);

void main() {
  group('computeMove', () {
    test('moves item from general list to a slot', () {
      final items = [_item(1, position: 0), _item(2, position: 1)];

      final result = computeMove(items, 1, _day1, ItinerarySlot.morning, 0);

      expect(result.map((i) => i.id), [2, 1]);
      final moved = result.firstWhere((i) => i.id == 1);
      expect(moved.dayDate, _day1);
      expect(moved.slot, ItinerarySlot.morning);
      expect(moved.position, 0);
      expect(result.firstWhere((i) => i.id == 2).position, 0);
    });

    test('moves item from a slot back to the general list', () {
      final items = [
        _item(1, position: 0, day: _day1, slot: ItinerarySlot.morning),
        _item(2, position: 0),
      ];

      final result = computeMove(items, 1, null, null, 0);

      final ids = result.map((i) => i.id).toList();
      expect(ids, [1, 2]);
      final moved = result.firstWhere((i) => i.id == 1);
      expect(moved.isUnassigned, isTrue);
      expect(moved.position, 0);
      expect(result.firstWhere((i) => i.id == 2).position, 1);
    });

    test('moves item between slots of different days', () {
      final items = [
        _item(1, position: 0, day: _day1, slot: ItinerarySlot.morning),
        _item(2, position: 0, day: _day3, slot: ItinerarySlot.night),
      ];

      final result = computeMove(items, 1, _day3, ItinerarySlot.night, 0);

      final ids = result.map((i) => i.id).toList();
      expect(ids, [1, 2]);
      final moved = result.firstWhere((i) => i.id == 1);
      expect(moved.dayDate, _day3);
      expect(moved.slot, ItinerarySlot.night);
      expect(moved.position, 0);
      expect(result.firstWhere((i) => i.id == 2).position, 1);
    });

    test(
      'reorders within a slot adjusting index when origin precedes target',
      () {
        final items = [
          _item(1, position: 0, day: _day1, slot: ItinerarySlot.morning),
          _item(2, position: 1, day: _day1, slot: ItinerarySlot.morning),
          _item(3, position: 2, day: _day1, slot: ItinerarySlot.morning),
        ];

        // Mover 1 (primera) a la posición 2: acaba tras 2, antes de 3.
        final result = computeMove(items, 1, _day1, ItinerarySlot.morning, 2);

        expect(result.map((i) => i.id), [2, 1, 3]);
        expect(result.map((i) => i.position), [0, 1, 2]);
      },
    );

    test('reorders within a slot when origin is after target', () {
      final items = [
        _item(1, position: 0, day: _day1, slot: ItinerarySlot.morning),
        _item(2, position: 1, day: _day1, slot: ItinerarySlot.morning),
        _item(3, position: 2, day: _day1, slot: ItinerarySlot.morning),
      ];

      // Mover 3 (última) a la posición 1: antes de 2.
      final result = computeMove(items, 3, _day1, ItinerarySlot.morning, 1);

      expect(result.map((i) => i.id), [1, 3, 2]);
      expect(result.map((i) => i.position), [0, 1, 2]);
    });

    test('moves into an empty target container', () {
      final items = [_item(1, position: 0), _item(2, position: 1)];

      final result = computeMove(items, 1, _day1, ItinerarySlot.afternoon, 3);

      final moved = result.firstWhere((i) => i.id == 1);
      expect(moved.dayDate, _day1);
      expect(moved.slot, ItinerarySlot.afternoon);
      expect(moved.position, 0);
    });

    test('clamps out-of-range target indices', () {
      final items = [
        _item(1, position: 0, day: _day1, slot: ItinerarySlot.morning),
        _item(2, position: 1, day: _day1, slot: ItinerarySlot.morning),
      ];

      // Índice mayor que la lista: al final.
      final toEnd = computeMove(items, 1, _day1, ItinerarySlot.morning, 99);
      expect(toEnd.map((i) => i.id), [2, 1]);

      // Índice negativo: al principio.
      final toStart = computeMove(items, 2, _day1, ItinerarySlot.morning, -5);
      expect(toStart.map((i) => i.id), [2, 1]);
    });

    test('keeps positions compacted in every container', () {
      final items = [
        _item(1, position: 0, day: _day1, slot: ItinerarySlot.morning),
        _item(2, position: 0, day: _day1, slot: ItinerarySlot.night),
        _item(3, position: 1, day: _day1, slot: ItinerarySlot.night),
        _item(4, position: 0),
      ];

      final result = computeMove(items, 3, _day1, ItinerarySlot.morning, 0);

      final morning = result
          .where((i) => i.slot == ItinerarySlot.morning)
          .map((i) => i.position)
          .toList();
      final night = result
          .where((i) => i.slot == ItinerarySlot.night)
          .map((i) => i.position)
          .toList();
      final general = result
          .where((i) => i.isUnassigned)
          .map((i) => i.position)
          .toList();
      expect(morning, [0, 1]);
      expect(night, [0]);
      expect(general, [0]);
    });
  });

  group('ItineraryController', () {
    test('loadItinerary populates items and trip', () async {
      final api = _FakeItineraryApi(items: [_item(1, position: 0)]);
      final controller = ItineraryController(api);
      addTearDown(controller.dispose);

      expect(controller.value.isLoading, isFalse);
      final future = controller.loadItinerary(_trip);
      expect(controller.value.isLoading, isTrue);

      await future;

      expect(controller.value.isLoading, isFalse);
      expect(controller.value.trip, _trip);
      expect(controller.value.items, [_item(1, position: 0)]);
    });

    test('loadItinerary propagates errors and resets isLoading', () async {
      final api = _FakeItineraryApi(fetchError: Exception('boom'));
      final controller = ItineraryController(api);
      addTearDown(controller.dispose);

      await expectLater(
        controller.loadItinerary(_trip),
        throwsA(isA<Exception>()),
      );

      expect(controller.value.isLoading, isFalse);
      expect(controller.value.items, isEmpty);
    });

    test('addPlace appends optimistically and POSTs the place id', () async {
      final created = _item(7, position: 0);
      final api = _FakeItineraryApi(addedItem: created);
      final controller = ItineraryController(api);
      addTearDown(controller.dispose);
      await controller.loadItinerary(_trip);

      final future = controller.addPlace(_place(1));
      final optimistic = controller.value.items;

      await future;

      expect(optimistic.last.place.name, 'Place 1');
      expect(optimistic.last.isUnassigned, isTrue);
      expect(api.addPlaceId, 1);
      expect(controller.value.items.last.id, 7);
    });

    test('addPlace rolls back when the POST fails', () async {
      final api = _FakeItineraryApi(addError: Exception('boom'));
      final controller = ItineraryController(api);
      addTearDown(controller.dispose);
      await controller.loadItinerary(_trip);

      await expectLater(
        controller.addPlace(_place(1)),
        throwsA(isA<Exception>()),
      );

      expect(controller.value.items, isEmpty);
    });

    test('moveItem applies the pure function and PATCHes', () async {
      final api = _FakeItineraryApi(
        items: [_item(1, position: 0), _item(2, position: 1)],
      );
      final controller = ItineraryController(api);
      addTearDown(controller.dispose);
      await controller.loadItinerary(_trip);

      final future = controller.moveItem(1, _day1, ItinerarySlot.morning, 0);
      final optimistic = controller.value.items;

      await future;

      final moved = optimistic.firstWhere((i) => i.id == 1);
      expect(moved.dayDate, _day1);
      expect(moved.slot, ItinerarySlot.morning);
      expect(api.movedItemId, 1);
      expect(api.lastMove!.dayDate, _day1);
      expect(api.lastMove!.slot, ItinerarySlot.morning);
      expect(api.lastMove!.position, 0);
    });

    test('moveItem rolls back and rethrows when the PATCH fails', () async {
      final api = _FakeItineraryApi(
        items: [_item(1, position: 0), _item(2, position: 1)],
        moveError: Exception('boom'),
      );
      final controller = ItineraryController(api);
      addTearDown(controller.dispose);
      await controller.loadItinerary(_trip);
      final before = controller.value.items;

      await expectLater(
        controller.moveItem(1, _day1, ItinerarySlot.morning, 0),
        throwsA(isA<Exception>()),
      );

      expect(controller.value.items, before);
      expect(controller.value.items.first.isUnassigned, isTrue);
    });

    test('removeItem removes optimistically and DELETEs', () async {
      final api = _FakeItineraryApi(
        items: [_item(1, position: 0), _item(2, position: 1)],
      );
      final controller = ItineraryController(api);
      addTearDown(controller.dispose);
      await controller.loadItinerary(_trip);

      final future = controller.removeItem(1);
      final optimistic = controller.value.items;

      await future;

      expect(optimistic.map((i) => i.id), [2]);
      expect(api.removedItemId, 1);
    });

    test('removeItem rolls back when the DELETE fails', () async {
      final api = _FakeItineraryApi(
        items: [_item(1, position: 0), _item(2, position: 1)],
        removeError: Exception('boom'),
      );
      final controller = ItineraryController(api);
      addTearDown(controller.dispose);
      await controller.loadItinerary(_trip);
      final before = controller.value.items;

      await expectLater(controller.removeItem(1), throwsA(isA<Exception>()));

      expect(controller.value.items, before);
    });

    test('reloading replaces items', () async {
      final api = _FakeItineraryApi(items: [_item(1, position: 0)]);
      final controller = ItineraryController(api);
      addTearDown(controller.dispose);
      await controller.loadItinerary(_trip);
      expect(controller.value.items.map((i) => i.id), [1]);

      api.items.add(_item(2, position: 1));
      await controller.loadItinerary(_trip);

      expect(controller.value.items.map((i) => i.id), [1, 2]);
    });
  });
}
