import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/category.dart';
import '../../data/models/place.dart';
import '../../data/models/place_draft.dart';
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
  final Future<void> Function(PlaceDraft draft) onCreatePlace;
  final bool isOnline;

  @override
  State<TravelMap> createState() => _TravelMapState();
}

sealed class _MapFormState {
  const _MapFormState();
}

class _Idle extends _MapFormState {
  const _Idle();
}

class _Creating extends _MapFormState {
  const _Creating({required this.point, required this.screenPos});

  final LatLng point;
  final Offset screenPos;
}

class _Viewing extends _MapFormState {
  const _Viewing({required this.place});

  final Place place;
}

class _TravelMapState extends State<TravelMap> {
  final _mapController = MapController();

  _MapFormState _state = const _Idle();

  void _closeForm() {
    setState(() => _state = const _Idle());
  }

  void _handleTap(TapPosition tapPosition, LatLng point) {
    switch (_state) {
      case _Idle():
        final offset = _mapController.camera.latLngToScreenOffset(point);
        setState(() => _state = _Creating(point: point, screenPos: offset));
      case _Creating():
      case _Viewing():
        _closeForm();
    }
  }

  void _handleMarkerTap(Place place) {
    switch (_state) {
      case _Idle():
        setState(() => _state = _Viewing(place: place));
      case _Creating():
      case _Viewing():
        _closeForm();
    }
  }

  Future<void> _handleSave(
    String name,
    int categoryId,
    String? description,
  ) async {
    if (!widget.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin conexión')),
      );
      _closeForm();
      return;
    }
    final s = _state;
    if (s is! _Creating) return;
    final point = s.point;
    try {
      await widget.onCreatePlace(
        PlaceDraft(
          name: name,
          categoryId: categoryId,
          description: description,
          latitude: point.latitude,
          longitude: point.longitude,
        ),
      );
      if (!mounted) return;
      _closeForm();
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
      if (_state case _Creating(:final point))
        Marker(
          point: point,
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
              if (_state is! _Idle && hasGesture) {
                _closeForm();
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
        if (_state is! _Idle) _buildFormOverlay(),
      ],
    );
  }

  Widget _positionedOverlay(Offset position, Widget child) {
    return Positioned(
      left: position.dx - 130,
      top: position.dy - 40,
      child: FractionalTranslation(
        translation: const Offset(0, -1),
        child: SizedBox(width: 260, child: child),
      ),
    );
  }

  Widget _buildFormOverlay() {
    switch (_state) {
      case _Creating(:final screenPos):
        return _positionedOverlay(
          screenPos,
          PlaceForm(
            categories: widget.categories,
            onSave: _handleSave,
            onCancel: _closeForm,
          ),
        );
      case _Viewing(:final place):
        return _positionedOverlay(
          Offset.zero,
          PlaceDetails(
            categories: widget.categories,
            place: place,
            onClose: _closeForm,
          ),
        );
      case _Idle():
        return const SizedBox.shrink();
    }
  }
}
