import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/category.dart';
import '../../data/models/place.dart';
import '../../data/models/place_draft.dart';
import '../../data/models/place_update.dart';
import 'import_url_dialog.dart';
import 'map_constants.dart';
import 'place_form.dart';
import 'place_label_layer.dart';

class TravelMap extends StatefulWidget {
  const TravelMap({
    super.key,
    this.places = const [],
    this.categories = const [],
    required this.onCreatePlace,
    required this.onUpdatePlace,
    required this.onDeletePlace,
    this.onCreateCategory,
    this.onRenameCategory,
    this.onDeleteCategory,
    this.isOnline = true,
    this.onResolveMapUrl,
    this.mapController,
  });

  final List<Place> places;
  final List<Category> categories;
  final Future<void> Function(PlaceDraft draft) onCreatePlace;
  final Future<void> Function(int id, PlaceUpdate update) onUpdatePlace;
  final Future<void> Function(int id) onDeletePlace;
  final Future<Category> Function(String name, String? icon)? onCreateCategory;
  final Future<Category> Function(int id, String name, String? icon)?
  onRenameCategory;
  final Future<void> Function(int id, int? reassignTo)? onDeleteCategory;
  final bool isOnline;
  final Future<LatLng> Function(String url)? onResolveMapUrl;
  final MapController? mapController;

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
  const _Viewing({required this.place, required this.screenPos});

  final Place place;
  final Offset screenPos;
}

class _Editing extends _MapFormState {
  const _Editing({required this.place, required this.screenPos});

  final Place place;
  final Offset screenPos;
}

class _TravelMapState extends State<TravelMap> {
  late final MapController _mapController;
  late final bool _ownsMapController;

  _MapFormState _state = const _Idle();

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

  int? get _formPlaceId => switch (_state) {
    _Viewing(:final place) => place.id,
    _Editing(:final place) => place.id,
    _Idle() || _Creating() => null,
  };

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
      case _Editing():
        _closeForm();
    }
  }

  void _handleImportedPoint(LatLng point) {
    _mapController.move(point, kDefaultZoom);
    final offset = _mapController.camera.latLngToScreenOffset(point);
    setState(() => _state = _Creating(point: point, screenPos: offset));
  }

  Future<void> _handleImportPressed() async {
    if (!widget.isOnline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sin conexión')));
      return;
    }
    final point = await showDialog<LatLng>(
      context: context,
      builder: (_) => ImportUrlDialog(
        onResolve: (url) async {
          try {
            return await widget.onResolveMapUrl!(url);
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al importar: $error')),
              );
            }
            rethrow;
          }
        },
      ),
    );
    if (point == null) return;
    _handleImportedPoint(point);
  }

  void _handleMarkerTap(Place place) {
    switch (_state) {
      case _Idle():
        final screenPos = _mapController.camera.latLngToScreenOffset(
          place.latLng,
        );
        setState(() => _state = _Viewing(place: place, screenPos: screenPos));
      case _Creating():
      case _Viewing():
      case _Editing():
        _closeForm();
    }
  }

  void _handleEdit(Place place, Offset screenPos) {
    setState(() => _state = _Editing(place: place, screenPos: screenPos));
  }

  Future<void> _handleUpdate(
    String name,
    int categoryId,
    String? description,
  ) async {
    if (!widget.isOnline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sin conexión')));
      return;
    }
    final s = _state;
    if (s is! _Editing) return;
    try {
      await widget.onUpdatePlace(
        s.place.id,
        PlaceUpdate(
          name: name,
          categoryId: categoryId,
          description: description,
        ),
      );
      if (!mounted) return;
      _closeForm();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $error')));
    }
  }

  Future<void> _handleDelete() async {
    if (!widget.isOnline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sin conexión')));
      return;
    }
    final s = _state;
    if (s is! _Editing) return;
    try {
      await widget.onDeletePlace(s.place.id);
      if (!mounted) return;
      _closeForm();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar: $error')));
    }
  }

  void _handleCancelEdit() {
    if (_state case _Editing(:final place, :final screenPos)) {
      setState(() => _state = _Viewing(place: place, screenPos: screenPos));
    }
  }

  Future<void> _handleSave(
    String name,
    int categoryId,
    String? description,
  ) async {
    if (!widget.isOnline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sin conexión')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $error')));
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
            PlaceLabelsLayer(
              places: widget.places,
              hiddenPlaceId: _formPlaceId,
            ),
          ],
        ),
        if (_state is! _Idle) _buildFormOverlay(),
        if (widget.onResolveMapUrl != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _handleImportPressed,
              heroTag: 'map-import-fab',
              tooltip: 'Importar desde Google Maps',
              child: const Icon(Icons.link),
            ),
          ),
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
            places: widget.places,
            onSave: _handleSave,
            onCancel: _closeForm,
            onCreateCategory: widget.onCreateCategory,
            onRenameCategory: widget.onRenameCategory,
            onDeleteCategory: widget.onDeleteCategory,
          ),
        );
      case _Viewing(:final place, :final screenPos):
        return _positionedOverlay(
          screenPos,
          PlaceDetails(
            categories: widget.categories,
            place: place,
            onEdit: () => _handleEdit(place, screenPos),
            onClose: _closeForm,
          ),
        );
      case _Editing(:final place, :final screenPos):
        return _positionedOverlay(
          screenPos,
          PlaceForm(
            categories: widget.categories,
            places: widget.places,
            initialName: place.name,
            initialDescription: place.description,
            initialCategory: place.category,
            onSave: _handleUpdate,
            onCancel: _handleCancelEdit,
            onDelete: _handleDelete,
            onCreateCategory: widget.onCreateCategory,
            onRenameCategory: widget.onRenameCategory,
            onDeleteCategory: widget.onDeleteCategory,
          ),
        );
      case _Idle():
        return const SizedBox.shrink();
    }
  }
}
