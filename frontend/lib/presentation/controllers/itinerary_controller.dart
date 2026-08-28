import 'package:flutter/foundation.dart' show ValueNotifier;

import '../../data/itinerary_api.dart';
import '../../data/models/itinerary_item.dart';
import '../../data/models/itinerary_move.dart';
import '../../data/models/itinerary_slot.dart';
import '../../data/models/place.dart';
import '../../data/models/trip.dart';

bool _sameContainer(ItineraryItem item, DateTime? day, ItinerarySlot? slot) =>
    item.dayDate == day && item.slot == slot;

int _containerCompare(ItineraryItem a, ItineraryItem b) {
  if (a.isUnassigned && b.isUnassigned) return 0;
  if (a.isUnassigned) return -1;
  if (b.isUnassigned) return 1;
  final dayCompare = a.dayDate!.compareTo(b.dayDate!);
  if (dayCompare != 0) return dayCompare;
  return a.slot!.index.compareTo(b.slot!.index);
}

ItineraryItem _copyWithPosition(ItineraryItem item, int position) =>
    ItineraryItem(
      id: item.id,
      dayDate: item.dayDate,
      slot: item.slot,
      position: position,
      place: item.place,
    );

/// Devuelve la lista nueva tras mover [itemId] al contenedor
/// ([targetDay], [targetSlot]) en [targetIndex] (índice "insertar antes").
///
/// Función pura: no muta la entrada. Compacta posiciones en origen y destino
/// y ajusta el índice al reordenar dentro del mismo contenedor cuando el
/// origen está antes del destino. Índices fuera de rango se clampean.
List<ItineraryItem> computeMove(
  List<ItineraryItem> items,
  int itemId,
  DateTime? targetDay,
  ItinerarySlot? targetSlot,
  int targetIndex,
) {
  final moving = items.firstWhere((item) => item.id == itemId);
  final others = items.where((item) => item.id != itemId).toList();

  // Compacta el origen: los items posteriores al movido bajan una posición.
  final shifted = [
    for (final item in others)
      if (_sameContainer(item, moving.dayDate, moving.slot) &&
          item.position > moving.position)
        _copyWithPosition(item, item.position - 1)
      else
        item,
  ];

  final targetCount = shifted
      .where((item) => _sameContainer(item, targetDay, targetSlot))
      .length;

  var insertIndex = targetIndex;
  if (_sameContainer(moving, targetDay, targetSlot) &&
      insertIndex > moving.position) {
    insertIndex -= 1;
  }
  insertIndex = insertIndex.clamp(0, targetCount);

  // Abre hueco en el destino desplazando hacia arriba desde el índice.
  final gapped = [
    for (final item in shifted)
      if (_sameContainer(item, targetDay, targetSlot) &&
          item.position >= insertIndex)
        _copyWithPosition(item, item.position + 1)
      else
        item,
  ];

  final moved = ItineraryItem(
    id: moving.id,
    dayDate: targetDay,
    slot: targetSlot,
    position: insertIndex,
    place: moving.place,
  );

  final combined = [...gapped, moved]..sort((a, b) {
    final container = _containerCompare(a, b);
    if (container != 0) return container;
    return a.position.compareTo(b.position);
  });
  return combined;
}

class ItineraryState {
  const ItineraryState({
    required this.trip,
    required this.items,
    required this.isLoading,
  });

  final Trip? trip;
  final List<ItineraryItem> items;
  final bool isLoading;
}

class ItineraryController extends ValueNotifier<ItineraryState> {
  ItineraryController(this._api)
    : super(const ItineraryState(trip: null, items: [], isLoading: false));

  final ItineraryApi _api;

  int _tempIdCounter = 0;

  int _nextTempId() => -(_tempIdCounter++ + 1);

  Future<void> loadItinerary(Trip trip) async {
    value = ItineraryState(
      trip: trip,
      items: value.items,
      isLoading: true,
    );
    try {
      final items = await _api.fetchItinerary(trip.id);
      value = ItineraryState(trip: trip, items: items, isLoading: false);
    } catch (_) {
      value = ItineraryState(
        trip: trip,
        items: value.items,
        isLoading: false,
      );
      rethrow;
    }
  }

  /// Añade un lugar al final de la lista general de forma optimista:
  /// aparece al instante y, si el POST falla, se revierte el cambio.
  Future<void> addPlace(Place place) async {
    final generalCount = value.items
        .where((item) => item.isUnassigned)
        .length;
    final tempId = _nextTempId();
    final tempItem = ItineraryItem(
      id: tempId,
      dayDate: null,
      slot: null,
      position: generalCount,
      place: place,
    );
    final previous = value;
    value = ItineraryState(
      trip: previous.trip,
      items: [...value.items, tempItem],
      isLoading: previous.isLoading,
    );
    try {
      final created = await _api.addPlace(_tripId, place.id);
      value = ItineraryState(
        trip: previous.trip,
        items: [
          for (final item in value.items)
            item.id == tempId ? created : item,
        ],
        isLoading: previous.isLoading,
      );
    } catch (_) {
      value = previous;
      rethrow;
    }
  }

  /// Mueve un item de forma optimista con la función pura y lo persiste.
  Future<void> moveItem(
    int itemId,
    DateTime? targetDay,
    ItinerarySlot? targetSlot,
    int targetIndex,
  ) async {
    final previous = value;
    final newItems = computeMove(
      value.items,
      itemId,
      targetDay,
      targetSlot,
      targetIndex,
    );
    value = ItineraryState(
      trip: previous.trip,
      items: newItems,
      isLoading: previous.isLoading,
    );
    try {
      await _api.moveItem(
        _tripId,
        itemId,
        ItineraryMove(
          dayDate: targetDay,
          slot: targetSlot,
          position: targetIndex,
        ),
      );
    } catch (_) {
      value = previous;
      rethrow;
    }
  }

  /// Borra una instancia de forma optimista y la persiste.
  Future<void> removeItem(int itemId) async {
    final previous = value;
    value = ItineraryState(
      trip: previous.trip,
      items: value.items.where((item) => item.id != itemId).toList(),
      isLoading: previous.isLoading,
    );
    try {
      await _api.removeItem(_tripId, itemId);
    } catch (_) {
      value = previous;
      rethrow;
    }
  }

  String get _tripId =>
      value.trip?.id ??
      (throw StateError('Trip not loaded before itinerary mutation'));
}