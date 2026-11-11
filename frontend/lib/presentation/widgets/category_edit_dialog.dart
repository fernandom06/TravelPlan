import 'package:flutter/material.dart';

import '../../data/category_icon_catalog.dart';
import '../../data/models/category.dart';
import '../../data/place_api.dart';
import 'category_icon_picker.dart';

/// Shows the create/rename category dialog.
///
/// Resolves to the saved [Category] on success, or `null` when cancelled. The
/// empty-name and duplicate errors are shown inline and keep the dialog open;
/// any other failure is reported inline with [failureMessage]. A `null` result
/// from [onSubmit] means the caller already reported the failure, so the dialog
/// stays open without adding a message.
Future<Category?> showCategoryEditDialog(
  BuildContext context, {
  required String title,
  String? initialName,
  String? initialIcon,
  required Future<Category?> Function(String name, String? icon) onSubmit,
  required String failureMessage,
}) {
  return showDialog<Category>(
    context: context,
    builder: (_) => _CategoryEditDialog(
      title: title,
      initialName: initialName,
      initialIcon: initialIcon,
      onSubmit: onSubmit,
      failureMessage: failureMessage,
    ),
  );
}

class _CategoryEditDialog extends StatefulWidget {
  const _CategoryEditDialog({
    required this.title,
    required this.onSubmit,
    required this.failureMessage,
    this.initialName,
    this.initialIcon,
  });

  final String title;
  final String? initialName;
  final String? initialIcon;
  final Future<Category?> Function(String name, String? icon) onSubmit;
  final String failureMessage;

  @override
  State<_CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<_CategoryEditDialog> {
  late final TextEditingController _controller;
  late String? _icon;
  String? _error;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _icon = widget.initialIcon;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final result = await pickCategoryIcon(context, current: _icon);
    if (!mounted) return;
    setState(() {
      switch (result) {
        case IconPickerPicked(:final id):
          _icon = id;
        case IconPickerCleared():
          _icon = null;
        case IconPickerCancelled():
          break;
      }
    });
  }

  Future<void> _confirm() async {
    if (_isSubmitting) return;
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'El nombre no puede estar vacío');
      return;
    }
    setState(() {
      _error = null;
      _isSubmitting = true;
    });
    try {
      final category = await widget.onSubmit(name, _icon);
      if (!mounted) return;
      if (category == null) {
        setState(() => _isSubmitting = false);
        return;
      }
      Navigator.pop(context, category);
    } on DuplicateCategoryException {
      if (!mounted) return;
      setState(() {
        _error = 'Ya existe una categoría con ese nombre';
        _isSubmitting = false;
      });
    } on PlaceApiException {
      if (!mounted) return;
      setState(() {
        _error = widget.failureMessage;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = widget.failureMessage;
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _confirm(),
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: Icon(categoryIconFor(_icon)),
                  tooltip: 'Elegir icono',
                  onPressed: _pickIcon,
                ),
                const SizedBox(width: 8),
                Text(
                  _icon == null ? 'Sin icono' : _icon!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _confirm,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
