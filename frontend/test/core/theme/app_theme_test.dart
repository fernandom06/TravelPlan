import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppColors', () {
    test('exact hex values match Artisanal Wanderer palette', () {
      expect(AppColors.primary, const Color(0xFFE07A5F));
      expect(AppColors.background, const Color(0xFFF4F1DE));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.text, const Color(0xFF3D405B));
      expect(AppColors.muted, const Color(0xFFD6CEB6));
      expect(AppColors.accent, const Color(0xFF81B29A));
    });
  });

  group('AppShadows', () {
    test('soft shadow matches token', () {
      const shadow = AppShadows.soft;
      expect(shadow.color, const Color(0x143D405B)); // rgba(61,64,91,0.08)
      expect(shadow.offset, const Offset(0, 8));
      expect(shadow.blurRadius, 24);
    });

    test('terracotta shadow matches token', () {
      const shadow = AppShadows.terracotta;
      expect(shadow.color, const Color(0x33E07A5F)); // rgba(224,122,95,0.2)
      expect(shadow.offset, const Offset(0, 4));
      expect(shadow.blurRadius, 12);
    });
  });

  group('AppRadii', () {
    test('organic radius has asymmetric corners', () {
      const radius = AppRadii.organic;
      expect(radius.topLeft, const Radius.circular(16));
      expect(radius.topRight, const Radius.circular(14));
      expect(radius.bottomRight, const Radius.circular(18));
      expect(radius.bottomLeft, const Radius.circular(12));
    });

    test('pill radius is fully rounded', () {
      const radius = AppRadii.pill;
      expect(radius.topLeft, const Radius.circular(999));
      expect(radius.topRight, const Radius.circular(999));
      expect(radius.bottomRight, const Radius.circular(999));
      expect(radius.bottomLeft, const Radius.circular(999));
    });
  });

  group('AppSpacing', () {
    test('spacing scale is 8/16/24', () {
      expect(AppSpacing.sm, 8);
      expect(AppSpacing.md, 16);
      expect(AppSpacing.lg, 24);
    });
  });

  group('AppTheme.light', () {
    late ThemeData theme;

    setUp(() {
      theme = AppTheme.light();
    });

    test('color scheme uses Artisanal Wanderer primary and surface', () {
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.surface, AppColors.surface);
    });

    test('scaffold background is paper', () {
      expect(theme.scaffoldBackgroundColor, AppColors.background);
    });

    test('text theme uses Fraunces for headings and Lora for body', () {
      expect(theme.textTheme.headlineLarge?.fontFamily, 'Fraunces');
      expect(theme.textTheme.titleLarge?.fontFamily, 'Fraunces');
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Lora');
      expect(theme.textTheme.bodySmall?.fontFamily, 'Lora');
      expect(theme.textTheme.labelLarge?.fontFamily, 'Fraunces');
    });

    test('component themes are wired up', () {
      expect(theme.appBarTheme.centerTitle, isTrue);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.titleTextStyle?.fontFamily, 'Fraunces');
      expect(theme.cardTheme.elevation, 0);
      expect(
        theme.floatingActionButtonTheme.backgroundColor,
        AppColors.primary,
      );
      expect(theme.navigationBarTheme.indicatorColor, AppColors.primary);
      expect(theme.dialogTheme.shape, isNotNull);
      expect(theme.bottomSheetTheme.shape, isNotNull);
    });
  });
}
