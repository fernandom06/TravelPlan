import 'package:flutter/material.dart';

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
      title: const Text('Añadir lugares'),
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
                  ? Center(
                      child: Text(
                        'No hay lugares',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final place = _filtered[index];
                        return ListTile(
                          leading: Icon(categoryIconFor(place.category.icon)),
                          title: Text(place.name),
                          onTap: () => _select(place),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_addedCount añadidos',
              style: Theme.of(context).textTheme.bodySmall,
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