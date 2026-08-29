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