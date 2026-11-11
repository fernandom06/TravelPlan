import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/category_icon_catalog.dart';
import '../../data/models/place.dart';

class PlacePickerDialog extends StatefulWidget {
  const PlacePickerDialog({
    super.key,
    required this.places,
    required this.onPlaceSelected,
  });

  final List<Place> places;
  final void Function(int placeId) onPlaceSelected;

  @override
  State<PlacePickerDialog> createState() => _PlacePickerDialogState();
}

class _PlacePickerDialogState extends State<PlacePickerDialog> {
  int _addedCount = 0;
  String _query = '';

  List<Place> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.places;
    return widget.places
        .where((place) => place.name.toLowerCase().contains(query))
        .toList();
  }

  void _select(Place place) {
    widget.onPlaceSelected(place.id);
    setState(() => _addedCount += 1);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Añadir lugares',
        style: TextStyle(
          fontFamily: 'Fraunces',
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
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
                  ? const Center(
                      child: Text(
                        'No hay lugares',
                        style: TextStyle(
                          fontFamily: 'Lora',
                          color: AppColors.muted,
                        ),
                      ),
                    )
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
                            style: const TextStyle(
                              fontFamily: 'Lora',
                              color: AppColors.text,
                            ),
                          ),
                          onTap: () => _select(place),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: AppRadii.pill,
              ),
              child: Text(
                '$_addedCount añadidos',
                style: const TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
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
}
