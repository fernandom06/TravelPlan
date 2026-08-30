import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/trip.dart';
import '../../data/models/trip_status.dart';
import 'app_badge.dart';
import 'entity_actions.dart';

class TripImageError extends StatelessWidget {
  const TripImageError({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image, color: AppColors.muted),
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

/// Polaroid-style trip card: white frame, full-bleed image with a status
/// [AppBadge], Fraunces title and Lora-italic terracotta dates. Edit/delete
/// live behind an [EntityActions] overflow (long-press on touch, hover ⋮ on
/// desktop) and tapping the card opens the trip.
class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.trip,
    required this.baseUrl,
    required this.onEdit,
    required this.onDelete,
    required this.onOpen,
    this.today,
  });

  final Trip trip;
  final String baseUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  /// Reference date for status derivation; defaults to [DateTime.now].
  final DateTime? today;

  TripStatus get _status => TripStatus.fromDates(
    trip.startDate,
    trip.endDate,
    today ?? DateTime.now(),
  );

  (String, Color, Color) get _badge {
    return switch (_status) {
      TripStatus.upcoming => ('PRÓXIMAMENTE', AppColors.primary, Colors.white),
      TripStatus.ongoing => ('EN CURSO', AppColors.accent, Colors.white),
      TripStatus.past => ('PASADO', AppColors.muted, AppColors.text),
    };
  }

  String get _dates =>
      '${_formatDayMonth(trip.startDate)} - ${_formatDayMonth(trip.endDate)}, '
      '${trip.endDate.year}';

  static const _months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  static String _formatDayMonth(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]}';

  Widget _buildImage(BuildContext context) {
    final imageUrl = trip.imageUrl;
    if (imageUrl == null) {
      return Container(
        height: 140,
        color: AppColors.background,
        alignment: Alignment.center,
        child: const Icon(Icons.image, size: 48, color: AppColors.muted),
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
    final (label, badgeColor, badgeTextColor) = _badge;
    return EntityActions(
      onEdit: onEdit,
      onDelete: onDelete,
      child: GestureDetector(
        onTap: onOpen,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.organic,
            boxShadow: const [AppShadows.soft],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _buildImage(context),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: AppBadge(
                      label: label,
                      color: badgeColor,
                      textColor: badgeTextColor,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: AppColors.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dates,
                      style: const TextStyle(
                        fontFamily: 'Lora',
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
