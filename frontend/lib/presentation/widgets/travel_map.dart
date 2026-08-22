import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'map_constants.dart';

class TravelMap extends StatefulWidget {
  const TravelMap({super.key});

  @override
  State<TravelMap> createState() => _TravelMapState();
}

class _TravelMapState extends State<TravelMap> {
  LatLng? _selectedPoint;

  void _handleTap(TapPosition tapPosition, LatLng point) {
    setState(() => _selectedPoint = point);
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: kDefaultCenter,
        initialZoom: kDefaultZoom,
        minZoom: kMinZoom,
        maxZoom: kMaxZoom,
        onTap: _handleTap,
      ),
      children: [
        TileLayer(
          urlTemplate: kOsmTileUrlTemplate,
          userAgentPackageName: 'dev.travelplan.frontend',
        ),
        MarkerLayer(
          markers: [
            if (_selectedPoint != null)
              Marker(
                point: _selectedPoint!,
                width: 40,
                height: 40,
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
