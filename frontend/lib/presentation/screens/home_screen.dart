import 'package:flutter/material.dart';

import '../../data/itinerary_api.dart';
import '../../data/models/category_draft.dart';
import '../controllers/places_controller.dart';
import '../controllers/trips_controller.dart';
import '../widgets/app_shell.dart';
import '../widgets/offline_banner.dart';
import '../widgets/travel_map.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar: $error')));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      children: [_buildMapContent(), _buildTripsContent()],
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
                onCreateCategory: (name, icon) => widget.placesController
                    .createCategory(CategoryDraft(name: name, icon: icon)),
                onRenameCategory: (id, name, icon) => widget.placesController
                    .renameCategory(id, CategoryDraft(name: name, icon: icon)),
                onDeleteCategory: (id, reassignTo) => widget.placesController
                    .deleteCategory(id, reassignTo: reassignTo),
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
}