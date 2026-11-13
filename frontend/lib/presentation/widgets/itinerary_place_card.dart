import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/category_palette.dart';
import '../../data/category_icon_catalog.dart';
import '../../data/models/itinerary_item.dart';

/// Mini-card for itinerary items: tinted category-icon circle, place name and
/// a trash button, wrapped in a [Draggable] (immediate on desktop, long-press
/// elsewhere) that carries the [ItineraryItem].
///
/// When [onTap] is provided a plain tap opens the move sheet, giving the
/// reordering a non-drag alternative for touch, keyboard and screen-reader
/// users.
class ItineraryPlaceCard extends StatelessWidget {
  const ItineraryPlaceCard({
    super.key,
    required this.item,
    required this.onDelete,
    this.onTap,
    this.horizontal = true,
    this.width,
  });

  final ItineraryItem item;
  final VoidCallback onDelete;

  /// Invoked on a plain tap (as opposed to a drag). Null keeps the card
  /// non-interactive.
  final VoidCallback? onTap;
  final bool horizontal;

  /// Optional width for the vertical (non-horizontal) card and its drag
  /// feedback. When null the vertical card keeps its default 104 width.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final content = _MiniCard(
      item: item,
      onDelete: onDelete,
      showDragHandle: true,
      horizontal: horizontal,
      width: width,
    );
    final interactive = onTap != null
        ? _CardTapSurface(onTap: onTap!, child: content)
        : content;
    final feedback = Material(
      elevation: 4,
      color: Colors.transparent,
      child: horizontal
          ? SizedBox(
              width: 260,
              child: _MiniCard(item: item, onDelete: () {}),
            )
          : SizedBox(
              width: width,
              child: _MiniCard(
                item: item,
                onDelete: () {},
                horizontal: false,
                width: width,
              ),
            ),
    );
    final isDesktop = switch (Theme.of(context).platform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    };
    return isDesktop
        ? Draggable<ItineraryItem>(
            data: item,
            feedback: feedback,
            childWhenDragging: Opacity(opacity: 0.4, child: interactive),
            child: interactive,
          )
        : LongPressDraggable<ItineraryItem>(
            data: item,
            feedback: feedback,
            childWhenDragging: Opacity(opacity: 0.4, child: interactive),
            child: interactive,
          );
  }
}

/// Focusable, semantics-announcing tap surface around the mini-card: a screen
/// reader announces the whole card as one button (its own text as the label,
/// with the delete button as a separate control) and keyboard users activate
/// it with Space, so reaching the move sheet never requires a drag. The
/// focus ring is drawn as a foreground border so the card's own decoration
/// stays untouched.
class _CardTapSurface extends StatefulWidget {
  const _CardTapSurface({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_CardTapSurface> createState() => _CardTapSurfaceState();
}

class _CardTapSurfaceState extends State<_CardTapSurface> {
  bool _showFocusRing = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: FocusableActionDetector(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => widget.onTap(),
          ),
        },
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (value) => setState(() => _showFocusRing = value),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            foregroundDecoration: _showFocusRing
                ? BoxDecoration(
                    borderRadius: AppRadii.organic,
                    border: Border.all(color: AppColors.primary, width: 2),
                  )
                : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.item,
    required this.onDelete,
    this.showDragHandle = false,
    this.horizontal = true,
    this.width,
  });

  final ItineraryItem item;
  final VoidCallback onDelete;
  final bool showDragHandle;
  final bool horizontal;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final place = item.place;
    final iconCircle = CircleAvatar(
      radius: 17,
      backgroundColor: categoryColorFor(place.category),
      child: Icon(
        categoryIconFor(place.category.icon),
        size: 18,
        color: Colors.white,
      ),
    );
    final deleteButton = IconButton(
      icon: const Icon(Icons.delete_outline, size: 16),
      tooltip: 'Quitar del itinerario',
      onPressed: onDelete,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      color: AppColors.textSecondary,
    );

    final Widget content;
    final textTheme = Theme.of(context).textTheme;
    if (horizontal) {
      content = Row(
        children: [
          if (showDragHandle) ...[
            const Icon(
              Icons.drag_indicator,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
          ],
          iconCircle,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  place.category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          deleteButton,
        ],
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle) ...[
            const Icon(
              Icons.drag_indicator,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 2),
          ],
          iconCircle,
          const SizedBox(height: 5),
          Text(
            place.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            place.category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          deleteButton,
        ],
      );
    }

    return Container(
      width: horizontal ? null : (width ?? 104),
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: horizontal ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.organic,
        boxShadow: const [AppShadows.soft],
      ),
      child: content,
    );
  }
}
