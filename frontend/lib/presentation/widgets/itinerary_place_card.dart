import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/category_palette.dart';
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
    this.width,
  });

  final ItineraryItem item;
  final VoidCallback onDelete;
  final bool horizontal;

  /// Optional width for the vertical (non-horizontal) card and its drag
  /// feedback. When null the vertical card keeps its default 104 width.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final content = _MiniCard(
      item: item,
      onDelete: onDelete,
      showDragHandle: true,
      horizontal: horizontal,
      width: width,
    );
    final feedback = Material(
      elevation: 4,
      color: Colors.transparent,
      child: horizontal
          ? SizedBox(
              width: 260,
              child: _MiniCard(item: item, onDelete: () {}),
            )
          : SizedBox(
              width: width,
              child: _MiniCard(
                item: item,
                onDelete: () {},
                horizontal: false,
                width: width,
              ),
            ),
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
    this.width,
  });

  final ItineraryItem item;
  final VoidCallback onDelete;
  final bool showDragHandle;
  final bool horizontal;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final place = item.place;
    final iconCircle = CircleAvatar(
      radius: 17,
      backgroundColor: categoryColorFor(place.category),
      child: Icon(
        categoryIconFor(place.category.icon),
        size: 18,
        color: Colors.white,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
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
                const SizedBox(height: 2),
                Text(
                  place.category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 10,
                    color: AppColors.muted,
                  ),
                ),
              ],
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
          const SizedBox(height: 5),
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
      width: horizontal ? null : (width ?? 104),
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: horizontal ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.organic,
        boxShadow: const [AppShadows.soft],
      ),
      child: content,
    );
  }
}
