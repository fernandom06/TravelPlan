import 'package:flutter/material.dart';

import '../../data/models/itinerary_item.dart';
import 'itinerary_place_card.dart';

class GeneralItemsSection extends StatelessWidget {
  const GeneralItemsSection({
    super.key,
    required this.items,
    required this.onAcceptItem,
    required this.onDeleteItem,
  });

  final List<ItineraryItem> items;

  /// Llamado al soltar un item sobre la lista general (franja destino null)
  /// con el índice de inserción ("insertar antes") ya calculado.
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
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: Row(
                children: [
                  Text(
                    'Lugares sin colocar',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      '${items.length}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: highlighted
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: items.isEmpty
                  ? _emptyState(context)
                  : Column(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          DragTarget<ItineraryItem>(
                            onAcceptWithDetails: (details) {
                              onAcceptItem(details.data, i);
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

  Widget _emptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      child: Text(
        'Añade lugares al viaje',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}