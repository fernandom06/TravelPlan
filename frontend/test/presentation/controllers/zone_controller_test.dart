import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/zone_point.dart';
import 'package:frontend/presentation/controllers/zone_controller.dart';

const _p1 = ZonePoint(latitude: 42.0, longitude: -4.0);
const _p2 = ZonePoint(latitude: 42.0, longitude: -3.0);
const _p3 = ZonePoint(latitude: 43.0, longitude: -3.0);

void main() {
  group('ZoneController', () {
    test('addPoint accumulates points', () {
      final controller = ZoneController();

      controller.addPoint(_p1);
      controller.addPoint(_p2);

      expect(controller.value.points, [_p1, _p2]);
    });

    test('canCreate is false with 0, 1, 2 points and true with 3+', () {
      final controller = ZoneController();

      expect(controller.canCreate, isFalse);
      controller.addPoint(_p1);
      expect(controller.canCreate, isFalse);
      controller.addPoint(_p2);
      expect(controller.canCreate, isFalse);
      controller.addPoint(_p3);
      expect(controller.canCreate, isTrue);
      controller.addPoint(_p1);
      expect(controller.canCreate, isTrue);
    });

    test('undoLast removes the last point', () {
      final controller = ZoneController();

      controller.addPoint(_p1);
      controller.addPoint(_p2);
      controller.undoLast();

      expect(controller.value.points, [_p1]);
    });

    test('undoLast on empty is safe', () {
      final controller = ZoneController();

      controller.undoLast();

      expect(controller.value.points, isEmpty);
    });

    test('clear empties points', () {
      final controller = ZoneController();

      controller.addPoint(_p1);
      controller.addPoint(_p2);
      controller.clear();

      expect(controller.value.points, isEmpty);
    });
  });
}