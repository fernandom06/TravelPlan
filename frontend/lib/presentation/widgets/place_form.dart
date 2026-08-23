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
          key: ValueKey(selectedCategory?.name),
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
  late final TextEditingController _categoryNameController;
  late final TextEditingController _renameNameController;
  late List<Category> _categories;
  Category? _selectedCategory;
  bool _isCreatingCategory = false;
  bool _isSubmittingCategory = false;
  bool _isRenamingCategory = false;
  bool _isSubmittingRename = false;
  bool _isDeletingCategory = false;
  String? _categoryError;
  String? _renameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _categoryNameController = TextEditingController();
    _renameNameController = TextEditingController();
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
    _categoryNameController.dispose();
    _renameNameController.dispose();
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

  Future<void> _handleRenameCategory() async {
    final selected = _selectedCategory;
    final onRenameCategory = widget.onRenameCategory;
    if (selected == null || onRenameCategory == null || _isSubmittingRename) {
      return;
    }
    final name = _renameNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _renameError = 'El nombre no puede estar vacío');
      return;
    }
    setState(() {
      _renameError = null;
      _isSubmittingRename = true;
    });
    try {
      final renamed = await onRenameCategory(selected.id, name);
      if (!mounted) return;
      setState(() {
        _categories = [
          for (final c in _categories) c.id == renamed.id ? renamed : c,
        ];
        _selectedCategory = renamed;
        _isRenamingCategory = false;
        _isSubmittingRename = false;
      });
    } on DuplicateCategoryException {
      if (!mounted) return;
      setState(() {
        _renameError = 'Ya existe una categoría con ese nombre';
        _isSubmittingRename = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _renameError = 'No se pudo renombrar la categoría';
        _isSubmittingRename = false;
      });
    }
  }

  Future<void> _handleDeleteCategory() async {
    final selected = _selectedCategory;
    final onDeleteCategory = widget.onDeleteCategory;
    if (selected == null || onDeleteCategory == null || _isDeletingCategory) {
      return;
    }
    final count = widget.places
        .where((p) => p.category.id == selected.id)
        .length;
    final candidates = _categories.where((c) => c.id != selected.id).toList();
    Category? destination;
    if (count > 0 && candidates.isNotEmpty) {
      destination = candidates.first;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        if (count == 0) {
          return AlertDialog(
            title: const Text('Eliminar categoría'),
            content: Text('Se eliminará "${selected.name}"'),
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
        }
        if (candidates.isEmpty) {
          return AlertDialog(
            title: const Text('No se puede eliminar'),
            content: const Text(
              'Es la única categoría, crea otra antes de eliminar',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
            ],
          );
        }
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Eliminar categoría'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'La categoría tiene $count lugar(es). Elige el destino:',
                  ),
                  DropdownButtonFormField<Category>(
                    initialValue: destination,
                    items: [
                      for (final c in candidates)
                        DropdownMenuItem(value: c, child: Text(c.name)),
                    ],
                    onChanged: (c) => setDialogState(() => destination = c),
                    decoration: const InputDecoration(labelText: 'Mover a'),
                  ),
                ],
              ),
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
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingCategory = true);
    try {
      await onDeleteCategory(selected.id, destination?.id);
      if (!mounted) return;
      setState(() {
        _categories = _categories.where((c) => c.id != selected.id).toList();
        if (_selectedCategory?.id == selected.id) {
          _selectedCategory = null;
        }
        _isDeletingCategory = false;
      });
    } on CategoryNotEmptyException {
      if (!mounted) return;
      setState(() => _isDeletingCategory = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo eliminar: la categoría tiene lugares sin destino',
          ),
        ),
      );
    } on InvalidReassignTargetException {
      if (!mounted) return;
      setState(() => _isDeletingCategory = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El destino no es válido')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeletingCategory = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la categoría')),
      );
    }
  }

  Widget? _buildCategoryActions() {
    final selected = _selectedCategory;
    final hasRename = widget.onRenameCategory != null;
    final hasDelete = widget.onDeleteCategory != null;
    final hasCreate = widget.onCreateCategory != null;
    if (selected == null && !hasCreate) return null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selected != null && (hasRename || hasDelete)) ...[
          Row(
            children: [
              if (hasRename)
                IconButton(
                  onPressed: _isSubmittingRename
                      ? null
                      : () => setState(() {
                          _isRenamingCategory = !_isRenamingCategory;
                          _renameError = null;
                          if (_isRenamingCategory) {
                            _renameNameController.text = selected.name;
                          }
                        }),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Renombrar categoría',
                ),
              if (hasDelete)
                IconButton(
                  onPressed: _isDeletingCategory ? null : _handleDeleteCategory,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Eliminar categoría',
                ),
            ],
          ),
          if (_isRenamingCategory) ...[
            TextField(
              controller: _renameNameController,
              decoration: const InputDecoration(labelText: 'Nuevo nombre'),
            ),
            if (_renameError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _renameError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _isSubmittingRename ? null : _handleRenameCategory,
                child: const Text('Renombrar'),
              ),
            ),
          ],
        ],
        if (hasCreate) ...[
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
              categories: widget.categories,
              nameController: _nameController,
              descriptionController: _descriptionController,
              selectedCategory: widget.place.category,
              onCategoryChanged: null,
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
