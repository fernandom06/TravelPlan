import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../data/category_icon_catalog.dart';
import '../../data/models/category.dart';
import '../../data/models/place.dart';
import '../../data/models/place_draft.dart';
import '../../data/models/place_update.dart';
import 'error_notice.dart';
import 'import_url_dialog.dart';
import 'map_constants.dart';
import 'place_form.dart';
import 'place_form_container.dart';
import 'place_label_layer.dart';
import 'place_pin.dart';

class TravelMap extends StatefulWidget {
  const TravelMap({
    super.key,
    this.places = const [],
    this.categories = const [],
    required this.onCreatePlace,
    required this.onUpdatePlace,
    required this.onDeletePlace,
    this.isOnline = true,
    this.onResolveMapUrl,
    this.mapController,
  });

  final List<Place> places;
  final List<Category> categories;
  final Future<void> Function(PlaceDraft draft) onCreatePlace;
  final Future<void> Function(int id, PlaceUpdate update) onUpdatePlace;
  final Future<void> Function(int id) onDeletePlace;
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
  const _Creating({required this.point});

  final LatLng point;
}

class _Viewing extends _MapFormState {
  const _Viewing({required this.place});

  final Place place;
}

class _Editing extends _MapFormState {
  const _Editing({required this.place});

  final Place place;
}

class _TravelMapState extends State<TravelMap> {
  late final MapController _mapController;
  late final bool _ownsMapController;

  _MapFormState _state = const _Idle();

  /// Whether the open create/edit form holds typed content. While creating,
  /// closing the form through a stray map tap must not silently destroy the
  /// draft the user typed on a phone keyboard.
  bool _draftDirty = false;

  /// Last create attempt, kept so a failed or offline save can be retried
  /// from the persistent snackbar without retyping anything.
  (String, int, String?)? _lastSaveAttempt;

  /// Last edit attempt, same retry contract as [_lastSaveAttempt].
  (String, int, String?)? _lastUpdateAttempt;

  /// Keeps the form subtree alive when the layout crosses the breakpoint
  /// (bottom sheet ↔ right panel), preserving text controllers.
  final GlobalKey _formKey = GlobalKey();

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
    _draftDirty = false;
    setState(() => _state = const _Idle());
  }

  void _handleTap(TapPosition tapPosition, LatLng point) {
    switch (_state) {
      case _Idle():
        setState(() {
          _draftDirty = false;
          _state = _Creating(point: point);
        });
      case _Creating():
        unawaited(_closeCreatingForm());
      case _Viewing():
      case _Editing():
        _closeForm();
    }
  }

  /// Closing a create form with typed content is confirmed, never silent:
  /// an accidental tap on the map would otherwise destroy the draft.
  Future<void> _closeCreatingForm() async {
    if (!_draftDirty) {
      _closeForm();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('¿Descartar el lugar?'),
          content: const Text(
            'Se perderá el nombre y la descripción que has escrito.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Seguir editando'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Descartar'),
            ),
          ],
        );
      },
    );
    if (discard == true && mounted) _closeForm();
  }

  void _handleImportedPoint(LatLng point) {
    _mapController.move(point, kDefaultZoom);
    setState(() {
      _draftDirty = false;
      _state = _Creating(point: point);
    });
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
                const SnackBar(
                  content: Text(
                    'No se pudo importar la ubicación. '
                    'Comprueba el enlace e inténtalo de nuevo.',
                  ),
                ),
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
        setState(() => _state = _Viewing(place: place));
      case _Creating():
        unawaited(_closeCreatingForm());
      case _Viewing():
      case _Editing():
        _closeForm();
    }
  }

  void _handleEdit(Place place) {
    setState(() => _state = _Editing(place: place));
  }

  Future<void> _handleUpdate(
    String name,
    int categoryId,
    String? description,
  ) async {
    final s = _state;
    if (s is! _Editing) return;
    _lastUpdateAttempt = (name, categoryId, description);
    await _attemptUpdate();
  }

  /// Re-attempts the stored edit; safe to call from the retry action of the
  /// persistent error snackbar.
  Future<void> _attemptUpdate() async {
    final s = _state;
    final attempt = _lastUpdateAttempt;
    if (s is! _Editing || attempt == null) return;
    final (name, categoryId, description) = attempt;
    if (!widget.isOnline) {
      showErrorNotice(
        context,
        'Sin conexión: el cambio no se ha guardado.',
        _attemptUpdate,
      );
      return;
    }
    try {
      await widget.onUpdatePlace(
        s.place.id,
        PlaceUpdate(
          name: name,
          categoryId: categoryId,
          description: description,
        ),
      );
      _lastUpdateAttempt = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _closeForm();
    } catch (_) {
      if (!mounted) return;
      showErrorNotice(
        context,
        'No se pudo guardar el cambio. Revisa tu conexión.',
        _attemptUpdate,
      );
    }
  }

  Future<void> _handleDelete() async {
    await _attemptDelete();
  }

  /// Re-attempts the delete; safe to call from the retry action of the
  /// persistent error snackbar.
  Future<void> _attemptDelete() async {
    final s = _state;
    if (s is! _Editing) return;
    if (!widget.isOnline) {
      showErrorNotice(
        context,
        'Sin conexión: el lugar no se ha eliminado.',
        _attemptDelete,
      );
      return;
    }
    try {
      await widget.onDeletePlace(s.place.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _closeForm();
    } catch (_) {
      if (!mounted) return;
      showErrorNotice(
        context,
        'No se pudo eliminar el lugar. Revisa tu conexión.',
        _attemptDelete,
      );
    }
  }

  void _handleCancelEdit() {
    if (_state case _Editing(:final place)) {
      setState(() => _state = _Viewing(place: place));
    }
  }

  Future<void> _handleSave(
    String name,
    int categoryId,
    String? description,
  ) async {
    final s = _state;
    if (s is! _Creating) return;
    // The draft is stored before attempting anything: saving without
    // connection must never destroy what the user wrote (field-truthful).
    _lastSaveAttempt = (name, categoryId, description);
    await _attemptSave();
  }

  /// Re-attempts the stored create; safe to call from the retry action of
  /// the persistent error snackbar.
  Future<void> _attemptSave() async {
    final s = _state;
    final attempt = _lastSaveAttempt;
    if (s is! _Creating || attempt == null) return;
    final (name, categoryId, description) = attempt;
    final point = s.point;
    if (!widget.isOnline) {
      showErrorNotice(
        context,
        'Sin conexión: el lugar no se ha guardado.',
        _attemptSave,
      );
      return;
    }
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
      _lastSaveAttempt = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _closeForm();
    } catch (_) {
      if (!mounted) return;
      showErrorNotice(
        context,
        'No se pudo guardar el lugar. Revisa tu conexión.',
        _attemptSave,
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
            child: PinHoverTooltip(
              label: place.name,
              child: PlacePin(icon: categoryIconFor(place.category.icon)),
            ),
          ),
        ),
      if (_state case _Creating(:final point))
        Marker(
          point: point,
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: const PlacePin(
            icon: Icons.add,
            color: AppColors.accent,
            halo: true,
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
              switch (_state) {
                case _Idle():
                  break;
                // While creating, panning is how the user orients the map:
                // closing the form — and destroying the typed draft — on a
                // drag would punish exploration. Explicit taps close it.
                case _Creating():
                  break;
                case _Viewing():
                case _Editing():
                  if (hasGesture) _closeForm();
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: kOsmTileUrlTemplate,
              userAgentPackageName: 'dev.travelplan.frontend',
            ),
            RichAttributionWidget(
              attributions: const [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  prependCopyright: false,
                ),
              ],
            ),
            MarkerLayer(markers: markers),
            PlaceLabelsLayer(
              places: widget.places,
              hiddenPlaceId: _formPlaceId,
            ),
          ],
        ),
        if (_state is! _Idle)
          PlaceFormContainer(
            child: KeyedSubtree(key: _formKey, child: _buildFormContent()),
          ),
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

  Widget _buildFormContent() {
    switch (_state) {
      case _Creating():
        return PlaceForm(
          categories: widget.categories,
          onSave: _handleSave,
          onCancel: _closeForm,
          onDraftChanged: (dirty) => _draftDirty = dirty,
        );
      case _Viewing(:final place):
        return PlaceDetails(
          categories: widget.categories,
          place: place,
          onEdit: () => _handleEdit(place),
          onClose: _closeForm,
        );
      case _Editing(:final place):
        return PlaceForm(
          categories: widget.categories,
          initialName: place.name,
          initialDescription: place.description,
          initialCategory: place.category,
          onSave: _handleUpdate,
          onCancel: _handleCancelEdit,
          onDelete: _handleDelete,
        );
      case _Idle():
        return const SizedBox.shrink();
    }
  }
}
