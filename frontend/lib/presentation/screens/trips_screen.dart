import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/itinerary_api.dart';
import '../../data/models/trip.dart';
import '../../data/models/trip_draft.dart';
import '../../data/models/trip_update.dart';
import '../controllers/itinerary_controller.dart';
import '../controllers/places_controller.dart';
import '../controllers/trips_controller.dart';
import '../widgets/dashed_border_container.dart';
import '../widgets/offline_banner.dart';
import '../widgets/trip_card.dart';
import '../widgets/trip_form.dart';
import 'itinerary_screen.dart';
import 'zone_map_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({
    super.key,
    required this.tripsController,
    required this.itineraryApi,
    required this.placesController,
    required this.online,
    required this.baseUrl,
  });

  final TripsController tripsController;
  final ItineraryApi itineraryApi;
  final PlacesController placesController;
  final ValueNotifier<bool> online;
  final String baseUrl;

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  late final ItineraryController _itineraryController;

  @override
  void initState() {
    super.initState();
    _itineraryController = ItineraryController(widget.itineraryApi);
    _loadTrips();
  }

  @override
  void dispose() {
    _itineraryController.dispose();
    super.dispose();
  }

  void _showError(Object error, String action) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$action: $error')));
  }

  Future<void> _loadTrips() async {
    try {
      await widget.tripsController.loadTrips();
    } catch (e) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showError(e, 'Error al cargar');
      });
    }
  }

  Future<void> _createTrip(TripDraft draft) async {
    try {
      await widget.tripsController.createTrip(draft);
    } catch (e) {
      _showError(e, 'Error al crear');
    }
  }

  Future<void> _updateTrip(String id, TripUpdate update) async {
    try {
      await widget.tripsController.updateTrip(id, update);
    } catch (e) {
      _showError(e, 'Error al actualizar');
    }
  }

  Future<void> _deleteTrip(String id) async {
    try {
      await widget.tripsController.deleteTrip(id);
    } catch (e) {
      _showError(e, 'Error al borrar');
    }
  }

  Future<String?> _pickAndUploadImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result.isEmpty) return null;
    final file = result.single;
    final bytes = await file.readAsBytes();
    return widget.tripsController.uploadImage(
      bytes,
      file.name,
      _contentTypeFor(file.name),
    );
  }

  static String _contentTypeFor(String filename) {
    final name = filename.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<TripDraft?> _showTripForm({TripDraft? initialDraft}) {
    return showDialog<TripDraft>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: TripForm(
            initialDraft: initialDraft,
            onSave: (draft) => Navigator.pop(dialogContext, draft),
            onCancel: () => Navigator.pop(dialogContext),
            onPickImage: _pickAndUploadImage,
          ),
        );
      },
    );
  }

  Future<void> _openCreateForm() async {
    TripDraft? saved;
    while (true) {
      saved = await _showTripForm(initialDraft: saved);
      if (saved == null || !mounted) return;
      final draft = saved;
      final result = await Navigator.push<TripDraft>(
        context,
        MaterialPageRoute(builder: (_) => ZoneMapScreen(draft: draft)),
      );
      if (result != null) {
        _createTrip(result);
        return;
      }
      if (!mounted) return;
    }
  }

  Future<void> _openEditForm(Trip trip) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: TripForm(
            initialTrip: trip,
            onSave: (draft) {
              Navigator.pop(dialogContext);
              _updateTrip(
                trip.id,
                TripUpdate(
                  name: draft.name,
                  startDate: draft.startDate,
                  endDate: draft.endDate,
                  description: draft.description,
                  imageUrl: draft.imageUrl,
                ),
              );
            },
            onCancel: () => Navigator.pop(dialogContext),
            onDelete: () {
              Navigator.pop(dialogContext);
              _deleteTrip(trip.id);
            },
            onPickImage: _pickAndUploadImage,
          ),
        );
      },
    );
  }

  void _openTrip(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItineraryScreen(
          trip: trip,
          itineraryController: _itineraryController,
          placesController: widget.placesController,
          online: widget.online,
          baseUrl: widget.baseUrl,
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar viaje'),
          content: const Text('¿Eliminar este viaje?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    _deleteTrip(trip.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: widget.online,
        builder: (_, isOnline, _) => Column(
          children: [
            if (!isOnline) const OfflineBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tus Aventuras',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppColors.text),
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<TripsState>(
                valueListenable: widget.tripsController,
                builder: (_, state, _) => _buildBody(context, state),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateForm,
        heroTag: 'trips-create-fab',
        child: const Icon(Icons.add),
      ),
    );
  }

  int _columnsFor(double width) {
    if (width < 800) return 1;
    if (width < 1280) return 2;
    return 3;
  }

  Widget _buildBody(BuildContext context, TripsState state) {
    if (state.isLoading && state.trips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = _columnsFor(width);
        final itemCount = state.trips.length + 1;
        if (state.trips.isEmpty) {
          // The dashed card doubles as the centered empty state.
          return Center(
            child: SizedBox(
              width: (width * 0.6).clamp(220.0, 320.0),
              height: 280,
              child: _CreateTripCard(onTap: _openCreateForm),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: itemCount,
          itemBuilder: (_, index) {
            if (index == state.trips.length) {
              return _CreateTripCard(onTap: _openCreateForm);
            }
            final trip = state.trips[index];
            return TripCard(
              trip: trip,
              baseUrl: widget.baseUrl,
              onEdit: () => _openEditForm(trip),
              onDelete: () => _confirmAndDelete(trip),
              onOpen: () => _openTrip(trip),
            );
          },
        );
      },
    );
  }
}

/// Dashed "¿A dónde vamos?" card that opens the trip creation form; it is the
/// last grid cell when trips exist and the centered empty state otherwise.
class _CreateTripCard extends StatelessWidget {
  const _CreateTripCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DashedBorderContainer(
      color: AppColors.muted,
      radius: 16,
      backgroundColor: AppColors.background.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 40, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              '¿A dónde vamos?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.text,
                fontFamily: 'Fraunces',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
