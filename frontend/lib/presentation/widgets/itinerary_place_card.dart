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
        leading: Icon(categoryIconFor(place.category.icon)),
        title: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Quitar del itinerario',
          onPressed: onDelete,
        ),
      ),
    );
    return LongPressDraggable<ItineraryItem>(
      data: item,
      feedback: Material(
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
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: content),
      child: content,
    );
  }
}
