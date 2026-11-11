import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/category_icon_catalog.dart';
import '../../data/models/category.dart';

/// Horizontal scrollable strip of category pills, used as a pure selector.
///
/// - Selected pill: mint fill, white icon+text, slightly scaled up.
/// - Unselected pill: white with a 2px sand border, navy text.
///
/// Managing categories (create, rename, delete, icon) lives in the settings
/// page, so the strip only reports selection through [onChanged].
class CategoryChipStrip extends StatefulWidget {
  const CategoryChipStrip({
    super.key,
    required this.categories,
    this.value,
    this.enabled = true,
    required this.onChanged,
    this.focusNode,
  });

  final List<Category> categories;
  final Category? value;
  final bool enabled;
  final ValueChanged<Category?> onChanged;
  final FocusNode? focusNode;

  @override
  State<CategoryChipStrip> createState() => _CategoryChipStripState();
}

class _CategoryChipStripState extends State<CategoryChipStrip> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: const NumericFocusOrder(1),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 4),
            for (final category in widget.categories)
              _CategoryChip(
                category: category,
                selected: widget.value?.id == category.id,
                enabled: widget.enabled,
                onTap: widget.enabled ? () => widget.onChanged(category) : null,
              ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.text;
    final bg = selected ? AppColors.accent : AppColors.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedScale(
        scale: selected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Material(
          color: bg,
          shape: StadiumBorder(
            side: selected
                ? BorderSide.none
                : const BorderSide(color: AppColors.muted, width: 2),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(categoryIconFor(category.icon), size: 16, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: TextStyle(
                      color: fg,
                      fontFamily: 'Lora',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
