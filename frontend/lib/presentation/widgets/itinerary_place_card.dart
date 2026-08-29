import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/category_icon_catalog.dart';
import '../../data/models/itinerary_item.dart';

/// Mini-card for itinerary items: tinted category-icon circle, place name and
/// a trash button, wrapped in a [Draggable] (immediate on desktop, long-press
/// elsewhere) that carries the [ItineraryItem].
class ItineraryPlaceCard extends StatelessWidget {
  const ItineraryPlaceCard({
    super.key,
    required this.item,
    required this.onDelete,
  });

  final ItineraryItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final place = item.place;
    final content = _MiniCard(
      item: item,
      onDelete: onDelete,
      showDragHandle: true,
    );
    final feedback = Material(
      elevation: 4,
      color: Colors.transparent,
      child: _MiniCard(item: item, onDelete: () {}),
    );
    final isDesktop = switch (Theme.of(context).platform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    };
    return isDesktop
        ? Draggable<ItineraryItem>(
            data: item,
            feedback: feedback,
            childWhenDragging: Opacity(opacity: 0.4, child: content),
            child: content,
          )
        : LongPressDraggable<ItineraryItem>(
            data: item,
            feedback: feedback,
            childWhenDragging: Opacity(opacity: 0.4, child: content),
            child: content,
          );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.item,
    required this.onDelete,
    this.showDragHandle = false,
  });

  final ItineraryItem item;
  final VoidCallback onDelete;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final place = item.place;
    return Container(
      width: 128,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.organic,
        boxShadow: const [AppShadows.soft],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle) ...[
            const Icon(Icons.drag_indicator, size: 16, color: AppColors.muted),
            const SizedBox(height: 2),
          ],
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Icon(
              categoryIconFor(place.category.icon),
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            place.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 12,
              color: AppColors.text,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Quitar del itinerario',
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }
}