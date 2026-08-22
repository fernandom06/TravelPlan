import 'package:flutter/material.dart';

import '../widgets/travel_map.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.online});

  final ValueNotifier<bool> online;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TravelPlan')),
      body: ValueListenableBuilder<bool>(
        valueListenable: online,
        builder: (_, isOnline, _) => Column(
          children: [
            if (!isOnline) const _OfflineBanner(),
            const Expanded(child: TravelMap()),
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
              'Sin conexión a internet',
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
