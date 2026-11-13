import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/category_icon_catalog.dart';
import '../../data/models/place.dart';

class PlacePickerDialog extends StatefulWidget {
  const PlacePickerDialog({
    super.key,
    required this.places,
    required this.onPlaceSelected,
    this.subtitle,
  });

  final List<Place> places;

  /// Where the picked places will land, e.g. "Mañana · Día 2 · 05 Jun" when
  /// the picker was opened from an empty slot. Null for the general picker.
  final String? subtitle;

  /// Called on every tap: the same place may be added more than once —
  /// visiting a spot twice on different days is a legitimate plan. Rows
  /// added during this dialog session show a "ya añadido" badge so the
  /// count alone is not the only signal of what was picked.
  final void Function(int placeId) onPlaceSelected;

  @override
  State<PlacePickerDialog> createState() => _PlacePickerDialogState();
}

class _PlacePickerDialogState extends State<PlacePickerDialog> {
  int _addedCount = 0;
  String _query = '';

  /// Places picked since the dialog opened, for the per-row badge. The
  /// rows stay tappable: adding the same place again remains legal.
  final Set<int> _addedIds = {};

  List<Place> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.places;
    return widget.places
        .where((place) => place.name.toLowerCase().contains(query))
        .toList();
  }

  void _select(Place place) {
    widget.onPlaceSelected(place.id);
    setState(() {
      _addedCount += 1;
      _addedIds.add(place.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Añadir lugares',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          if (widget.subtitle != null)
            Text(
              widget.subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
        ],
      ),
      content: SizedBox(
        width: 320,
        height: 360,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar lugar',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? _emptyMessage()
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final place = _filtered[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.15,
                            ),
                            child: Icon(
                              categoryIconFor(place.category.icon),
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            place.name,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.text),
                          ),
                          // Marks which rows were picked during this dialog
                          // session without blocking them: the badge speaks,
                          // the row stays tappable for repeat visits.
                          trailing: _addedIds.contains(place.id)
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: AppRadii.pill,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: AppColors.text,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Añadido',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.text,
                                            ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                          onTap: () => _select(place),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            // Live region: a screen reader announces the count as it grows,
            // instead of leaving the feedback count-only and silent.
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: AppRadii.pill,
                ),
                child: Text(
                  _addedCountLabel(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  /// Distinguishes "no places in the trip yet" from "the search found
  /// nothing"; both need a different next step.
  Widget _emptyMessage() {
    final textTheme = Theme.of(context).textTheme;
    if (widget.places.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.travel_explore, size: 24, color: AppColors.muted),
            const SizedBox(height: 6),
            Text(
              'Todavía no hay lugares en el viaje',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 24, color: AppColors.muted),
          const SizedBox(height: 6),
          Text(
            'Ningún lugar coincide con la búsqueda',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _addedCountLabel() => switch (_addedCount) {
    0 => '0 añadidos',
    1 => '1 añadido',
    _ => '$_addedCount añadidos',
  };
}
