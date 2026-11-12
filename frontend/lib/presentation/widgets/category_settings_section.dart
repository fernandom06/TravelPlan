import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/category_icon_catalog.dart';
import '../../data/models/category.dart';
import '../../data/models/place.dart';
import '../../data/place_api.dart';
import 'category_delete_dialog.dart';
import 'category_edit_dialog.dart';
import 'entity_actions.dart';

/// The "Categorías" section of the settings page.
///
/// It is a passive widget: the owner (`HomeScreen`) injects the category and
/// place lists from the shared `PlacesController` plus the callbacks that
/// mutate it. The section only orchestrates dialogs and messages.
class CategorySettingsSection extends StatefulWidget {
  const CategorySettingsSection({
    super.key,
    required this.categories,
    required this.places,
    required this.isOnline,
    required this.onCreate,
    required this.onRename,
    required this.onDelete,
  });

  final List<Category> categories;
  final List<Place> places;
  final bool isOnline;
  final Future<Category> Function(String name, String? icon) onCreate;
  final Future<Category> Function(int id, String name, String? icon) onRename;
  final Future<void> Function(int id, int? reassignTo) onDelete;

  @override
  State<CategorySettingsSection> createState() =>
      _CategorySettingsSectionState();
}

class _CategorySettingsSectionState extends State<CategorySettingsSection> {
  Future<void> _openCreate() async {
    await showCategoryEditDialog(
      context,
      title: 'Nueva categoría',
      onSubmit: _submitCreate,
      failureMessage: 'No se pudo crear la categoría',
    );
  }

  Future<Category?> _submitCreate(String name, String? icon) async {
    if (!widget.isOnline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sin conexión')));
      return null;
    }
    return widget.onCreate(name, icon);
  }

  Future<void> _openEdit(Category category) async {
    if (!widget.isOnline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sin conexión')));
      return;
    }
    await showCategoryEditDialog(
      context,
      title: 'Editar categoría',
      initialName: category.name,
      initialIcon: category.icon,
      onSubmit: (name, icon) => widget.onRename(category.id, name, icon),
      failureMessage: 'No se pudo renombrar la categoría',
    );
  }

  Future<void> _handleDelete(Category category) async {
    if (!widget.isOnline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sin conexión')));
      return;
    }
    final placeCount = widget.places
        .where((place) => place.category.id == category.id)
        .length;
    final candidates = widget.categories
        .where((candidate) => candidate.id != category.id)
        .toList();
    final (confirmed, reassignTo) = await showCategoryDeleteDialog(
      context,
      category: category,
      placeCount: placeCount,
      candidates: candidates,
    );
    if (!confirmed || !mounted) return;
    try {
      await widget.onDelete(category.id, reassignTo);
    } on CategoryNotEmptyException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo eliminar: la categoría tiene lugares sin destino',
          ),
        ),
      );
    } on InvalidReassignTargetException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El destino no es válido')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la categoría')),
      );
    }
  }

  bool get _isTouch {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS ||
        platform == TargetPlatform.fuchsia;
  }

  void _showRowMenu(Category category) {
    showEntityActionsMenu(
      context,
      onEdit: () => _openEdit(category),
      onDelete: () => _handleDelete(category),
    );
  }

  Widget _buildRow(Category category) {
    final row = ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(categoryIconFor(category.icon), color: AppColors.text),
      title: Text(
        category.name,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openEdit(category),
          ),
          IconButton(
            tooltip: 'Borrar',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _handleDelete(category),
          ),
        ],
      ),
    );
    if (!_isTouch) return row;
    return GestureDetector(
      onLongPress: () => _showRowMenu(category),
      child: row,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorías',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (widget.categories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Aún no hay categorías. Crea una para clasificar tus lugares.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        for (final category in widget.categories) _buildRow(category),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: _openCreate,
          icon: const Icon(Icons.add),
          label: const Text('Añadir categoría'),
        ),
      ],
    );
  }
}
