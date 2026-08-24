import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/models/trip.dart';
import '../../data/models/trip_draft.dart';
import '../../data/models/trip_update.dart';
import '../controllers/trips_controller.dart';
import '../widgets/offline_banner.dart';
import '../widgets/trip_card.dart';
import '../widgets/trip_form.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({
    super.key,
    required this.tripsController,
    required this.online,
    required this.baseUrl,
  });

  final TripsController tripsController;
  final ValueNotifier<bool> online;
  final String baseUrl;

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  @override
  void initState() {
    super.initState();
    _loadTrips();
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

  Future<void> _openCreateForm() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: TripForm(
            onSave: (draft) {
              Navigator.pop(dialogContext);
              _createTrip(draft);
            },
            onCancel: () => Navigator.pop(dialogContext),
            onPickImage: _pickAndUploadImage,
          ),
        );
      },
    );
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
            Expanded(
              child: ValueListenableBuilder<TripsState>(
                valueListenable: widget.tripsController,
                builder: (_, state, _) => _buildBody(state),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateForm,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(TripsState state) {
    if (state.isLoading && state.trips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.flight, size: 64),
            SizedBox(height: 16),
            Text('No hay viajes'),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: state.trips.length,
      itemBuilder: (_, index) {
        final trip = state.trips[index];
        return TripCard(
          trip: trip,
          baseUrl: widget.baseUrl,
          onEdit: () => _openEditForm(trip),
          onDelete: () => _confirmAndDelete(trip),
        );
      },
    );
  }
}
