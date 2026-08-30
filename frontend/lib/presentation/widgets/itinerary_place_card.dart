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
    this.horizontal = true,
  });

  final ItineraryItem item;
  final VoidCallback onDelete;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final content = _MiniCard(
      item: item,
      onDelete: onDelete,
      showDragHandle: true,
      horizontal: horizontal,
    );
    final feedback = Material(
      elevation: 4,
      color: Colors.transparent,
      child: horizontal
          ? SizedBox(
              width: 260,
              child: _MiniCard(item: item, onDelete: () {}),
            )
          : _MiniCard(item: item, onDelete: () {}, horizontal: false),
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
    this.horizontal = true,
  });

  final ItineraryItem item;
  final VoidCallback onDelete;
  final bool showDragHandle;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final place = item.place;
    final iconCircle = CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Icon(
        categoryIconFor(place.category.icon),
        size: 16,
        color: AppColors.primary,
      ),
    );
    final deleteButton = IconButton(
      icon: const Icon(Icons.delete_outline, size: 16),
      tooltip: 'Quitar del itinerario',
      onPressed: onDelete,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      color: AppColors.muted,
    );

    final Widget content;
    if (horizontal) {
      content = Row(
        children: [
          if (showDragHandle) ...[
            const Icon(Icons.drag_indicator, size: 16, color: AppColors.muted),
            const SizedBox(width: 6),
          ],
          iconCircle,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              place.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(width: 4),
          deleteButton,
        ],
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle) ...[
            const Icon(Icons.drag_indicator, size: 14, color: AppColors.muted),
            const SizedBox(height: 2),
          ],
          iconCircle,
          const SizedBox(height: 6),
          Text(
            place.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            place.category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 10,
              color: AppColors.muted,
            ),
          ),
          deleteButton,
        ],
      );
    }

    return Container(
      width: horizontal ? null : 104,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.organic,
        boxShadow: const [AppShadows.soft],
      ),
      child: content,
    );
  }
}
