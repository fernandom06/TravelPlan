import 'package:flutter/material.dart';

import '../../data/models/category.dart';

/// Curated category colors, one per visual category, in medium/dark tones
/// that stay legible with a white icon on top (Artisanal Wanderer palette).
const List<Color> categoryPalette = <Color>[
  Color(0xFFE07A5F), // terracotta
  Color(0xFF3D405B), // navy
  Color(0xFF5B8E7D), // deep green
  Color(0xFFB97A57), // clay
  Color(0xFF7A6A9B), // mauve
  Color(0xFF4F7C8A), // muted blue
];

/// Deterministically maps a [Category] to one of the [categoryPalette]
/// entries based on its id, so a renamed category keeps its color.
Color categoryColorFor(Category category) {
  return categoryPalette[category.id.abs() % categoryPalette.length];
}
