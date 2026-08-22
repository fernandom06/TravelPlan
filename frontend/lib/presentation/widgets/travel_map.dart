import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/category.dart';
import '../../data/models/place.dart';
import 'map_constants.dart';
import 'place_form.dart';

class TravelMap extends StatefulWidget {
  const TravelMap({
    super.key,
    this.places = const [],
    this.categories = const [],
    required this.onCreatePlace,
    this.isOnline = true,
  });

  final List<Place> places;
  final List<Category> categories;
  final Future<void> Function({
    required String name,
    required int categoryId,
    String? description,
    required double latitude,
    required double longitude,
  })
  onCreatePlace;
  final bool isOnline;

  @override
  State<TravelMap> createState() => _TravelMapState();
}

enum _FormMode { creation, readOnly }

class _TravelMapState extends State<TravelMap> {
  final _mapController = MapController();

  LatLng? _selectedPoint;
  Offset? _formScreenPosition;
  _FormMode? _formMode;
  Place? _viewingPlace;

  bool get _formOpen => _formMode != null;

  void _closeForm() {
    _selectedPoint = null;
    _formScreenPosition = null;
    _formMode = null;
    _viewingPlace = null;
  }

  void _handleTap(TapPosition tapPosition, LatLng point) {
    if (_formOpen) {
      setState(_closeForm);
      return;
    }
    final offset = _mapController.camera.latLngToScreenOffset(point);
    setState(() {
      _selectedPoint = point;
      _formScreenPosition = offset;
      _formMode = _FormMode.creation;
      _viewingPlace = null;
    });
  }

  void _handleMarkerTap(Place place) {
    if (_formOpen) {
      setState(_closeForm);
      return;
    }
    setState(() {
      _formMode = _FormMode.readOnly;
      _viewingPlace = place;
      _selectedPoint = null;
    });
  }

  Future<void> _handleSave(
    String name,
    int categoryId,
    String? description,
  ) async {
    if (!widget.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin conexion')),
      );
      setState(_closeForm);
      return;
    }
    final point = _selectedPoint!;
    try {
      await widget.onCreatePlace(
        name: name,
        categoryId: categoryId,
        description: description,
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (!mounted) return;
      setState(_closeForm);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      for (final place in widget.places)
        Marker(
          point: place.latLng,
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _handleMarkerTap(place),
            child: const Icon(
              Icons.location_on,
              color: kSavedMarkerColor,
              size: 40,
            ),
          ),
        ),
      if (_selectedPoint != null && _formMode == _FormMode.creation)
        Marker(
          point: _selectedPoint!,
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: const Icon(
            Icons.location_on,
            color: kNewMarkerColor,
            size: 40,
          ),
        ),
    ];

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: kDefaultCenter,
            initialZoom: kDefaultZoom,
            minZoom: kMinZoom,
            maxZoom: kMaxZoom,
            onTap: _handleTap,
            onPositionChanged: (camera, hasGesture) {
              if (_formOpen && hasGesture) {
                setState(_closeForm);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: kOsmTileUrlTemplate,
              userAgentPackageName: 'dev.travelplan.frontend',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        if (_formOpen) _buildFormOverlay(),
      ],
    );
  }

  Widget _buildFormOverlay() {
    final position = _formScreenPosition ?? Offset.zero;
    return Positioned(
      left: position.dx - 130,
      top: position.dy - 40,
      child: FractionalTranslation(
        translation: const Offset(0, -1),
        child: SizedBox(
          width: 260,
          child: PlaceForm(
            categories: widget.categories,
            place: _formMode == _FormMode.readOnly ? _viewingPlace : null,
            onSave: _handleSave,
            onCancel: () => setState(_closeForm),
          ),
        ),
      ),
    );
  }
}
