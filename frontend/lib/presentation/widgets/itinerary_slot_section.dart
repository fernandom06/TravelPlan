import 'package:flutter/material.dart';

import '../../data/models/itinerary_item.dart';
import '../../data/models/itinerary_slot.dart';
import 'itinerary_place_card.dart';

class ItinerarySlotSection extends StatelessWidget {
  const ItinerarySlotSection({
    super.key,
    required this.title,
    required this.slot,
    required this.items,
    required this.onAcceptItem,
    required this.onDeleteItem,
  });

  final String title;
  final ItinerarySlot slot;
  final List<ItineraryItem> items;

  /// Llamado al soltar un item sobre esta franja con el índice de inserción
  /// ("insertar antes") ya calculado.
  final void Function(ItineraryItem item, ItinerarySlot slot, int index)
  onAcceptItem;
  final void Function(int itemId) onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ItineraryItem>(
      onAcceptWithDetails: (details) {
        onAcceptItem(details.data, slot, items.length);
      },
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: highlighted
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: items.isEmpty
                  ? _emptyState(context, highlighted)
                  : Column(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          DragTarget<ItineraryItem>(
                            onAcceptWithDetails: (details) {
                              onAcceptItem(details.data, slot, i);
                            },
                            builder: (context, _, _) => ItineraryPlaceCard(
                              item: items[i],
                              onDelete: () => onDeleteItem(items[i].id),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _emptyState(BuildContext context, bool highlighted) {
    return Container(
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      child: Text(
        'Arrastra un lugar aquí',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: highlighted
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
