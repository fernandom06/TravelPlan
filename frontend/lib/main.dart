import 'package:flutter/material.dart';

import 'core/connectivity/connectivity_controller.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(TravelPlanApp(online: ConnectivityController.live()));
}

class TravelPlanApp extends StatelessWidget {
  const TravelPlanApp({super.key, required this.online});

  final ValueNotifier<bool> online;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TravelPlan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: HomeScreen(online: online),
    );
  }
}
