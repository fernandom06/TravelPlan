import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/presentation/widgets/place_label_layer.dart';

void main() {
  group('placeLabelOpacity', () {
    test('ramps from 0 at zoom 9 to 1 at zoom 11', () {
      expect(placeLabelOpacity(8.0), 0.0);
      expect(placeLabelOpacity(9.0), 0.0);
      expect(placeLabelOpacity(10.0), closeTo(0.5, 0.0001));
      expect(placeLabelOpacity(11.0), 1.0);
      expect(placeLabelOpacity(13.0), 1.0);
    });
  });

  group('hiddenLabelIndexes', () {
    test('returns empty when nothing overlaps', () {
      const rects = [
        Rect.fromLTWH(0, 0, 10, 10),
        Rect.fromLTWH(20, 0, 10, 10),
      ];
      expect(hiddenLabelIndexes(rects), isEmpty);
    });

    test('hides the second of two overlapping rects', () {
      const rects = [
        Rect.fromLTWH(0, 0, 20, 10),
        Rect.fromLTWH(10, 0, 20, 10),
      ];
      expect(hiddenLabelIndexes(rects), {1});
    });

    test('hides the second and third of three identical rects', () {
      const rect = Rect.fromLTWH(0, 0, 20, 10);
      expect(hiddenLabelIndexes([rect, rect, rect]), {1, 2});
    });

    test('hides later rects in an overlapping chain', () {
      const rects = [
        Rect.fromLTWH(0, 0, 10, 10),
        Rect.fromLTWH(5, 0, 10, 10),
        Rect.fromLTWH(14, 0, 10, 10),
      ];
      expect(hiddenLabelIndexes(rects), {1, 2});
    });

    test('returns empty for an empty list', () {
      expect(hiddenLabelIndexes(const []), isEmpty);
    });
  });

  group('labelAlignment', () {
    test('keeps centerRight when there is room on the right', () {
      expect(
        labelAlignment(
          screenPos: const Offset(100, 100),
          labelSize: const Size(40, 18),
          viewport: const Size(400, 300),
        ),
        Alignment.centerRight,
      );
    });

    test('flips to centerLeft near the right edge', () {
      expect(
        labelAlignment(
          screenPos: const Offset(390, 100),
          labelSize: const Size(40, 18),
          viewport: const Size(400, 300),
        ),
        Alignment.centerLeft,
      );
    });
  });

  group('placeLabelRect', () {
    test('places a centerRight label beside the point', () {
      expect(
        placeLabelRect(
          screenPos: const Offset(120, 200),
          labelSize: const Size(40, 18),
          alignment: Alignment.centerRight,
        ),
        const Rect.fromLTWH(120, 191, 40, 18),
      );
    });

    test('places a centerLeft label to the left of the point', () {
      expect(
        placeLabelRect(
          screenPos: const Offset(120, 200),
          labelSize: const Size(40, 18),
          alignment: Alignment.centerLeft,
        ),
        const Rect.fromLTWH(80, 191, 40, 18),
      );
    });
  });
}