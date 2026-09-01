import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/itinerary_item.dart';
import 'itinerary_place_card.dart';

/// Layout mode for the section: a horizontal carousel or a vertical list.
enum GeneralItemsLayout {
  /// Horizontal [ListView] carousel with a fixed 176px-tall container.
  carousel,

  /// Full-width vertical list of cards, one per row.
  vertical,
}

/// Section of unassigned places.
///
/// Header "LUGARES POR ASIGNAR" (uppercase, tracked); a white/50 rounded
/// container with a sand border holds either a horizontally scrollable row of
/// [ItineraryPlaceCard] mini-cards ([GeneralItemsLayout.carousel]) or a
/// full-width vertical list ([GeneralItemsLayout.vertical]). Dropping
/// anywhere on the container appends; dropping on a card inserts before that
/// card's index. An optional [trailing] widget is shown after the last card
/// (or centered when there are no items).
class GeneralItemsSection extends StatelessWidget {
  const GeneralItemsSection({
    super.key,
    required this.items,
    required this.onAcceptItem,
    required this.onDeleteItem,
    this.trailing,
    this.layout = GeneralItemsLayout.carousel,
  });

  final List<ItineraryItem> items;

  /// Called when an item is dropped on the general list (null destination)
  /// with the horizontal insert index already computed.
  final void Function(ItineraryItem item, int index) onAcceptItem;
  final void Function(int itemId) onDeleteItem;

  /// Optional widget (e.g. a [DashedActionCard]) rendered at the end of the
  /// carousel, or centered in the empty state. When null the section keeps its
  /// current layout.
  final Widget? trailing;

  /// How the cards are laid out inside the container.
  final GeneralItemsLayout layout;

  static const _carouselHeight = 176.0;
  static const _trailingHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ItineraryItem>(
      onAcceptWithDetails: (details) {
        onAcceptItem(details.data, items.length);
      },
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        final isVertical = layout == GeneralItemsLayout.vertical;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'LUGARES POR ASIGNAR',
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Color(0xB33D405B), // navy/70
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: isVertical ? null : _carouselHeight,
                constraints: isVertical
                    ? const BoxConstraints(minHeight: 120)
                    : null,
                decoration: BoxDecoration(
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
                    ? _buildVerticalContent(context)
                    : _buildContent(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final trailing = this.trailing;
    if (items.isEmpty) {
      if (trailing == null) return _emptyState(context);
      return Center(child: SizedBox(width: 104, child: trailing));
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length + (trailing == null ? 0 : 1),
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        if (trailing != null && i == items.length) {
          return SizedBox(width: 104, child: trailing);
        }
        final item = items[i];
        return DragTarget<ItineraryItem>(
          onAcceptWithDetails: (details) {
            onAcceptItem(details.data, i);
          },
          builder: (context, _, _) => ItineraryPlaceCard(
            item: item,
            onDelete: () => onDeleteItem(item.id),
            horizontal: false,
          ),
        );
      },
    );
  }

  Widget _buildVerticalContent(BuildContext context) {
    final trailing = this.trailing;
    if (items.isEmpty) {
      if (trailing == null) {
        return SizedBox(height: _trailingHeight, child: _emptyState(context));
      }
      return SizedBox(height: _trailingHeight, child: trailing);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              ),
            ),
          ),
        if (trailing != null)
          SizedBox(height: _trailingHeight, child: trailing),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: const Text(
        'Añade lugares al viaje',
        style: TextStyle(
          fontFamily: 'Lora',
          fontSize: 13,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
