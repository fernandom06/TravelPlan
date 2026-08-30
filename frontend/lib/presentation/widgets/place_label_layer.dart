import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/place.dart';

const kLabelFadeStartZoom = 9.0;

const kLabelFadeEndZoom = 11.0;

const kLabelFontSize = 13.0;

const kLabelHeight = 18.0;

const kLabelHPadding = 4.0;

const kLabelMaxChars = 20;

const kLabelTruncatedChars = 17;

const kLabelMaxWidth = 120.0;

const kLabelEdgeMargin = 8.0;

/// Sketchbook-style label: Lora italic in navy with a strong white halo for
/// readability over the busy OSM standard tiles.
const kPlaceLabelStyle = TextStyle(
  fontFamily: 'Lora',
  fontSize: kLabelFontSize,
  fontStyle: FontStyle.italic,
  fontWeight: FontWeight.w600,
  color: AppColors.text,
  shadows: [
    Shadow(color: Colors.white, blurRadius: 2),
    Shadow(color: Colors.white, blurRadius: 2, offset: Offset(1, 1)),
    Shadow(color: Colors.white, blurRadius: 2, offset: Offset(-1, 1)),
    Shadow(color: Colors.white, blurRadius: 2, offset: Offset(1, -1)),
    Shadow(color: Colors.white, blurRadius: 2, offset: Offset(-1, -1)),
  ],
);

double placeLabelOpacity(double zoom) {
  final progress =
      (zoom - kLabelFadeStartZoom) / (kLabelFadeEndZoom - kLabelFadeStartZoom);
  return progress.clamp(0.0, 1.0);
}

String truncatePlaceLabel(String name) {
  if (name.length <= kLabelMaxChars) return name;
  return '${name.substring(0, kLabelTruncatedChars)}…';
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

class PlaceLabelsLayer extends StatelessWidget {
  const PlaceLabelsLayer({super.key, required this.places, this.hiddenPlaceId});

  final List<Place> places;
  final int? hiddenPlaceId;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final viewport = camera.nonRotatedSize;
    final firstFrame = viewport == MapCamera.kImpossibleSize;
    final effectiveViewport = firstFrame
        ? const Size(double.infinity, double.infinity)
        : viewport;
    final style = kPlaceLabelStyle;

    final geometries = <({Size markerSize, Alignment alignment, Rect rect})>[];
    for (final place in places) {
      final labelSize = measureLabelSize(place.name, style);
      final markerSize = Size(
        labelSize.width + 2 * kLabelHPadding,
        kLabelHeight,
      );
      final screenPos = camera.latLngToScreenOffset(place.latLng);
      final alignment = labelAlignment(
        screenPos: screenPos,
        labelSize: markerSize,
        viewport: effectiveViewport,
      );
      geometries.add((
        markerSize: markerSize,
        alignment: alignment,
        rect: placeLabelRect(
          screenPos: screenPos,
          labelSize: markerSize,
          alignment: alignment,
        ),
      ));
    }

    final hidden = firstFrame
        ? const <int>{}
        : hiddenLabelIndexes([
            for (final geometry in geometries) geometry.rect,
          ]);

    return MarkerLayer(
      markers: [
        for (var i = 0; i < places.length; i++)
          Marker(
            key: ValueKey('place-label-${places[i].id}'),
            point: places[i].latLng,
            width: geometries[i].markerSize.width,
            height: geometries[i].markerSize.height,
            alignment: geometries[i].alignment,
            child: IgnorePointer(
              child: Opacity(
                opacity: _opacityFor(places[i], i, hidden, camera.zoom),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kLabelHPadding,
                  ),
                  child: Text(
                    places[i].name,
                    style: style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  double _opacityFor(Place place, int index, Set<int> hidden, double zoom) {
    if (place.id == hiddenPlaceId) return 0.0;
    if (hidden.contains(index)) return 0.0;
    return placeLabelOpacity(zoom);
  }
}
