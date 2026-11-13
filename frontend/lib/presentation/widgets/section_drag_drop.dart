import 'package:flutter/widgets.dart';

import '../../data/models/itinerary_item.dart';
import '../controllers/itinerary_drag_session.dart';

/// Shared drag & drop mechanics of the itinerary sections.
///
/// Both the day slots and the "Por asignar" list accept drops the same way:
/// one [DragTarget] per section, card centres measured by [GlobalKey] on the
/// stacking axis ([Axis.vertical] with `dy`, [Axis.horizontal] with `dx`) and
/// an insert index ("insert before") derived from the pointer position. The
/// grab anchor travels in the shared [ItineraryDragSession], so a section the
/// drag merely crosses computes the index from the real pointer.
///
/// Each state supplies its own items, session, container and axis through the
/// hooks, and decides how to render the hole (column vs carousel list).
mixin SectionDragDrop<T extends StatefulWidget> on State<T> {
  /// One key per card id: measuring by id keeps each key on the same card
  /// after a reorder, and pruning keeps the map bounded by the visible cards.
  final Map<int, GlobalKey> _cardKeys = {};

  /// Card centres in the section's local coordinates, with the drag state they
  /// were measured under. The hole opening or closing reflows the cards, a new
  /// dragged item may move the hole, and the preview index is shared across
  /// containers (the same index can point at another section), so all three
  /// invalidate the cache.
  List<double>? _centers;
  int? _centersDraggedItemId;
  ItineraryDragContainer? _centersPreviewContainer;
  int? _centersPreviewIndex;

  /// Items rendered by the section, in visual order.
  List<ItineraryItem> get items;

  /// Shared drag state; null keeps the section drop-only.
  ItineraryDragSession? get dragSession;

  /// Container this section accepts drops for.
  ItineraryDragContainer get dragContainer;

  /// Axis the cards are stacked on.
  Axis get stackAxis;

  /// Forwards a non-no-op drop to the owner (the callback shape differs
  /// between the slot and the general list).
  void acceptItem(ItineraryItem item, int index);

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _invalidateCenters();
  }

  /// Adds keys for new ids and prunes the ones no longer on screen.
  void syncCardKeys() {
    final ids = {for (final item in items) item.id};
    _cardKeys.removeWhere((id, _) => !ids.contains(id));
    for (final id in ids) {
      _cardKeys.putIfAbsent(id, GlobalKey.new);
    }
  }

  /// Measurement keys for [items], in visual order.
  ///
  /// Ids are server primary keys, so they are unique; should a repeated id
  /// slip in, only its first card gets the [GlobalKey] (two widgets can never
  /// share one). The extra card renders unmeasured instead of breaking the
  /// tree, and the measured centres stay those of the first occurrence.
  List<Key?> measurementKeys() {
    final seen = <int>{};
    return [
      for (final item in items)
        if (seen.add(item.id)) _keyFor(item) else null,
    ];
  }

  GlobalKey _keyFor(ItineraryItem item) =>
      _cardKeys.putIfAbsent(item.id, GlobalKey.new);

  /// Reports the hovered insert index to the session (`onMove`).
  void onSectionMove(DragTargetDetails<ItineraryItem> details) {
    dragSession?.updatePreview(dragContainer, insertIndexAt(details.offset));
  }

  /// Forwards the drop with its insert index, unless it is a no-op.
  void onSectionAccept(DragTargetDetails<ItineraryItem> details) {
    final item = details.data;
    final index = insertIndexAt(details.offset);
    // Dropping on the item's own place changes nothing: the controller would
    // leave it where it is, so neither the section nor the screen is notified.
    if (_isOwnPosition(item, index)) return;
    acceptItem(item, index);
  }

  /// Index where the hole should be drawn, or null when it is not this
  /// section's turn (or when the drop would not change anything, which keeps
  /// the section height stable at that spot).
  int? previewIndexFor(ItineraryDragSession session) {
    final item = session.draggedItem;
    if (item == null || session.previewContainer != dragContainer) return null;
    final index = session.previewIndex;
    if (index == null || _isOwnPosition(item, index)) return null;
    return index;
  }

  /// Insert index ("insert before") for a drop at [globalOffset], measured
  /// against the live card centres in the section's own coordinates.
  int insertIndexAt(Offset globalOffset) {
    final sectionBox = context.findRenderObject() as RenderBox?;
    if (sectionBox == null || !sectionBox.attached) return items.length;
    // Drag targets report the feedback's top-left corner; the session's anchor
    // is where the pointer grabbed it, so adding it recovers the pointer.
    final local = sectionBox.globalToLocal(
      globalOffset + (dragSession?.dragAnchor ?? Offset.zero),
    );
    final horizontal = stackAxis == Axis.horizontal;
    final dropPosition = horizontal ? local.dx : local.dy;
    final centers = _centersFor(sectionBox, horizontal: horizontal);
    return computeInsertIndex(cardCenters: centers, dropPosition: dropPosition);
  }

  /// Cached card centres. Re-reads the render tree only when the drag state
  /// that shapes the layout changed (different dragged item or hole position)
  /// or the section's items were replaced; a straight move between two card
  /// boundaries is then O(1).
  List<double> _centersFor(RenderBox sectionBox, {required bool horizontal}) {
    final draggedItemId = dragSession?.draggedItem?.id;
    final previewContainer = dragSession?.previewContainer;
    final previewIndex = dragSession?.previewIndex;
    final cached = _centers;
    if (cached != null &&
        _centersDraggedItemId == draggedItemId &&
        _centersPreviewContainer == previewContainer &&
        _centersPreviewIndex == previewIndex) {
      return cached;
    }
    final centers = <double>[];
    for (final item in items) {
      final box =
          _cardKeys[item.id]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final center = sectionBox.globalToLocal(
        box.localToGlobal(box.size.center(Offset.zero)),
      );
      centers.add(horizontal ? center.dx : center.dy);
    }
    _centers = centers;
    _centersDraggedItemId = draggedItemId;
    _centersPreviewContainer = previewContainer;
    _centersPreviewIndex = previewIndex;
    return centers;
  }

  void _invalidateCenters() {
    _centers = null;
    _centersDraggedItemId = null;
    _centersPreviewContainer = null;
    _centersPreviewIndex = null;
  }

  bool _isOwnPosition(ItineraryItem item, int index) {
    return item.dayDate == dragContainer.day &&
        item.slot == dragContainer.slot &&
        item.position == index;
  }
}
