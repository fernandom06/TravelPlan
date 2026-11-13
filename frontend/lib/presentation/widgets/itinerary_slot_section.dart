import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/itinerary_item.dart';
import '../../data/models/itinerary_slot.dart';
import 'dashed_border_container.dart';
import 'itinerary_place_card.dart';

/// Timeline-style slot section: a terracotta rail with a circular marker per
/// slot, a Fraunces header with a per-slot icon, and either a dashed drop zone
/// ("Arrastra lugares aquí", highlighted while dragging) or the assigned
/// [ItineraryPlaceCard]s. The empty drop zone is also tappable via
/// [onAddPlace], which opens the picker pre-targeted to this day+slot.
/// Drag semantics (append + insert-before) are unchanged.
class ItinerarySlotSection extends StatelessWidget {
  const ItinerarySlotSection({
    super.key,
    required this.title,
    required this.slot,
    required this.items,
    required this.onAcceptItem,
    required this.onDeleteItem,
    this.onOpenItem,
    this.onAddPlace,
    this.dayLabel,
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

  /// Invoked when a card is plain-tapped (non-drag move alternative).
  final void Function(ItineraryItem item)? onOpenItem;

  /// Invoked when the empty drop zone is tapped: opens the place picker
  /// pre-targeted to this day+slot, so adding somewhere specific does not
  /// require a drag. Null keeps the zone drag-only.
  final VoidCallback? onAddPlace;

  /// Day context (e.g. "Día 2 · 02 Jun") spoken in the empty-zone Semantics
  /// label, so a screen reader knows which day the zone targets. The slot
  /// title alone ("Mañana") is ambiguous across days.
  final String? dayLabel;

  /// Icons picked so the three slots read apart at a glance: dawn light for
  /// morning, a full sun for afternoon and the moon for night. Public so the
  /// move sheet can reuse the exact same vocabulary.
  static IconData iconFor(ItinerarySlot slot) => switch (slot) {
    ItinerarySlot.morning => Icons.wb_twilight,
    ItinerarySlot.afternoon => Icons.wb_sunny,
    ItinerarySlot.night => Icons.dark_mode,
  };

  /// The empty-slot hint names the real gesture: on touch platforms items
  /// move by long-press, on desktop by an immediate drag.
  static String dragHint(BuildContext context) {
    final isDesktop = switch (Theme.of(context).platform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    };
    return isDesktop
        ? 'Arrastra lugares aquí'
        : 'Mantén pulsado y arrastra lugares aquí';
  }

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
                            iconFor(slot),
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.text),
                          ),
                        ],
                      ),
                    ),
                    _content(
                      context,
                      highlighted,
                      items.isEmpty,
                      items.isEmpty
                          ? _emptyHint(context)
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
                                        onTap: onOpenItem == null
                                            ? null
                                            : () => onOpenItem!(items[i]),
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

  /// Renders the assigned cards directly on the timeline when the slot has
  /// content at rest; the dashed drop zone is only shown while the slot is
  /// empty or being dragged over, so the dashed border keeps its "drop here"
  /// meaning instead of framing every filled group.
  Widget _content(
    BuildContext context,
    bool highlighted,
    bool isEmpty,
    Widget child,
  ) {
    if (highlighted || isEmpty) return _dropZone(context, highlighted, child);
    return child;
  }

  Widget _dropZone(BuildContext context, bool highlighted, Widget child) {
    final zone = DashedBorderContainer(
      color: highlighted ? AppColors.accent : AppColors.muted,
      backgroundColor: highlighted
          ? AppColors.background
          : AppColors.surface.withValues(alpha: 0.3),
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: child,
    );
    final onTap = highlighted ? null : onAddPlace;
    if (onTap == null) return zone;
    final label = dayLabel == null
        ? 'Añadir lugar en $title'
        : 'Añadir lugar en $title · $dayLabel';
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(onTap: onTap, child: zone),
    );
  }

  Widget _emptyHint(BuildContext context) {
    // The hint holds textSecondary even while dragging: mint accent text on
    // the paper background only reaches ~2.1:1. The highlighted accent
    // border on the drop zone already carries the "drop here" signal.
    const hintColor = AppColors.textSecondary;
    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_circle_outline, size: 16, color: hintColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              dragHint(context),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: hintColor),
            ),
          ),
        ],
      ),
    );
  }
}
