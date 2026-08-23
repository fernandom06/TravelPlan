import 'package:flutter/material.dart';

import '../../data/models/category.dart';
import '../../data/models/place.dart';

class _PlaceFields extends StatelessWidget {
  const _PlaceFields({
    required this.categories,
    required this.nameController,
    required this.descriptionController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onNameChanged,
    required this.enabled,
  });

  final List<Category> categories;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final Category? selectedCategory;
  final ValueChanged<Category?>? onCategoryChanged;
  final ValueChanged<String>? onNameChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: nameController,
          enabled: enabled,
          onChanged: onNameChanged,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Category>(
          initialValue: selectedCategory,
          items: categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
              .toList(),
          onChanged: onCategoryChanged,
          decoration: const InputDecoration(labelText: 'Categoría'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: descriptionController,
          enabled: enabled,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Descripción'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

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
            _PlaceFields(
              categories: widget.categories,
              nameController: _nameController,
              descriptionController: _descriptionController,
              selectedCategory: _selectedCategory,
              onCategoryChanged: _readOnly
                  ? null
                  : (c) => setState(() => _selectedCategory = c),
              onNameChanged: _readOnly ? null : (_) => setState(() {}),
              enabled: !_readOnly,
            ),
            if (_readOnly)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cerrar'),
                ),
              )
            else
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancelar'),
                  ),
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
