import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/category.dart';
import '../../data/models/place.dart';
import 'category_chip_strip.dart';

class _PlaceFields extends StatelessWidget {
  const _PlaceFields({
    required this.nameController,
    required this.descriptionController,
    required this.categoryField,
    required this.onNameChanged,
    required this.enabled,
    this.nameFocus,
    this.descriptionFocus,
    this.autofocus = false,
    this.onNameNext,
    this.onDescriptionSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final Widget categoryField;
  final ValueChanged<String>? onNameChanged;
  final bool enabled;
  final FocusNode? nameFocus;
  final FocusNode? descriptionFocus;
  final bool autofocus;
  final VoidCallback? onNameNext;
  final VoidCallback? onDescriptionSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FocusTraversalOrder(
          order: const NumericFocusOrder(0),
          child: _WireframeNameField(
            controller: nameController,
            focusNode: nameFocus,
            autofocus: autofocus,
            enabled: enabled,
            onChanged: onNameChanged,
            textInputAction: onNameNext == null ? null : TextInputAction.next,
            onSubmitted: onNameNext == null ? null : (_) => onNameNext!(),
          ),
        ),
        const SizedBox(height: 16),
        categoryField,
        const SizedBox(height: 16),
        FocusTraversalOrder(
          order: NumericFocusOrder((1 << 20).toDouble()),
          child: TextField(
            controller: descriptionController,
            focusNode: descriptionFocus,
            enabled: enabled,
            maxLines: 3,
            textInputAction: onDescriptionSubmit == null
                ? null
                : TextInputAction.done,
            onSubmitted: onDescriptionSubmit == null
                ? null
                : (_) => onDescriptionSubmit!(),
            decoration: const InputDecoration(
              labelText: 'Descripción',
              labelStyle: TextStyle(fontFamily: 'Lora', color: AppColors.text),
              filled: true,
              fillColor: Color(0x80F4F1DE), // paper tone
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Sketchbook-style title input: Fraunces 600, no border by default, a sand
/// underline on hover and a terracotta underline on focus.
class _WireframeNameField extends StatefulWidget {
  const _WireframeNameField({
    required this.controller,
    this.focusNode,
    required this.enabled,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  State<_WireframeNameField> createState() => _WireframeNameFieldState();
}

class _WireframeNameFieldState extends State<_WireframeNameField> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        style: const TextStyle(
          fontFamily: 'Fraunces',
          fontWeight: FontWeight.w600,
          fontSize: 24,
          color: AppColors.text,
        ),
        decoration: InputDecoration(
          hintText: 'Nombra este rincón...',
          hintStyle: const TextStyle(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: AppColors.muted,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: _hovered ? AppColors.muted : Colors.transparent,
              width: 1,
            ),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
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
  final Future<Category> Function(String name, String? icon)? onCreateCategory;
  final List<Place> places;
  final Future<Category> Function(int id, String name, String? icon)?
  onRenameCategory;
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
  late final FocusNode _nameFocus;
  late final FocusNode _categoryFocus;
  late final FocusNode _descriptionFocus;
  late List<Category> _categories;
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _nameFocus = FocusNode();
    _categoryFocus = FocusNode();
    _descriptionFocus = FocusNode();
    _categories = List.of(widget.categories);
    _selectedCategory = widget.initialCategory;
    // autofocus on the TextField is discarded when the surrounding scope
    // already holds focus (e.g. the map overlay), so also request focus after
    // the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocus.requestFocus();
    });
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
    _nameFocus.dispose();
    _categoryFocus.dispose();
    _descriptionFocus.dispose();
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

  void _submit() {
    if (!_canSave) return;
    _handleSave();
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
    return CategoryChipStrip(
      categories: _categories,
      value: _selectedCategory,
      places: widget.places,
      focusNode: _categoryFocus,
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
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _PlaceFields(
              nameController: _nameController,
              descriptionController: _descriptionController,
              categoryField: _buildCategoryField(),
              onNameChanged: (_) => setState(() {}),
              enabled: true,
              nameFocus: _nameFocus,
              descriptionFocus: _descriptionFocus,
              autofocus: true,
              onNameNext: () => _categoryFocus.requestFocus(),
              onDescriptionSubmit: _submit,
            ),
          ),
          const SizedBox(height: 16),
          _FormFooter(
            onDelete: widget.onDelete == null ? null : _handleDeleteTap,
            onCancel: widget.onCancel,
            onSave: _canSave ? _handleSave : null,
            saveLabel: 'Guardar Lugar',
          ),
        ],
      ),
    );
  }
}

/// Sticky-looking footer with a terracotta primary button.
class _FormFooter extends StatelessWidget {
  const _FormFooter({
    required this.onDelete,
    required this.onCancel,
    required this.onSave,
    required this.saveLabel,
  });

  final VoidCallback? onDelete;
  final VoidCallback onCancel;
  final VoidCallback? onSave;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.muted.withValues(alpha: 0.5)),
        ),
      ),
      child: OverflowBar(
        alignment: MainAxisAlignment.end,
        spacing: 8,
        children: [
          if (onDelete != null)
            TextButton(
              onPressed: onDelete,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Eliminar'),
            ),
          TextButton(onPressed: onCancel, child: const Text('Cancelar')),
          FilledButton(
            onPressed: onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(96, 48),
            ),
            child: Text(saveLabel),
          ),
        ],
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _PlaceFields(
            nameController: _nameController,
            descriptionController: _descriptionController,
            categoryField: CategoryChipStrip(
              categories: widget.categories,
              value: widget.place.category,
              enabled: false,
              onChanged: (_) {},
            ),
            onNameChanged: null,
            enabled: false,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.muted.withValues(alpha: 0.5)),
            ),
          ),
          child: OverflowBar(
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
        ),
      ],
    );
  }
}
