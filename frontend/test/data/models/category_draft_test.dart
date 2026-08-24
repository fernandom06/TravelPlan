import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category_draft.dart';

void main() {
  group('CategoryDraft', () {
    test('exposes the name', () {
      const draft = CategoryDraft(name: 'Playa');

      expect(draft.name, 'Playa');
    });

    test('exposes the icon', () {
      const draft = CategoryDraft(name: 'Playa', icon: 'beach');

      expect(draft.icon, 'beach');
    });

    test('toJson produces the expected map', () {
      const draft = CategoryDraft(name: 'Playa');

      expect(draft.toJson(), {'name': 'Playa', 'icon': null});
    });

    test('toJson includes a non-null icon', () {
      const draft = CategoryDraft(name: 'Playa', icon: 'beach');

      expect(draft.toJson(), {'name': 'Playa', 'icon': 'beach'});
    });
  });
}