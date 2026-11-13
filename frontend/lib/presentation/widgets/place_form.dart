import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/category.dart';
import '../../data/models/place.dart';
import 'category_chip_strip.dart';
import 'sketchbook_name_field.dart';

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
          child: SketchbookNameField(
            controller: nameController,
            focusNode: nameFocus,
            autofocus: autofocus,
            enabled: enabled,
            hint: 'Nombra este rincón...',
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

class PlaceForm extends StatefulWidget {
  const PlaceForm({
    super.key,
    required this.categories,
    required this.onSave,
    required this.onCancel,
    this.initialName,
    this.initialDescription,
    this.initialCategory,
    this.onDelete,
    this.onDraftChanged,
  });

  final List<Category> categories;
  final void Function(String name, int categoryId, String? description) onSave;
  final VoidCallback onCancel;
  final String? initialName;
  final String? initialDescription;
  final Category? initialCategory;
  final VoidCallback? onDelete;

  /// Reports whether the form holds typed content, so hosts can protect the
  /// draft from being discarded by an accidental interaction.
  final ValueChanged<bool>? onDraftChanged;

  @override
  State<PlaceForm> createState() => _PlaceFormState();
}

class _PlaceFormState extends State<PlaceForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final FocusNode _nameFocus;
  late final FocusNode _categoryFocus;
  late final FocusNode _descriptionFocus;
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
    _selectedCategory = widget.initialCategory;
    // Track typed content so hosts (e.g. the map) can protect the draft.
    _nameController.addListener(_notifyDraft);
    _descriptionController.addListener(_notifyDraft);
    // autofocus on the TextField is discarded when the surrounding scope
    // already holds focus (e.g. the map overlay), so also request focus after
    // the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocus.requestFocus();
        _notifyDraft();
      }
    });
  }

  void _notifyDraft() {
    if (!mounted) return;
    widget.onDraftChanged?.call(
      _nameController.text.trim().isNotEmpty ||
          _descriptionController.text.trim().isNotEmpty,
    );
  }

  @override
  void didUpdateWidget(PlaceForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = _selectedCategory;
    if (selected == null) return;
    Category? fresh;
    for (final category in widget.categories) {
      if (category.id == selected.id) {
        fresh = category;
        break;
      }
    }
    _selectedCategory = fresh;
  }

  @override
  void dispose() {
    _nameController.removeListener(_notifyDraft);
    _descriptionController.removeListener(_notifyDraft);
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
      categories: widget.categories,
      value: _selectedCategory,
      focusNode: _categoryFocus,
      onChanged: (c) => setState(() => _selectedCategory = c),
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
