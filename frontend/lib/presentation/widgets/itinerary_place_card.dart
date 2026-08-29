import 'package:flutter/material.dart';

import '../../data/category_icon_catalog.dart';
import '../../data/models/itinerary_item.dart';

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
    final content = Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_indicator,
              size: 20,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Icon(categoryIconFor(place.category.icon)),
          ],
        ),
        title: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Quitar del itinerario',
          onPressed: onDelete,
        ),
      ),
    );
    final isDesktop = switch (Theme.of(context).platform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    };
    final feedback = Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(categoryIconFor(place.category.icon)),
            const SizedBox(width: 8),
            Text(place.name),
          ],
        ),
      ),
    );
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
