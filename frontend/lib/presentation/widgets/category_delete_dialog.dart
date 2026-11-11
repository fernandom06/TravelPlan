import 'package:flutter/material.dart';

import '../../data/models/category.dart';

/// Shows the delete-category flow and resolves to `(confirmed, reassignTo)`.
///
/// The dialog chosen mirrors the rules that lived inline in the chip strip:
/// - no places: simple confirmation, no reassignment;
/// - places and other categories: destination dropdown (defaults to the first
///   candidate), reassignment required;
/// - places and it is the only category: blocked warning with no delete action.
Future<(bool, int?)> showCategoryDeleteDialog(
  BuildContext context, {
  required Category category,
  required int placeCount,
  required List<Category> candidates,
}) async {
  if (placeCount == 0) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('Se eliminará "${category.name}"'),
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
      ),
    );
    return (confirmed == true, null);
  }

  if (candidates.isEmpty) {
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
      ),
    );
    return (false, null);
  }

  Category? destination = candidates.first;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('La categoría tiene $placeCount lugar(es). Elige el destino:'),
            DropdownButtonFormField<Category>(
              initialValue: destination,
              items: [
                for (final candidate in candidates)
                  DropdownMenuItem(
                    value: candidate,
                    child: Text(candidate.name),
                  ),
              ],
              onChanged: (value) => setDialogState(() => destination = value),
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
      ),
    ),
  );
  if (confirmed != true) return (false, null);
  return (true, destination?.id);
}
