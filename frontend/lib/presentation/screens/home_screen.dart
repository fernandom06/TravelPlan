import 'package:flutter/material.dart';

import '../../data/models/category_draft.dart';
import '../controllers/places_controller.dart';
import '../widgets/travel_map.dart';
import 'trips_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.online,
    required this.placesController,
  });

  final ValueNotifier<bool> online;
  final PlacesController placesController;

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
        children: [_buildMapContent(), const TripsScreen()],
      ),
    );
  }

  Widget _buildMapContent() {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.online,
      builder: (_, isOnline, _) => Column(
        children: [
          if (!isOnline) const _OfflineBanner(),
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
                onCreateCategory: (name) => widget.placesController
                    .createCategory(CategoryDraft(name: name)),
                onRenameCategory: (id, name) => widget.placesController
                    .renameCategory(id, CategoryDraft(name: name)),
                onDeleteCategory: (id, reassignTo) => widget.placesController
                    .deleteCategory(id, reassignTo: reassignTo),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            Icon(
              Icons.wifi_off,
              size: 18,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Text(
              'Sin conexión con el servidor',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
