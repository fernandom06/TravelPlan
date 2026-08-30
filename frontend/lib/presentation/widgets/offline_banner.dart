import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Offline indicator styled with design tokens: a soft paper/terracotta tone
/// with a sand bottom border, navy Lora text and a terracotta wifi_off icon.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.muted, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Sin conexión con el servidor',
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 13,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
