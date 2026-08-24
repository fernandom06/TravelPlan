import 'package:flutter/material.dart';

import '../../data/models/category_draft.dart';
import '../controllers/places_controller.dart';
import '../controllers/trips_controller.dart';
import '../widgets/offline_banner.dart';
import '../widgets/travel_map.dart';
import 'trips_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.online,
    required this.placesController,
    required this.tripsController,
    required this.apiBaseUrl,
  });

  final ValueNotifier<bool> online;
  final PlacesController placesController;
  final TripsController tripsController;
  final String apiBaseUrl;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _tabController.addListener(_onTabChanged);
    widget.placesController.loadAll().catchError((Object error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar: $error')));
      });
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TravelPlan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined), text: 'Mapa'),
            Tab(icon: Icon(Icons.flight), text: 'Viajes'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _tabController.index,
        children: [_buildMapContent(), _buildTripsContent()],
      ),
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
      online: widget.online,
      baseUrl: widget.apiBaseUrl,
    );
  }
}
