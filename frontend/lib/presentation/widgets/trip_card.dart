import 'package:flutter/material.dart';

import '../../data/models/trip.dart';

class TripImageError extends StatelessWidget {
  const TripImageError({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 4),
          Text(
            'Imagen no disponible',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.trip,
    required this.baseUrl,
    required this.onEdit,
    required this.onDelete,
  });

  final Trip trip;
  final String baseUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _dates =>
      '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}';

  static String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  Widget _buildImage(BuildContext context) {
    final imageUrl = trip.imageUrl;
    if (imageUrl == null) {
      return Container(
        height: 140,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.image,
          size: 48,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }
    return Image.network(
      trip.displayImageUrl(baseUrl),
      height: 140,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const TripImageError(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(context),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(_dates, style: Theme.of(context).textTheme.bodySmall),
                if (trip.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    trip.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: onEdit,
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: onDelete,
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
