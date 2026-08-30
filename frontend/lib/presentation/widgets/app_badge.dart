import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Small pill-shaped status label: uppercase, tracked, bold 10px text on a
/// solid color capsule (e.g. PRÓXIMAMENTE / EN CURSO / PASADO).
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
    this.icon,
  });

  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: AppRadii.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Lora',
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
