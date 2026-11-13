import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import '../../data/models/itinerary_item.dart';
import '../../data/models/itinerary_slot.dart';

/// Contenedor del itinerario al que apunta un arrastre: el `(day, slot)` de
/// una sección de día o `(null, null)` para "Por asignar".
typedef ItineraryDragContainer = ({DateTime? day, ItinerarySlot? slot});

/// Contenedor de la lista general "Por asignar".
const ItineraryDragContainer kGeneralDragContainer = (day: null, slot: null);

/// Índice de inserción ("insertar antes") para un drop sobre el eje de
/// apilado de una sección del itinerario.
///
/// [cardCenters] son los centros de las tarjetas visibles del contenedor en
/// coordenadas locales de su `DragTarget`, ordenados de menor a mayor sobre el
/// eje de apilado (dy en vertical, dx en el carrusel). [dropPosition] es la
/// posición del puntero sobre ese mismo eje. Devuelve cuántos centros quedan
/// estrictamente por encima del drop: soltar sobre el centro de una tarjeta
/// inserta antes de ella y soltar por debajo de la última una posición más.
int computeInsertIndex({
  required List<double> cardCenters,
  required double dropPosition,
}) {
  var index = 0;
  for (final center in cardCenters) {
    if (center < dropPosition) index++;
  }
  return index;
}

/// Estado efímero de un arrastre del itinerario, compartido por todas las
/// secciones para que solo haya un hueco de previsualización visible a la vez.
///
/// Vive solo durante el gesto: [start] al empezar, [updatePreview] en cada
/// movimiento sobre una sección y [end] al soltar o cancelar. Nunca se
/// persiste.
class ItineraryDragSession extends ChangeNotifier {
  ItineraryItem? _draggedItem;
  Offset _dragAnchor = Offset.zero;
  ItineraryDragContainer? _previewContainer;
  int? _previewIndex;

  ItineraryItem? get draggedItem => _draggedItem;

  /// Where the pointer grabbed the dragged card, in the card's local
  /// coordinates. Drag targets receive the feedback's top-left corner, so
  /// adding this anchor turns it back into the pointer position. It travels in
  /// the session so every section, including the ones the drag merely crosses,
  /// computes the index from the real pointer.
  Offset get dragAnchor => _dragAnchor;

  ItineraryDragContainer? get previewContainer => _previewContainer;

  int? get previewIndex => _previewIndex;

  void start(ItineraryItem item, Offset anchor) {
    if (_draggedItem?.id == item.id &&
        _dragAnchor == anchor &&
        _previewContainer == null &&
        _previewIndex == null) {
      return;
    }
    _draggedItem = item;
    _dragAnchor = anchor;
    _previewContainer = null;
    _previewIndex = null;
    notifyListeners();
  }

  void updatePreview(ItineraryDragContainer container, int index) {
    if (_previewContainer == container && _previewIndex == index) return;
    _previewContainer = container;
    _previewIndex = index;
    notifyListeners();
  }

  void end() {
    if (_draggedItem == null &&
        _dragAnchor == Offset.zero &&
        _previewContainer == null &&
        _previewIndex == null) {
      return;
    }
    _draggedItem = null;
    _dragAnchor = Offset.zero;
    _previewContainer = null;
    _previewIndex = null;
    notifyListeners();
  }
}
