import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/presentation/controllers/zone_controller.dart';
import 'package:frontend/presentation/widgets/map_constants.dart';
import 'package:frontend/presentation/widgets/zone_map.dart';

Widget _map(ZoneController controller) => MaterialApp(
  home: Scaffold(body: ZoneMap(controller: controller)),
);

List<Marker> _markers(WidgetTester tester) =>
    tester.widget<MarkerLayer>(find.byType(MarkerLayer).first).markers;

Future<void> _tapMap(WidgetTester tester, Offset offset) async {
  await tester.tapAt(tester.getCenter(find.byType(FlutterMap)) + offset);
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('renders FlutterMap with no polygon or markers initially', (
    tester,
  ) async {
    final controller = ZoneController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_map(controller));

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolygonLayer), findsNothing);
    expect(_markers(tester), isEmpty);
  });

  testWidgets('uses CartoDB Positron tiles with attribution', (tester) async {
    final controller = ZoneController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_map(controller));

    final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer).first);
    expect(tileLayer.urlTemplate, kCartoTileUrlTemplate);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is RichAttributionWidget &&
            w.attributions.any(
              (a) =>
                  a is TextSourceAttribution &&
                  a.text.contains('OpenStreetMap contributors'),
            ),
      ),
      findsWidgets,
    );
  });

  testWidgets('three taps add a polygon with three vertices and markers', (
    tester,
  ) async {
    final controller = ZoneController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_map(controller));

    await _tapMap(tester, Offset.zero);
    await _tapMap(tester, const Offset(40, 0));
    await _tapMap(tester, const Offset(0, 40));

    expect(find.byType(PolygonLayer), findsOneWidget);
    final polygon = tester
        .widget<PolygonLayer>(find.byType(PolygonLayer))
        .polygons
        .single;
    expect(polygon.points, hasLength(3));
    expect(_markers(tester), hasLength(3));
    expect(controller.value.points, hasLength(3));
  });

  testWidgets('polygon is mint with a dashed mint border', (tester) async {
    final controller = ZoneController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_map(controller));

    await _tapMap(tester, Offset.zero);
    await _tapMap(tester, const Offset(40, 0));
    await _tapMap(tester, const Offset(0, 40));

    final polygon = tester
        .widget<PolygonLayer>(find.byType(PolygonLayer))
        .polygons
        .single;
    expect(polygon.color, AppColors.accent.withValues(alpha: 0.2));
    expect(polygon.borderColor, AppColors.accent);
    final pattern = polygon.pattern;
    expect(pattern, isA<StrokePattern>());
    expect(pattern.segments, [8, 4]);
    expect(pattern, StrokePattern.dashed(segments: [8, 4]));
  });

  testWidgets('vertex markers are mint', (tester) async {
    final controller = ZoneController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_map(controller));

    await _tapMap(tester, Offset.zero);
    await _tapMap(tester, const Offset(40, 0));
    await _tapMap(tester, const Offset(0, 40));

    final marker = _markers(tester).first;
    final icon = (marker.child as Icon);
    expect(icon.color, AppColors.accent);
  });

  testWidgets('an extra tap grows the polygon and vertex markers', (
    tester,
  ) async {
    final controller = ZoneController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_map(controller));

    await _tapMap(tester, Offset.zero);
    await _tapMap(tester, const Offset(40, 0));
    await _tapMap(tester, const Offset(0, 40));
    await _tapMap(tester, const Offset(40, 40));

    expect(controller.value.points, hasLength(4));
    final polygon = tester
        .widget<PolygonLayer>(find.byType(PolygonLayer))
        .polygons
        .single;
    expect(polygon.points, hasLength(4));
    expect(_markers(tester), hasLength(4));
  });
}
