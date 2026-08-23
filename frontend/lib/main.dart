import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/connectivity/connectivity_controller.dart';
import 'data/place_api.dart';
import 'presentation/controllers/places_controller.dart';
import 'presentation/screens/home_screen.dart';

final String kApiBaseUrl = _resolveApiBaseUrl();

String _resolveApiBaseUrl() {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isNotEmpty) return configured;
  return defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8000'
      : 'http://localhost:8000';
}

void main() {
  final online = ConnectivityController.live();
  final placesController = PlacesController(PlaceApi(baseUrl: kApiBaseUrl));
  runApp(
    TravelPlanApp(online: online, placesController: placesController),
  );
}

class TravelPlanApp extends StatelessWidget {
  const TravelPlanApp({
    super.key,
    required this.online,
    required this.placesController,
  });

  final ValueNotifier<bool> online;
  final PlacesController placesController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TravelPlan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: HomeScreen(online: online, placesController: placesController),
    );
  }
}
