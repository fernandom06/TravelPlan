import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/itinerary_item.dart';
import '../controllers/itinerary_drag_session.dart';
import 'itinerary_place_card.dart';
import 'section_drag_drop.dart';

/// Layout mode for the section: a horizontal carousel or a vertical list.
enum GeneralItemsLayout {
  /// Horizontal [ListView] carousel with a fixed 200px-tall container.
  carousel,

  /// Full-width vertical list of cards, one per row.
  vertical,
}

/// Section of unassigned places.
///
/// Header "Lugares por asignar" as a section title; a white/50 rounded
/// container with a sand border holds either a horizontally scrollable row of
/// [ItineraryPlaceCard] mini-cards ([GeneralItemsLayout.carousel]) or a
/// full-width vertical list ([GeneralItemsLayout.vertical]). When it fills a
/// bounded height, the vertical list centers the header together with its
/// cards and scrolls once they overflow.
///
/// One single [DragTarget] covers the whole section: the insert index comes
/// from the pointer position over the visible cards (dx on the carousel, dy on
/// the vertical list), so the preview hole and the drop always agree. Adding
/// new places lives on the screen's FAB, not here.
class GeneralItemsSection extends StatefulWidget {
  const GeneralItemsSection({
    super.key,
    required this.items,
    required this.onAcceptItem,
    required this.onDeleteItem,
    this.onOpenItem,
    this.layout = GeneralItemsLayout.carousel,
    this.dragSession,
  });

  final List<ItineraryItem> items;

  /// Called when an item is dropped on the general list (null destination)
  /// with the insert index already computed.
  final void Function(ItineraryItem item, int index) onAcceptItem;
  final void Function(int itemId) onDeleteItem;

  /// Invoked when a card is plain-tapped (non-drag move alternative).
  final void Function(ItineraryItem item)? onOpenItem;

  /// How the cards are laid out inside the container.
  final GeneralItemsLayout layout;

  /// Shared drag state: when present, the section reports the hovered insert
  /// index and renders the translucent hole there.
  final ItineraryDragSession? dragSession;

  static const _carouselHeight = 200.0;

  @override
  State<GeneralItemsSection> createState() => _GeneralItemsSectionState();
}

class _GeneralItemsSectionState extends State<GeneralItemsSection>
    with SectionDragDrop<GeneralItemsSection> {
  bool get _isVertical => widget.layout == GeneralItemsLayout.vertical;

  @override
  List<ItineraryItem> get items => widget.items;

  @override
  ItineraryDragSession? get dragSession => widget.dragSession;

  @override
  ItineraryDragContainer get dragContainer => kGeneralDragContainer;

  @override
  Axis get stackAxis => _isVertical ? Axis.vertical : Axis.horizontal;

  @override
  void acceptItem(ItineraryItem item, int index) {
    widget.onAcceptItem(item, index);
  }

  @override
  Widget build(BuildContext context) {
    syncCardKeys();
    return DragTarget<ItineraryItem>(
      onMove: onSectionMove,
      onAcceptWithDetails: onSectionAccept,
      builder: (context, candidateData, _) {
        final highlighted = candidateData.isNotEmpty;
        return _withPreview(
          (previewIndex) => LayoutBuilder(
            builder: (context, constraints) {
              final fillsHeight = _isVertical && constraints.hasBoundedHeight;
              final header = _header(context);
              if (fillsHeight) {
                // The header joins the cards inside the panel so the whole
                // group stays vertically centered in the tall column.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _panel(
                        context,
                        highlighted: highlighted,
                        fillsHeight: true,
                        previewIndex: previewIndex,
                        header: header,
                      ),
                    ),
                  ],
                );
              }
              final panel = _panel(
                context,
                highlighted: highlighted,
                fillsHeight: false,
                previewIndex: previewIndex,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [header, panel],
              );
            },
          ),
        );
      },
    );
  }

  /// Rebuilds the panel while a drag hovers this section, with the preview
  /// index (null when the hole is not here).
  Widget _withPreview(Widget Function(int? previewIndex) builder) {
    final session = widget.dragSession;
    if (session == null) return builder(null);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => builder(previewIndexFor(session)),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        'Lugares por asignar',
        // titleMedium: this is a section label, not a page title — the trip
        // name and day context outrank it in the visual hierarchy.
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: AppColors.text),
      ),
    );
  }

  Widget _panel(
    BuildContext context, {
    required bool highlighted,
    required bool fillsHeight,
    int? previewIndex,
    Widget? header,
  }) {
    return Padding(
      padding: _isVertical
          ? const EdgeInsets.fromLTRB(12, 0, 12, 16)
          : const EdgeInsets.symmetric(horizontal: 12),
      child: AnimatedContainer(
        key: const ValueKey('general-items-panel'),
        duration: const Duration(milliseconds: 120),
        height: _isVertical ? null : GeneralItemsSection._carouselHeight,
        constraints: _isVertical ? const BoxConstraints(minHeight: 120) : null,
        decoration: _isVertical
            // The vertical panel mirrors the timeline: no framed box at rest,
            // only a subtle fill while a drag is hovering over it.
            ? (highlighted
                  ? BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.5),
                      borderRadius: AppRadii.organic,
                    )
                  : const BoxDecoration())
            : BoxDecoration(
                color: highlighted
                    ? AppColors.surface
                    : AppColors.surface.withValues(alpha: 0.5),
                borderRadius: AppRadii.organic,
                border: Border.all(
                  color: AppColors.muted.withValues(alpha: 0.5),
                ),
              ),
        padding: _isVertical
            ? const EdgeInsets.symmetric(vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: _isVertical
            ? _buildVerticalContent(
                context,
                scrollable: fillsHeight,
                previewIndex: previewIndex,
                header: header,
              )
            : _buildContent(context, previewIndex: previewIndex),
      ),
    );
  }

  Widget _buildContent(BuildContext context, {int? previewIndex}) {
    if (widget.items.isEmpty) {
      final empty = _emptyState(context);
      // Without cards the insert index is always 0: the hole previews that
      // spot next to the empty state.
      if (previewIndex == null) return empty;
      return Row(
        children: [
          const ItineraryDropPlaceholder(width: kItineraryPlaceholderWidth),
          const SizedBox(width: 8),
          Expanded(child: empty),
        ],
      );
    }
    final itemCount = widget.items.length + (previewIndex == null ? 0 : 1);
    final keys = measurementKeys();
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, slot) {
        if (previewIndex != null && slot == previewIndex) {
          return const ItineraryDropPlaceholder(
            width: kItineraryPlaceholderWidth,
          );
        }
        final index = previewIndex != null && slot > previewIndex
            ? slot - 1
            : slot;
        return _carouselCard(index, keys[index]);
      },
    );
  }

  Widget _carouselCard(int index, Key? key) {
    final item = widget.items[index];
    return KeyedSubtree(
      key: key,
      child: ItineraryPlaceCard(
        item: item,
        onDelete: () => widget.onDeleteItem(item.id),
        onTap: widget.onOpenItem == null
            ? null
            : () => widget.onOpenItem!(item),
        horizontal: false,
        onDragStarted: (anchor) => widget.dragSession?.start(item, anchor),
        onDragEnd: () => widget.dragSession?.end(),
      ),
    );
  }

  Widget _buildVerticalContent(
    BuildContext context, {
    bool scrollable = false,
    int? previewIndex,
    Widget? header,
  }) {
    final content = _verticalContent(
      context,
      previewIndex: previewIndex,
      header: header,
    );
    if (!scrollable) return content;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: content),
        ),
      ),
    );
  }

  Widget _verticalContent(
    BuildContext context, {
    int? previewIndex,
    Widget? header,
  }) {
    if (widget.items.isEmpty) {
      // The hint text is two lines at panel width: it must size itself, not
      // fit a fixed trailing slot.
      final body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: _emptyState(context),
      );
      final withHole = previewIndex == null
          ? body
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: ItineraryDropPlaceholder(),
                ),
                body,
              ],
            );
      if (header == null) return withHole;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, withHole],
      );
    }
    final keys = measurementKeys();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?header,
        for (var i = 0; i <= widget.items.length; i++) ...[
          if (previewIndex == i)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: ItineraryDropPlaceholder(),
            ),
          if (i < widget.items.length) _verticalCard(i, keys[i]),
        ],
      ],
    );
  }

  Widget _verticalCard(int index, Key? key) {
    final item = widget.items[index];
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 8),
      child: ItineraryPlaceCard(
        item: item,
        onDelete: () => widget.onDeleteItem(item.id),
        onTap: widget.onOpenItem == null
            ? null
            : () => widget.onOpenItem!(item),
        onDragStarted: (anchor) => widget.dragSession?.start(item, anchor),
        onDragEnd: () => widget.dragSession?.end(),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.travel_explore, size: 24, color: AppColors.muted),
          const SizedBox(height: 6),
          Text(
            'Todavía no hay lugares por asignar. ¿Añadimos uno?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
