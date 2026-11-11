import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/category_palette.dart';
import 'package:frontend/data/models/category.dart';

void main() {
  test('categoryColorFor is deterministic for the same category', () {
    const category = Category(id: 3, name: 'Naturaleza', icon: 'nature');
    expect(categoryColorFor(category), categoryColorFor(category));
  });

  test('consecutive distinct category ids map to distinct colors', () {
    final colors = <Color>{
      for (var id = 0; id < categoryPalette.length; id++)
        categoryColorFor(Category(id: id, name: 'C$id')),
    };
    expect(colors, hasLength(categoryPalette.length));
  });

  test('the returned color belongs to the palette and is fully opaque', () {
    const category = Category(id: 7, name: 'Café', icon: 'cafe');
    final color = categoryColorFor(category);
    expect(categoryPalette, contains(color));
    expect(color.a, 1.0);
  });

  test('id 0 and negative ids normalize with abs without crashing', () {
    const zero = Category(id: 0, name: 'Cero');
    const negative = Category(id: -4, name: 'Negativo');
    expect(categoryColorFor(zero), categoryPalette[0]);
    expect(categoryColorFor(negative), categoryPalette[4]);
  });

  test('palette has 6 entries and all are opaque', () {
    expect(categoryPalette, hasLength(6));
    for (final color in categoryPalette) {
      expect(color.a, 1.0);
    }
  });
}
