import 'package:flutter/material.dart';

import '../../data/models/category.dart';
import '../../data/models/place.dart';
import '../../data/place_api.dart';

class _PlaceFields extends StatelessWidget {
  const _PlaceFields({
    required this.categories,
    required this.nameController,
    required this.descriptionController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onNameChanged,
    required this.enabled,
    this.categoryActions,
  });

  final List<Category> categories;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final Category? selectedCategory;
  final ValueChanged<Category?>? onCategoryChanged;
  final ValueChanged<String>? onNameChanged;
  final bool enabled;
  final Widget? categoryActions;

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
        ?categoryActions,
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
  });

  final List<Category> categories;
  final void Function(String name, int categoryId, String? description) onSave;
  final VoidCallback onCancel;
  final Future<Category> Function(String name)? onCreateCategory;

  @override
  State<PlaceForm> createState() => _PlaceFormState();
}

class _PlaceFormState extends State<PlaceForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryNameController;
  late List<Category> _categories;
  Category? _selectedCategory;
  bool _isCreatingCategory = false;
  bool _isSubmittingCategory = false;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _categoryNameController = TextEditingController();
    _categories = List.of(widget.categories);
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
    _categoryNameController.dispose();
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

  Future<void> _handleCreateCategory() async {
    final name = _categoryNameController.text.trim();
    final onCreateCategory = widget.onCreateCategory;
    if (name.isEmpty || onCreateCategory == null || _isSubmittingCategory) {
      return;
    }
    setState(() {
      _categoryError = null;
      _isSubmittingCategory = true;
    });
    try {
      final category = await onCreateCategory(name);
      if (!mounted) return;
      setState(() {
        _categories = [..._categories, category];
        _categoryNameController.clear();
        _isSubmittingCategory = false;
      });
    } on DuplicateCategoryException {
      if (!mounted) return;
      setState(() {
        _categoryError = 'Ya existe una categoría con ese nombre';
        _isSubmittingCategory = false;
      });
    } on PlaceApiException {
      if (!mounted) return;
      setState(() {
        _categoryError = 'No se pudo crear la categoría';
        _isSubmittingCategory = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categoryError = 'No se pudo crear la categoría';
        _isSubmittingCategory = false;
      });
    }
  }

  Widget? _buildCategoryActions() {
    if (widget.onCreateCategory == null) return null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _isSubmittingCategory
                ? null
                : () => setState(() {
                    _isCreatingCategory = !_isCreatingCategory;
                    _categoryError = null;
                  }),
            icon: const Icon(Icons.add),
            label: const Text('Nueva categoría'),
          ),
        ),
        if (_isCreatingCategory) ...[
          TextField(
            controller: _categoryNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la categoría',
            ),
          ),
          if (_categoryError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _categoryError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _isSubmittingCategory ? null : _handleCreateCategory,
              child: const Text('Crear'),
            ),
          ),
        ],
      ],
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
              categories: _categories,
              nameController: _nameController,
              descriptionController: _descriptionController,
              selectedCategory: _selectedCategory,
              onCategoryChanged: (c) => setState(() => _selectedCategory = c),
              onNameChanged: (_) => setState(() {}),
              enabled: true,
              categoryActions: _buildCategoryActions(),
            ),
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

class PlaceDetails extends StatefulWidget {
  const PlaceDetails({
    super.key,
    required this.categories,
    required this.place,
    required this.onClose,
  });

  final List<Category> categories;
  final Place place;
  final VoidCallback onClose;

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
              categories: widget.categories,
              nameController: _nameController,
              descriptionController: _descriptionController,
              selectedCategory: widget.place.category,
              onCategoryChanged: null,
              onNameChanged: null,
              enabled: false,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onClose,
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
