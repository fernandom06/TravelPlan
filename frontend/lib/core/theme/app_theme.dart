import 'package:flutter/material.dart';

/// Artisanal Wanderer design tokens.
///
/// Central palette, shadows, radii and spacing used across the app. All visual
/// decisions hang off these constants so components never hardcode Material
/// defaults.
abstract final class AppColors {
  /// Terracotta — primary actions, active states, key accents.
  static const Color primary = Color(0xFFE07A5F);

  /// Paper — main page background.
  static const Color background = Color(0xFFF4F1DE);

  /// White — cards, sheets, pure containers.
  static const Color surface = Color(0xFFFFFFFF);

  /// Navy — headings and main body text.
  static const Color text = Color(0xFF3D405B);

  /// Sand — borders, dividers, disabled states.
  static const Color muted = Color(0xFFD6CEB6);

  /// Mint — success states, nature categories, fresh highlights.
  static const Color accent = Color(0xFF81B29A);
}

abstract final class AppShadows {
  /// Soft ambient shadow for cards and surfaces.
  static const BoxShadow soft = BoxShadow(
    color: Color(0x143D405B), // rgba(61,64,91,0.08)
    offset: Offset(0, 8),
    blurRadius: 24,
  );

  /// Warm terracotta glow for primary elements (FAB, active states).
  static const BoxShadow terracotta = BoxShadow(
    color: Color(0x33E07A5F), // rgba(224,122,95,0.2)
    offset: Offset(0, 4),
    blurRadius: 12,
  );
}

abstract final class AppRadii {
  /// Organic hand-cut radius: top-left 16, top-right 14, bottom-right 18,
  /// bottom-left 12.
  static const BorderRadius organic = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(14),
    bottomRight: Radius.circular(18),
    bottomLeft: Radius.circular(12),
  );

  /// Fully rounded radius for pills and chips.
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

abstract final class AppSpacing {
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
}

/// Material [ThemeData] for the Artisanal Wanderer design system.
abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      outline: AppColors.muted,
      outlineVariant: AppColors.muted,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final textTheme = base.textTheme
        .apply(
          fontFamily: 'Lora',
          bodyColor: AppColors.text,
          displayColor: AppColors.text,
        )
        .copyWith(
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w700,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w700,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w600,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w600,
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        indicatorColor: AppColors.primary,
        elevation: 0,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: 'Lora', fontSize: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.organic),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.muted),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.pill),
        labelStyle: const TextStyle(fontFamily: 'Lora', color: AppColors.text),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.text,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: const TextStyle(
          fontFamily: 'Lora',
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: AppRadii.organic,
          borderSide: const BorderSide(color: AppColors.muted),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.organic,
          borderSide: const BorderSide(color: AppColors.muted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.organic,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}