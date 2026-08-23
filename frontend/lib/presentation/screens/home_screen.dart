import 'package:flutter/material.dart';

import '../../data/models/category_draft.dart';
import '../controllers/places_controller.dart';
import '../widgets/travel_map.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('TravelPlan')),
      body: ValueListenableBuilder<bool>(
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
                  onCreateCategory: (name) => widget.placesController
                      .createCategory(CategoryDraft(name: name)),
                ),
              ),
            ),
          ],
        ),
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
