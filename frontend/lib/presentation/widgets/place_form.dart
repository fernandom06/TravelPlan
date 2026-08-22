import 'package:flutter/material.dart';

import '../../data/models/category.dart';
import '../../data/models/place.dart';

class PlaceForm extends StatefulWidget {
  const PlaceForm({
    super.key,
    required this.categories,
    required this.onSave,
    required this.onCancel,
    this.place,
  });

  final List<Category> categories;
  final Place? place;
  final void Function(String name, int categoryId, String? description) onSave;
  final void Function() onCancel;

  @override
  State<PlaceForm> createState() => _PlaceFormState();
}

class _PlaceFormState extends State<PlaceForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  Category? _selectedCategory;

  bool get _readOnly => widget.place != null;

  @override
  void initState() {
    super.initState();
    final place = widget.place;
    _nameController = TextEditingController(text: place?.name ?? '');
    _descriptionController = TextEditingController(text: place?.description ?? '');
    _selectedCategory = place?.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_readOnly &&
      _nameController.text.trim().isNotEmpty &&
      _selectedCategory != null;

  void _handleSave() {
    final description = _descriptionController.text.trim();
    widget.onSave(
      _nameController.text.trim(),
      _selectedCategory!.id,
      description.isEmpty ? null : description,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_readOnly,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Category>(
              value: _selectedCategory,
              items: widget.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: _readOnly
                  ? null
                  : (c) => setState(() => _selectedCategory = c),
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              enabled: !_readOnly,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 16),
            if (_readOnly)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cerrar'),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _canSave ? _handleSave : null,
                    child: const Text('Guardar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
