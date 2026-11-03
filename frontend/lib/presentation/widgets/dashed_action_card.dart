import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'dashed_border_container.dart';

/// Dashed add-action card with a centered `+` icon and a call-to-action label.
///
/// Used as the "¿A dónde vamos?" card on the trips screen and the
/// "¿Añadimos un lugar?" card at the end of the itinerary general items
/// carousel. Requires a [Material] ancestor (both call sites live in a
/// [Scaffold]).
class DashedActionCard extends StatelessWidget {
  const DashedActionCard({
    super.key,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  /// Text under the `+` icon.
  final String label;

  /// Invoked when the card is tapped.
  final VoidCallback onTap;

  /// Renders the smaller variant used inside the itinerary list: a 20px `+`
  /// and tighter padding. Defaults to the full card (e.g. the trips screen).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.add,
      size: compact ? 20.0 : 40.0,
      color: AppColors.textSecondary,
    );
    final label = Text(
      this.label,
      textAlign: TextAlign.center,
      maxLines: compact ? 1 : null,
      overflow: compact ? TextOverflow.ellipsis : null,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        // The compact card matches the empty-slot hint ("Arrastra lugares
        // aquí") so both drop affordances read with the same weight; the
        // full card keeps the primary text color.
        color: compact ? AppColors.textSecondary : AppColors.text,
        fontFamily: 'Fraunces',
        fontWeight: FontWeight.w600,
      ),
    );
    final content = compact
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Flexible(child: label),
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [icon, const SizedBox(height: 12), label],
          );
    return DashedBorderContainer(
      color: AppColors.muted,
      radius: 16,
      backgroundColor: AppColors.background.withValues(alpha: 0.4),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}
