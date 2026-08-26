import 'package:flutter/material.dart';

import '../../data/category_icon_catalog.dart';

/// The outcome of the category icon picker.
///
/// A sealed class so callers must handle every case explicitly:
///  - [IconPickerCancelled]: the dialog was dismissed without choosing;
///    the previous icon should be kept.
///  - [IconPickerCleared]: the user chose "Sin icono"; the icon is cleared.
///  - [IconPickerPicked]: the user chose a concrete icon id.
sealed class IconPickerResult {
  const IconPickerResult();
}

class IconPickerCancelled extends IconPickerResult {
  const IconPickerCancelled();
}

class IconPickerCleared extends IconPickerResult {
  const IconPickerCleared();
}

class IconPickerPicked extends IconPickerResult {
  const IconPickerPicked(this.id);

  final String id;
}

/// Shows the category icon picker and resolves to an [IconPickerResult].
///
/// Barrier/Escape dismissal (which pops the dialog with `null`) is mapped to
/// [IconPickerCancelled] so callers can switch exhaustively over the three
/// result subtypes without a null case.
Future<IconPickerResult> pickCategoryIcon(
  BuildContext context, {
  String? current,
}) async {
  final result = await showDialog<IconPickerResult>(
    context: context,
    builder: (dialogContext) => _CategoryIconPickerDialog(current: current),
  );
  return result ?? const IconPickerCancelled();
}

class _CategoryIconPickerDialog extends StatelessWidget {
  const _CategoryIconPickerDialog({this.current});

  final String? current;

  void _pop(BuildContext context, IconPickerResult result) {
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Elegir icono'),
      content: SizedBox(
        width: 360,
        child: GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _IconTile(
              icon: categoryPlaceholderIcon,
              label: 'Sin icono',
              selected: current == null,
              onTap: () => _pop(context, const IconPickerCleared()),
            ),
            for (final entry in categoryIconCatalog)
              _IconTile(
                icon: entry.icon,
                label: entry.id,
                selected: current == entry.id,
                onTap: () => _pop(context, IconPickerPicked(entry.id)),
              ),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? colorScheme.primaryContainer : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: selected ? colorScheme.onPrimaryContainer : null,
          ),
        ),
      ),
    );
  }
}
