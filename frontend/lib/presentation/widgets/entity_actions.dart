import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Shared overflow menu wrapper for entities (trip cards, category chips).
///
/// The affordance is decided by [TargetPlatform], NOT by the 800 dp layout
/// breakpoint:
/// - touch platforms (Android/iOS): a long-press anywhere on [child] opens
///   the actions menu.
/// - desktop platforms with a mouse (macOS/Windows/Linux): hovering [child]
///   reveals a ⋮ button (terracotta on a white bubble) that opens the same
///   menu.
///
/// An iPad in horizontal layout (>= 800 dp) still gets long-press menus, while
/// a narrow desktop window (< 800 dp) still gets hover menus.
class EntityActions extends StatefulWidget {
  const EntityActions({
    super.key,
    required this.child,
    this.onEdit,
    this.onDelete,
    this.editLabel = 'Editar',
    this.deleteLabel = 'Borrar',
  });

  final Widget child;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String editLabel;
  final String deleteLabel;

  @override
  State<EntityActions> createState() => _EntityActionsState();
}

class _EntityActionsState extends State<EntityActions> {
  bool _hovering = false;

  bool get _isTouch {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS ||
        platform == TargetPlatform.fuchsia;
  }

  Future<void> _showMenu() async {
    final items = <Widget>[
      if (widget.onEdit != null)
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(widget.editLabel),
          onTap: () {
            Navigator.pop(context);
            widget.onEdit!();
          },
        ),
      if (widget.onDelete != null)
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: Text(widget.deleteLabel),
          onTap: () {
            Navigator.pop(context);
            widget.onDelete!();
          },
        ),
    ];
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: items),
      ),
    );
  }

  void _openMenu() {
    _showMenu();
  }

  @override
  Widget build(BuildContext context) {
    if (_isTouch) {
      return GestureDetector(onLongPress: _openMenu, child: widget.child);
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Stack(
        children: [
          widget.child,
          if (_hovering)
            Positioned(
              top: 8,
              right: 8,
              child: _MoreButton(onPressed: _openMenu),
            ),
        ],
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppShadows.soft.color,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.more_vert, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}
