import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/zone_point.dart';
import '../controllers/zone_controller.dart';
import 'map_constants.dart';

class ZoneMap extends StatefulWidget {
  const ZoneMap({super.key, required this.controller, this.mapController});

  final ZoneController controller;
  final MapController? mapController;

  @override
  State<ZoneMap> createState() => _ZoneMapState();
}

class _ZoneMapState extends State<ZoneMap> {
  late final MapController _mapController;
  late final bool _ownsMapController;

  @override
  void initState() {
    super.initState();
    final injected = widget.mapController;
    if (injected != null) {
      _mapController = injected;
      _ownsMapController = false;
    } else {
      _mapController = MapController();
      _ownsMapController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsMapController) _mapController.dispose();
    super.dispose();
  }

  void _addVertex(TapPosition tapPosition, LatLng point) {
    widget.controller.addPoint(
      ZonePoint(latitude: point.latitude, longitude: point.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ZoneState>(
      valueListenable: widget.controller,
      builder: (context, state, _) {
        final vertices = [
          for (final p in state.points) LatLng(p.latitude, p.longitude),
        ];
        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: kDefaultCenter,
            initialZoom: kDefaultZoom,
            minZoom: kMinZoom,
            maxZoom: kMaxZoom,
            onTap: _addVertex,
            onLongPress: _addVertex,
          ),
          children: [
            TileLayer(
              urlTemplate: kCartoTileUrlTemplate,
              userAgentPackageName: 'dev.travelplan.frontend',
            ),
            RichAttributionWidget(
              attributions: const [
                TextSourceAttribution(
                  'OpenStreetMap contributors © CARTO',
                  prependCopyright: false,
                ),
              ],
            ),
            if (vertices.length >= 3)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: vertices,
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderColor: AppColors.accent,
                    borderStrokeWidth: 2,
                    pattern: StrokePattern.dashed(segments: [8, 4]),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final vertex in vertices)
                  Marker(
                    point: vertex,
                    width: 20,
                    height: 20,
                    child: const Icon(
                      Icons.circle,
                      color: AppColors.accent,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
