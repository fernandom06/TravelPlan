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

  final combined = [...gapped, moved]
    ..sort((a, b) {
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
    this.loadError,
    this.isMutating = false,
  });

  final Trip? trip;
  final List<ItineraryItem> items;
  final bool isLoading;

  /// Error of the last failed load. While items are visible the screen keeps
  /// working and only notifies; when the list is empty the screen shows an
  /// explicit error state instead of looking like an empty itinerary.
  final Object? loadError;

  /// True while at least one optimistic mutation is in flight, so the screen
  /// can say "guardando" instead of looking settled while a request runs.
  final bool isMutating;
}

class ItineraryController extends ValueNotifier<ItineraryState> {
  ItineraryController(this._api)
    : super(const ItineraryState(trip: null, items: [], isLoading: false));

  final ItineraryApi _api;

  int _tempIdCounter = 0;

  int _nextTempId() => -(_tempIdCounter++ + 1);

  int _pendingMutations = 0;

  ItineraryState _copy(
    ItineraryState base, {
    List<ItineraryItem>? items,
    bool? isLoading,
    Object? loadError,
    required bool isMutating,
  }) => ItineraryState(
    trip: base.trip,
    items: items ?? base.items,
    isLoading: isLoading ?? base.isLoading,
    loadError: loadError, // null clears the error on the next success.
    isMutating: isMutating,
  );

  Future<void> loadItinerary(Trip trip) async {
    value = ItineraryState(
      trip: trip,
      items: value.items,
      isLoading: true,
      loadError: value.loadError,
      isMutating: value.isMutating,
    );
    try {
      final items = await _api.fetchItinerary(trip.id);
      value = _copy(value, items: items, isLoading: false, isMutating: value.isMutating);
    } catch (e) {
      value = _copy(
        value,
        isLoading: false,
        loadError: e,
        isMutating: value.isMutating,
      );
      rethrow;
    }
  }

  /// Añade un lugar al final de la lista general de forma optimista:
  /// aparece al instante y, si el POST falla, se revierte el cambio.
  Future<void> addPlace(Place place) async {
    final generalCount = value.items.where((item) => item.isUnassigned).length;
    final tempId = _nextTempId();
    final tempItem = ItineraryItem(
      id: tempId,
      dayDate: null,
      slot: null,
      position: generalCount,
      place: place,
    );
    final previous = value;
    _pendingMutations++;
    value = _copy(
      value,
      items: [...value.items, tempItem],
      isMutating: true,
    );
    try {
      final created = await _api.addPlace(_tripId, place.id);
      _pendingMutations--;
      value = _copy(
        value,
        items: [
          for (final item in value.items) item.id == tempId ? created : item,
        ],
        isMutating: _pendingMutations > 0,
      );
    } catch (_) {
      _pendingMutations--;
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
    _pendingMutations++;
    final newItems = computeMove(
      value.items,
      itemId,
      targetDay,
      targetSlot,
      targetIndex,
    );
    value = _copy(
      previous,
      items: newItems,
      isMutating: true,
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
      _pendingMutations--;
      value = _copy(value, isMutating: _pendingMutations > 0);
    } catch (_) {
      _pendingMutations--;
      value = previous;
      rethrow;
    }
  }

  /// Borra una instancia de forma optimista y la persiste.
  Future<void> removeItem(int itemId) async {
    final previous = value;
    _pendingMutations++;
    value = _copy(
      value,
      items: value.items.where((item) => item.id != itemId).toList(),
      isMutating: true,
    );
    try {
      await _api.removeItem(_tripId, itemId);
      _pendingMutations--;
      value = _copy(value, isMutating: _pendingMutations > 0);
    } catch (_) {
      _pendingMutations--;
      value = previous;
      rethrow;
    }
  }

  String get _tripId =>
      value.trip?.id ??
      (throw StateError('Trip not loaded before itinerary mutation'));
}
