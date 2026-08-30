import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Container whose border is drawn as dashes by [DashedBorderPainter].
///
/// Used for drop zones, the empty trips card and the trip-zone pill.
class DashedBorderContainer extends StatelessWidget {
  const DashedBorderContainer({
    super.key,
    required this.child,
    this.color = const Color(0xFF81B29A),
    this.strokeWidth = 2,
    this.dash = 8,
    this.space = 4,
    this.radius = 12,
    this.padding,
    this.backgroundColor,
  });

  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dash;
  final double space;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        dash: dash,
        space: space,
        radius: radius,
      ),
      child: Container(
        padding: padding,
        decoration: backgroundColor == null
            ? null
            : BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(radius),
              ),
        child: child,
      ),
    );
  }
}

/// Paints a rounded-rectangle dashed border around its [size].
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dash,
    required this.space,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double dash;
  final double space;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = _buildDashedPath(_sampleRoundRect(rrect), dash, space);
    canvas.drawPath(path, paint);
  }

  /// Samples the rounded-rect outline into a dense polyline.
  static List<Offset> _sampleRoundRect(RRect rrect) {
    const steps = 128;
    final perimeter = _roundRectPerimeter(rrect);
    return [
      for (var i = 0; i <= steps; i++)
        _pointAtPerimeter(rrect, perimeter * i / steps),
    ];
  }

  /// Emits dash segments [dash] long separated by [space]-long gaps along a
  /// polyline.
  static Path _buildDashedPath(List<Offset> points, double dash, double space) {
    final path = Path();
    if (points.isEmpty) return path;
    var drawing = true;
    var remaining = dash;
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final segment = (b - a).distance;
      if (segment == 0) continue;
      var travelled = 0.0;
      while (travelled < segment) {
        final take = (segment - travelled).clamp(0.0, remaining);
        final p = a + (b - a) * ((travelled + take) / segment);
        if (drawing) {
          path.lineTo(p.dx, p.dy);
        } else {
          path.moveTo(p.dx, p.dy);
        }
        travelled += take;
        remaining -= take;
        if (remaining <= 0) {
          drawing = !drawing;
          remaining = drawing ? dash : space;
        }
      }
    }
    return path;
  }

  static double _roundRectPerimeter(RRect rrect) {
    final w = rrect.width;
    final h = rrect.height;
    final r = rrect.tlRadius.x.clamp(0.0, w / 2).toDouble();
    return 2 * w + 2 * h - 8 * r + 2 * math.pi * r;
  }

  static Offset _pointAtPerimeter(RRect rrect, double distance) {
    final w = rrect.width;
    final h = rrect.height;
    final r = rrect.tlRadius.x.clamp(0.0, w / 2).toDouble();
    final left = rrect.left;
    final top = rrect.top;
    final right = rrect.right;
    final bottom = rrect.bottom;
    final straightW = w - 2 * r;
    final straightH = h - 2 * r;
    final quarter = (math.pi * r) / 2;

    final topLen = straightW;
    final rightLen = straightH;
    final bottomLen = straightW;
    final leftLen = straightH;
    final total = 4 * quarter + 2 * (straightW + straightH);

    var d = distance % total;

    // Top edge (left to right), then top-right corner.
    if (d < topLen) return Offset(left + r + d, top);
    d -= topLen;
    if (d < quarter) {
      final a = d / quarter * (math.pi / 2);
      return Offset(
        right - r + r * math.cos(a - math.pi / 2),
        top + r + r * math.sin(a - math.pi / 2),
      );
    }
    d -= quarter;

    // Right edge.
    if (d < rightLen) return Offset(right, top + r + d);
    d -= rightLen;
    if (d < quarter) {
      final a = d / quarter * (math.pi / 2);
      return Offset(right - r + r * math.cos(a), bottom - r + r * math.sin(a));
    }
    d -= quarter;

    // Bottom edge.
    if (d < bottomLen) return Offset(right - r - d, bottom);
    d -= bottomLen;
    if (d < quarter) {
      final a = d / quarter * (math.pi / 2);
      return Offset(
        left + r + r * math.cos(a + math.pi / 2),
        bottom - r + r * math.sin(a + math.pi / 2),
      );
    }
    d -= quarter;

    // Left edge, then top-left corner.
    if (d < leftLen) return Offset(left, bottom - r - d);
    d -= leftLen;
    if (d < quarter) {
      final a = d / quarter * (math.pi / 2);
      return Offset(
        left + r + r * math.cos(a + math.pi),
        top + r + r * math.sin(a + math.pi),
      );
    }
    return Offset(left + r, top + r);
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dash != dash ||
        oldDelegate.space != space ||
        oldDelegate.radius != radius;
  }
}
