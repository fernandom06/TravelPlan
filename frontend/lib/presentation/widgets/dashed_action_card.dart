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
  });

  /// Text under the `+` icon.
  final String label;

  /// Invoked when the card is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DashedBorderContainer(
      color: AppColors.muted,
      radius: 16,
      backgroundColor: AppColors.background.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 40, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.text,
                fontFamily: 'Fraunces',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}