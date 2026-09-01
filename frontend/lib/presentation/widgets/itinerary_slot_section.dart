import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/itinerary_item.dart';
import '../../data/models/itinerary_slot.dart';
import 'dashed_border_container.dart';
import 'itinerary_place_card.dart';

/// Timeline-style slot section: a terracotta rail with a circular marker per
/// slot, a Fraunces header with a per-slot icon, and either a dashed drop zone
/// ("Arrastra lugares aquí", highlighted while dragging) or the assigned
/// [ItineraryPlaceCard]s. Drag semantics (append + insert-before) are
/// unchanged.
class ItinerarySlotSection extends StatelessWidget {
  const ItinerarySlotSection({
    super.key,
    required this.title,
    required this.slot,
    required this.items,
    required this.onAcceptItem,
    required this.onDeleteItem,
    this.isLast = false,
  });

  final String title;
  final ItinerarySlot slot;
  final List<ItineraryItem> items;

  /// Whether this is the last section of the day: when true the timeline rail
  /// stops at its marker instead of running to the bottom edge.
  final bool isLast;

  /// Called when an item is dropped on this slot with the insert index
  /// ("insert before") already computed.
  final void Function(ItineraryItem item, ItinerarySlot slot, int index)
  onAcceptItem;
  final void Function(int itemId) onDeleteItem;

  static IconData _iconFor(ItinerarySlot slot) => switch (slot) {
    ItinerarySlot.morning => Icons.light_mode,
    ItinerarySlot.afternoon => Icons.wb_sunny,
    ItinerarySlot.night => Icons.dark_mode,
  };

  @override
  Widget build(BuildContext context) {
    return DragTarget<ItineraryItem>(
      onAcceptWithDetails: (details) {
        onAcceptItem(details.data, slot, items.length);
      },
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline rail with a circular marker aligned to the header.
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            _iconFor(slot),
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontFamily: 'Fraunces',
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _dropZone(
                      context,
                      highlighted,
                      items.isEmpty
                          ? _emptyHint(highlighted)
                          : Column(
                              children: [
                                for (var i = 0; i < items.length; i++)
                                  DragTarget<ItineraryItem>(
                                    onAcceptWithDetails: (details) {
                                      onAcceptItem(details.data, slot, i);
                                    },
                                    builder: (context, _, _) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: ItineraryPlaceCard(
                                        item: items[i],
                                        onDelete: () =>
                                            onDeleteItem(items[i].id),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dropZone(BuildContext context, bool highlighted, Widget child) {
    return DashedBorderContainer(
      color: highlighted ? AppColors.accent : AppColors.muted,
      backgroundColor: highlighted
          ? AppColors.background
          : AppColors.surface.withValues(alpha: 0.3),
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: child,
    );
  }

  Widget _emptyHint(bool highlighted) {
    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 16,
            color: highlighted ? AppColors.accent : AppColors.muted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Arrastra lugares aquí',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 13,
                color: highlighted ? AppColors.accent : AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
