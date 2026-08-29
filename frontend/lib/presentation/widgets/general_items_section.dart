import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/itinerary_item.dart';
import 'itinerary_place_card.dart';

/// Horizontal carousel of unassigned places.
///
/// Header "LUGARES POR ASIGNAR" (uppercase, tracked) with a counter; a
/// white/50 rounded container with a sand border holds a horizontally
/// scrollable row of [ItineraryPlaceCard] mini-cards. Dropping anywhere on the
/// container appends; dropping on a card inserts before that card's index.
class GeneralItemsSection extends StatelessWidget {
  const GeneralItemsSection({
    super.key,
    required this.items,
    required this.onAcceptItem,
    required this.onDeleteItem,
  });

  final List<ItineraryItem> items;

  /// Called when an item is dropped on the general list (null destination)
  /// with the horizontal insert index already computed.
  final void Function(ItineraryItem item, int index) onAcceptItem;
  final void Function(int itemId) onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ItineraryItem>(
      onAcceptWithDetails: (details) {
        onAcceptItem(details.data, items.length);
      },
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
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
                height: 158,
                decoration: BoxDecoration(
                  color: highlighted
                      ? AppColors.surface
                      : AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: AppRadii.organic,
                  border: Border.all(
                    color: AppColors.muted.withValues(alpha: 0.5),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                child: items.isEmpty
                    ? _emptyState(context)
                    : ListView.separated(
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
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
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