import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/presentation/widgets/place_label_layer.dart';

void main() {
  group('kPlaceLabelStyle', () {
    test('uses Lora italic navy semibold (sketchbook)', () {
      expect(kPlaceLabelStyle.fontFamily, 'Lora');
      expect(kPlaceLabelStyle.fontStyle, FontStyle.italic);
      expect(kPlaceLabelStyle.fontWeight, FontWeight.w600);
      expect(kPlaceLabelStyle.color, AppColors.text);
      expect(kPlaceLabelStyle.shadows, isNotEmpty);
    });
  });

  group('measureLabelSize', () {
    test('measures a label with the new style', () {
      final size = measureLabelSize('Mirador de la Catedral', kPlaceLabelStyle);
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    test('measures a 20-character name wider than the old 120px clamp', () {
      final size = measureLabelSize('12345678901234567890', kPlaceLabelStyle);
      expect(size.width, greaterThan(120));
    });

    test('measures a 40-character name fully without a width limit', () {
      final size = measureLabelSize('x' * 40, kPlaceLabelStyle);
      expect(size.width, greaterThan(250));
    });
  });

  group('truncatePlaceLabel', () {
    test('keeps a name of exactly 20 characters whole', () {
      const name = '12345678901234567890';
      expect(truncatePlaceLabel(name), name);
    });

    test('keeps short and empty names intact', () {
      for (final name in ['Mirador', '', 'A', 'AB']) {
        expect(truncatePlaceLabel(name), name);
      }
    });

    test('truncates a 21-character name to 17 chars plus ellipsis', () {
      expect(truncatePlaceLabel('123456789012345678901'), '12345678901234567…');
    });

    test('truncates a 60-character name to 17 chars plus ellipsis', () {
      expect(truncatePlaceLabel('x' * 60), 'x' * 17 + '…');
    });

    test('cuts dry, keeping a space that lands at the cut boundary', () {
      // The space is the 17th character; it survives right before the
      // ellipsis (no word-aware cutting, no trimming).
      expect(
        truncatePlaceLabel('abcdefghijklmnop qrstuvwxyz'),
        'abcdefghijklmnop …',
      );
    });

    test('truncated result has length 18 (17 + ellipsis)', () {
      expect(truncatePlaceLabel('y' * 25).length, 18);
    });
  });

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
      const rects = [Rect.fromLTWH(0, 0, 10, 10), Rect.fromLTWH(20, 0, 10, 10)];
      expect(hiddenLabelIndexes(rects), isEmpty);
    });

    test('hides the second of two overlapping rects', () {
      const rects = [Rect.fromLTWH(0, 0, 20, 10), Rect.fromLTWH(10, 0, 20, 10)];
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
