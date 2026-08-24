import 'package:flutter/material.dart';

import '../../data/models/category.dart';
import '../../data/models/place.dart';
import 'category_dropdown.dart';

class _PlaceFields extends StatelessWidget {
  const _PlaceFields({
    required this.nameController,
    required this.descriptionController,
    required this.categoryField,
    required this.onNameChanged,
    required this.enabled,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final Widget categoryField;
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
        categoryField,
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
    this.onCreateCategory,
    this.places = const [],
    this.onRenameCategory,
    this.onDeleteCategory,
    this.initialName,
    this.initialDescription,
    this.initialCategory,
    this.onDelete,
  });

  final List<Category> categories;
  final void Function(String name, int categoryId, String? description) onSave;
  final VoidCallback onCancel;
  final Future<Category> Function(String name)? onCreateCategory;
  final List<Place> places;
  final Future<Category> Function(int id, String name)? onRenameCategory;
  final Future<void> Function(int id, int? reassignTo)? onDeleteCategory;
  final String? initialName;
  final String? initialDescription;
  final Category? initialCategory;
  final VoidCallback? onDelete;

  @override
  State<PlaceForm> createState() => _PlaceFormState();
}

class _PlaceFormState extends State<PlaceForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late List<Category> _categories;
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _categories = List.of(widget.categories);
    _selectedCategory = widget.initialCategory;
  }

  @override
  void didUpdateWidget(PlaceForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final knownIds = {for (final c in _categories) c.id};
    final additions = widget.categories
        .where((c) => !knownIds.contains(c.id))
        .toList();
    if (additions.isNotEmpty) {
      _categories = [..._categories, ...additions];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _selectedCategory != null;

  void _handleSave() {
    final description = _descriptionController.text.trim();
    widget.onSave(
      _nameController.text.trim(),
      _selectedCategory!.id,
      description.isEmpty ? null : description,
    );
  }

  Future<void> _handleDeleteTap() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar lugar'),
          content: const Text('¿Eliminar este lugar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    onDelete();
  }

  Widget _buildCategoryField() {
    return CategoryDropdown(
      categories: _categories,
      value: _selectedCategory,
      places: widget.places,
      onCreate: widget.onCreateCategory,
      onRename: widget.onRenameCategory,
      onDelete: widget.onDeleteCategory,
      onChanged: (c) => setState(() => _selectedCategory = c),
      onCategoryAdded: (c) => setState(() => _categories = [..._categories, c]),
      onCategoryRenamed: (c) => setState(() {
        _categories = [for (final x in _categories) x.id == c.id ? c : x];
        if (_selectedCategory?.id == c.id) {
          _selectedCategory = c;
        }
      }),
      onCategoryDeleted: (id) => setState(() {
        _categories = _categories.where((x) => x.id != id).toList();
        if (_selectedCategory?.id == id) {
          _selectedCategory = null;
        }
      }),
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
              nameController: _nameController,
              descriptionController: _descriptionController,
              categoryField: _buildCategoryField(),
              onNameChanged: (_) => setState(() {}),
              enabled: true,
            ),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                if (widget.onDelete != null)
                  TextButton(
                    onPressed: _handleDeleteTap,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Eliminar'),
                  ),
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

class PlaceDetails extends StatefulWidget {
  const PlaceDetails({
    super.key,
    required this.categories,
    required this.place,
    required this.onClose,
    this.onEdit,
  });

  final List<Category> categories;
  final Place place;
  final VoidCallback onClose;
  final VoidCallback? onEdit;

  @override
  State<PlaceDetails> createState() => _PlaceDetailsState();
}

class _PlaceDetailsState extends State<PlaceDetails> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.place.name);
    _descriptionController = TextEditingController(
      text: widget.place.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
              nameController: _nameController,
              descriptionController: _descriptionController,
              categoryField: CategoryDropdown(
                categories: widget.categories,
                value: widget.place.category,
                enabled: false,
                onChanged: (_) {},
              ),
              onNameChanged: null,
              enabled: false,
            ),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                if (widget.onEdit != null)
                  OutlinedButton(
                    onPressed: widget.onEdit,
                    child: const Text('Editar'),
                  ),
                TextButton(
                  onPressed: widget.onClose,
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
