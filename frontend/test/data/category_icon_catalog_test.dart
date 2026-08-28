import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/category_icon_catalog.dart';

void main() {
  group('categoryIconCatalog', () {
    test('has no empty or duplicate ids', () {
      final ids = categoryIconCatalog.map((e) => e.id).toList();

      expect(ids, isNotEmpty);
      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(id, isNotEmpty);
      }
    });

    test('covers the curated slugs', () {
      final ids = categoryIconCatalog.map((e) => e.id).toSet();

      expect(
        ids,
        containsAll([
          'beach',
          'nature',
          'monument',
          'restaurant',
          'hotel',
          'museum',
          'shopping',
          'transport',
          'photo',
          'star',
          'cafe',
          'bar',
          'attraction',
          'church',
          'castle',
          'hiking',
          'pool',
          'theater',
          'camping',
          'gas',
        ]),
      );
    });
  });

  group('categoryIconFor', () {
    test('returns the placeholder for null', () {
      expect(categoryIconFor(null), categoryPlaceholderIcon);
    });

    test('returns the mapped icon for a known id', () {
      final entry = categoryIconCatalog.first;

      expect(categoryIconFor(entry.id), entry.icon);
    });

    test('returns the placeholder for an unknown id', () {
      expect(categoryIconFor('does-not-exist'), categoryPlaceholderIcon);
    });

    test('returns the placeholder for an empty string', () {
      expect(categoryIconFor(''), categoryPlaceholderIcon);
    });
  });
}
