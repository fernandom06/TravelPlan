import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/itinerary_item.dart';
import 'itinerary_place_card.dart';

/// Layout mode for the section: a horizontal carousel or a wrapping grid.
enum GeneralItemsLayout {
  /// Horizontal [ListView] carousel with a fixed 160px-tall container.
  carousel,

  /// [Wrap] grid of cards sized to the available width (2–3 per row).
  grid,
}

/// Section of unassigned places.
///
/// Header "LUGARES POR ASIGNAR" (uppercase, tracked) with a counter; a
/// white/50 rounded container with a sand border holds either a horizontally
/// scrollable row of [ItineraryPlaceCard] mini-cards ([GeneralItemsLayout
/// .carousel]) or a wrapping grid ([GeneralItemsLayout.grid]). Dropping
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

  static const _minCardWidth = 150.0;
  static const _spacing = 8.0;
  static const _twoPerRowMinWidth = 2 * _minCardWidth + _spacing;
  static const _threePerRowMinWidth = 3 * _minCardWidth + 2 * _spacing;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ItineraryItem>(
      onAcceptWithDetails: (details) {
        onAcceptItem(details.data, items.length);
      },
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        final isGrid = layout == GeneralItemsLayout.grid;
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
                  const Spacer(),
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.muted.withValues(alpha: 0.6),
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 11,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: isGrid ? null : 160,
                constraints: isGrid
                    ? const BoxConstraints(minHeight: 160)
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
                padding: isGrid
                    ? const EdgeInsets.symmetric(vertical: 8)
                    : const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: isGrid
                    ? _buildGridContent(context)
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

  Widget _buildGridContent(BuildContext context) {
    final trailing = this.trailing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final perRow = _cardsPerRow(available);
        final cardWidth = (available - _spacing * (perRow - 1)) / perRow;
        if (items.isEmpty) {
          if (trailing == null) {
            return SizedBox(height: 160, child: _emptyState(context));
          }
          return SizedBox(
            height: 160,
            child: Center(
              child: SizedBox(width: cardWidth, child: trailing),
            ),
          );
        }
        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(
                width: cardWidth,
                child: DragTarget<ItineraryItem>(
                  onAcceptWithDetails: (details) {
                    onAcceptItem(details.data, i);
                  },
                  builder: (context, _, _) => ItineraryPlaceCard(
                    item: items[i],
                    onDelete: () => onDeleteItem(items[i].id),
                    horizontal: false,
                    width: cardWidth,
                  ),
                ),
              ),
            if (trailing != null) SizedBox(width: cardWidth, child: trailing),
          ],
        );
      },
    );
  }

  static int _cardsPerRow(double available) {
    if (available >= _threePerRowMinWidth) return 3;
    if (available >= _twoPerRowMinWidth) return 2;
    return 1;
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
