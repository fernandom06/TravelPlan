import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/itinerary_item.dart';
import 'itinerary_place_card.dart';

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
/// cards and scrolls once they overflow. Dropping anywhere on the container
/// appends; dropping on a card inserts before that card's index. Adding new
/// places lives on the screen's FAB, not here.
class GeneralItemsSection extends StatelessWidget {
  const GeneralItemsSection({
    super.key,
    required this.items,
    required this.onAcceptItem,
    required this.onDeleteItem,
    this.onOpenItem,
    this.layout = GeneralItemsLayout.carousel,
  });

  final List<ItineraryItem> items;

  /// Called when an item is dropped on the general list (null destination)
  /// with the horizontal insert index already computed.
  final void Function(ItineraryItem item, int index) onAcceptItem;
  final void Function(int itemId) onDeleteItem;

  /// Invoked when a card is plain-tapped (non-drag move alternative).
  final void Function(ItineraryItem item)? onOpenItem;

  /// How the cards are laid out inside the container.
  final GeneralItemsLayout layout;

  static const _carouselHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ItineraryItem>(
      onAcceptWithDetails: (details) {
        onAcceptItem(details.data, items.length);
      },
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        final isVertical = layout == GeneralItemsLayout.vertical;
        final header = _header(context);
        return LayoutBuilder(
          builder: (context, constraints) {
            final fillsHeight = isVertical && constraints.hasBoundedHeight;
            if (fillsHeight) {
              // The header joins the cards inside the panel so the whole
              // group stays vertically centered in the tall column.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _panel(
                      context,
                      isVertical: true,
                      highlighted: highlighted,
                      fillsHeight: true,
                      header: header,
                    ),
                  ),
                ],
              );
            }
            final panel = _panel(
              context,
              isVertical: isVertical,
              highlighted: highlighted,
              fillsHeight: false,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [header, panel],
            );
          },
        );
      },
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
    required bool isVertical,
    required bool highlighted,
    required bool fillsHeight,
    Widget? header,
  }) {
    return Padding(
      padding: isVertical
          ? const EdgeInsets.fromLTRB(12, 0, 12, 16)
          : const EdgeInsets.symmetric(horizontal: 12),
      child: AnimatedContainer(
        key: const ValueKey('general-items-panel'),
        duration: const Duration(milliseconds: 120),
        height: isVertical ? null : _carouselHeight,
        constraints: isVertical ? const BoxConstraints(minHeight: 120) : null,
        decoration: isVertical
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
        padding: isVertical
            ? const EdgeInsets.symmetric(vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: isVertical
            ? _buildVerticalContent(
                context,
                scrollable: fillsHeight,
                header: header,
              )
            : _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (items.isEmpty) return _emptyState(context);
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final item = items[i];
        return DragTarget<ItineraryItem>(
          onAcceptWithDetails: (details) {
            onAcceptItem(details.data, i);
          },
          builder: (context, _, _) => ItineraryPlaceCard(
            item: item,
            onDelete: () => onDeleteItem(item.id),
            onTap: onOpenItem == null ? null : () => onOpenItem!(item),
            horizontal: false,
          ),
        );
      },
    );
  }

  Widget _buildVerticalContent(
    BuildContext context, {
    bool scrollable = false,
    Widget? header,
  }) {
    final content = _verticalContent(context, header: header);
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

  Widget _verticalContent(BuildContext context, {Widget? header}) {
    if (items.isEmpty) {
      // The hint text is two lines at panel width: it must size itself, not
      // fit a fixed trailing slot.
      final body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: _emptyState(context),
      );
      if (header == null) return body;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, body],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?header,
        for (var i = 0; i < items.length; i++)
          DragTarget<ItineraryItem>(
            onAcceptWithDetails: (details) {
              onAcceptItem(details.data, i);
            },
            builder: (context, _, _) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ItineraryPlaceCard(
                item: items[i],
                onDelete: () => onDeleteItem(items[i].id),
                onTap: onOpenItem == null ? null : () => onOpenItem!(items[i]),
              ),
            ),
          ),
      ],
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
