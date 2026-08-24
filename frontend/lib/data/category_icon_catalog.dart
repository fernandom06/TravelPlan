import 'package:flutter/material.dart';

/// A curated, stable identifier for a category icon.
///
/// Slugs are stable strings (not Flutter codepoints) so they can travel
/// through the backend and survive icon set migrations.
class CategoryIconEntry {
  const CategoryIconEntry({required this.id, required this.icon});

  final String id;
  final IconData icon;
}

/// The curated catalog of category icons.
const categoryIconCatalog = <CategoryIconEntry>[
  CategoryIconEntry(id: 'beach', icon: Icons.beach_access),
  CategoryIconEntry(id: 'nature', icon: Icons.park),
  CategoryIconEntry(id: 'monument', icon: Icons.account_balance),
  CategoryIconEntry(id: 'restaurant', icon: Icons.restaurant),
  CategoryIconEntry(id: 'hotel', icon: Icons.hotel),
  CategoryIconEntry(id: 'museum', icon: Icons.museum),
  CategoryIconEntry(id: 'shopping', icon: Icons.shopping_bag),
  CategoryIconEntry(id: 'transport', icon: Icons.directions_bus),
  CategoryIconEntry(id: 'photo', icon: Icons.photo_camera),
  CategoryIconEntry(id: 'star', icon: Icons.star),
  CategoryIconEntry(id: 'cafe', icon: Icons.local_cafe),
  CategoryIconEntry(id: 'bar', icon: Icons.local_bar),
  CategoryIconEntry(id: 'attraction', icon: Icons.attractions),
  CategoryIconEntry(id: 'church', icon: Icons.church),
  CategoryIconEntry(id: 'castle', icon: Icons.castle),
  CategoryIconEntry(id: 'hiking', icon: Icons.hiking),
  CategoryIconEntry(id: 'pool', icon: Icons.pool),
  CategoryIconEntry(id: 'theater', icon: Icons.theater_comedy),
  CategoryIconEntry(id: 'camping', icon: Icons.forest),
  CategoryIconEntry(id: 'gas', icon: Icons.local_gas_station),
];

/// The icon shown for a category without an icon (or with an unknown id).
const categoryPlaceholderIcon = Icons.label_outline;

/// Resolves an icon id to its [IconData], falling back to the placeholder for
/// `null`, empty or unknown ids.
IconData categoryIconFor(String? id) {
  if (id == null || id.isEmpty) return categoryPlaceholderIcon;
  for (final entry in categoryIconCatalog) {
    if (entry.id == id) return entry.icon;
  }
  return categoryPlaceholderIcon;
}