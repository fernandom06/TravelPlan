import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category.dart';

void main() {
  group('Category', () {
    test('fromJson parses id and name', () {
      final category = Category.fromJson({'id': 1, 'name': 'Naturaleza'});

      expect(category.id, 1);
      expect(category.name, 'Naturaleza');
    });

    test('toJson produces the expected map', () {
      const category = Category(id: 1, name: 'Naturaleza');

      expect(category.toJson(), {'id': 1, 'name': 'Naturaleza'});
    });

    test('categories with same id are equal', () {
      const a = Category(id: 1, name: 'Naturaleza');
      const b = Category(id: 1, name: 'Naturaleza');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('categories with different id are not equal', () {
      const a = Category(id: 1, name: 'Naturaleza');
      const b = Category(id: 2, name: 'Naturaleza');

      expect(a, isNot(b));
    });
  });
}
