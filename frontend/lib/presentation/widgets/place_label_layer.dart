import 'package:flutter/material.dart';

const kLabelFadeStartZoom = 9.0;

const kLabelFadeEndZoom = 11.0;

const kLabelFontSize = 12.0;

const kLabelHeight = 18.0;

const kLabelHPadding = 4.0;

const kLabelMaxWidth = 120.0;

const kLabelEdgeMargin = 8.0;

double placeLabelOpacity(double zoom) {
  final progress =
      (zoom - kLabelFadeStartZoom) / (kLabelFadeEndZoom - kLabelFadeStartZoom);
  return progress.clamp(0.0, 1.0);
}

Set<int> hiddenLabelIndexes(List<Rect> rects) {
  final hidden = <int>{};
  final processed = <Rect>[];
  for (var i = 0; i < rects.length; i++) {
    if (processed.any((rect) => rect.overlaps(rects[i]))) {
      hidden.add(i);
    }
    processed.add(rects[i]);
  }
  return hidden;
}

Alignment labelAlignment({
  required Offset screenPos,
  required Size labelSize,
  required Size viewport,
}) {
  return screenPos.dx + labelSize.width > viewport.width - kLabelEdgeMargin
      ? Alignment.centerLeft
      : Alignment.centerRight;
}

Rect placeLabelRect({
  required Offset screenPos,
  required Size labelSize,
  required Alignment alignment,
}) {
  return switch (alignment) {
    Alignment.centerLeft => Rect.fromLTWH(
      screenPos.dx - labelSize.width,
      screenPos.dy - labelSize.height / 2,
      labelSize.width,
      labelSize.height,
    ),
    _ => Rect.fromLTWH(
      screenPos.dx,
      screenPos.dy - labelSize.height / 2,
      labelSize.width,
      labelSize.height,
    ),
  };
}

Size measureLabelSize(String name, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: name, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: kLabelMaxWidth);
  return painter.size;
}
