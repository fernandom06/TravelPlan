import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/presentation/widgets/dashed_border_container.dart';

class _RecordingCanvas implements Canvas {
  int drawPathCount = 0;
  int drawRectCount = 0;
  Path? lastPath;

  @override
  void drawPath(Path path, Paint paint) {
    drawPathCount++;
    lastPath = path;
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    drawRectCount++;
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}

void main() {
  testWidgets('accepts and lays out a child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashedBorderContainer(
            child: SizedBox(height: 60, child: Text('drop zone')),
          ),
        ),
      ),
    );

    expect(find.text('drop zone'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter is DashedBorderPainter,
      ),
      findsOneWidget,
    );
  });

  test('DashedBorderPainter paints one dashed path', () {
    final canvas = _RecordingCanvas();
    final painter = DashedBorderPainter(
      color: AppColors.accent,
      strokeWidth: 2,
      dash: 8,
      space: 4,
      radius: 12,
    );

    painter.paint(canvas, const Size(200, 100));

    expect(canvas.drawPathCount, 1);
    expect(canvas.lastPath, isNotNull);
  });

  test('DashedBorderPainter exposes configurable stroke properties', () {
    const painter = DashedBorderPainter(
      color: AppColors.accent,
      strokeWidth: 2,
      dash: 8,
      space: 4,
      radius: 12,
    );

    expect(painter.color, AppColors.accent);
    expect(painter.strokeWidth, 2);
    expect(painter.dash, 8);
    expect(painter.space, 4);
    expect(painter.radius, 12);
  });

  test('DashedBorderPainter repaints when config changes', () {
    const a = DashedBorderPainter(
      color: AppColors.accent,
      strokeWidth: 2,
      dash: 8,
      space: 4,
      radius: 12,
    );
    const b = DashedBorderPainter(
      color: AppColors.primary,
      strokeWidth: 2,
      dash: 8,
      space: 4,
      radius: 12,
    );

    expect(a.shouldRepaint(b), isTrue);
    expect(a.shouldRepaint(a), isFalse);
  });
}