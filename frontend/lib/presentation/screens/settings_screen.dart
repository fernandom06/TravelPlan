import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/category.dart';
import '../../data/models/place.dart';
import '../widgets/category_settings_section.dart';
import '../widgets/offline_banner.dart';

/// Settings page: a plain stack of visible sections, categories first.
///
/// Like the other top-level tabs it shows the [OfflineBanner] when the
/// backend is unreachable, and constrains its content column on wide
/// layouts so row actions stay near their rows.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.categories,
    required this.places,
    required this.isOnline,
    required this.onCreate,
    required this.onRename,
    required this.onDelete,
  });

  /// Maximum width of the content column on layouts wider than it.
  static const double _contentMaxWidth = 640;

  final List<Category> categories;
  final List<Place> places;
  final bool isOnline;
  final Future<Category> Function(String name, String? icon) onCreate;
  final Future<Category> Function(int id, String name, String? icon) onRename;
  final Future<void> Function(int id, int? reassignTo) onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (!isOnline) const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ajustes',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: AppColors.text),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CategorySettingsSection(
                        categories: categories,
                        places: places,
                        isOnline: isOnline,
                        onCreate: onCreate,
                        onRename: onRename,
                        onDelete: onDelete,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
