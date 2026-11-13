import 'package:flutter/material.dart';

import '../../data/itinerary_api.dart';
import '../../data/models/category_draft.dart';
import '../controllers/places_controller.dart';
import '../controllers/trips_controller.dart';
import '../widgets/app_shell.dart';
import '../widgets/error_notice.dart';
import '../widgets/offline_banner.dart';
import '../widgets/travel_map.dart';
import 'settings_screen.dart';
import 'trips_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.online,
    required this.placesController,
    required this.tripsController,
    required this.itineraryApi,
    required this.apiBaseUrl,
  });

  final ValueNotifier<bool> online;
  final PlacesController placesController;
  final TripsController tripsController;
  final ItineraryApi itineraryApi;
  final String apiBaseUrl;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.placesController.loadAll().catchError((Object error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showErrorNotice(
          context,
          'No se pudieron cargar los lugares. Revisa tu conexión.',
          () => widget.placesController.loadAll(),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      children: [
        _buildMapContent(),
        _buildTripsContent(),
        _buildSettingsContent(),
      ],
    );
  }

  Widget _buildMapContent() {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.online,
      builder: (_, isOnline, _) => Column(
        children: [
          if (!isOnline) const OfflineBanner(),
          Expanded(
            child: ValueListenableBuilder<PlacesState>(
              valueListenable: widget.placesController,
              builder: (_, state, _) => TravelMap(
                places: state.places,
                categories: state.categories,
                isOnline: isOnline,
                onCreatePlace: widget.placesController.createPlace,
                onUpdatePlace: widget.placesController.updatePlace,
                onDeletePlace: widget.placesController.deletePlace,
                onResolveMapUrl: widget.placesController.resolveMapUrl,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsContent() {
    return TripsScreen(
      tripsController: widget.tripsController,
      itineraryApi: widget.itineraryApi,
      placesController: widget.placesController,
      online: widget.online,
      baseUrl: widget.apiBaseUrl,
    );
  }

  Widget _buildSettingsContent() {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.online,
      builder: (_, isOnline, _) => ValueListenableBuilder<PlacesState>(
        valueListenable: widget.placesController,
        builder: (_, state, _) => SettingsScreen(
          categories: state.categories,
          places: state.places,
          isOnline: isOnline,
          onCreate: (name, icon) => widget.placesController.createCategory(
            CategoryDraft(name: name, icon: icon),
          ),
          onRename: (id, name, icon) => widget.placesController.renameCategory(
            id,
            CategoryDraft(name: name, icon: icon),
          ),
          onDelete: (id, reassignTo) => widget.placesController.deleteCategory(
            id,
            reassignTo: reassignTo,
          ),
        ),
      ),
    );
  }
}
