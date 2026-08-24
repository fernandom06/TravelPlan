import 'package:flutter/material.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.flight, size: 64),
          SizedBox(height: 16),
          Text('Próximamente'),
        ],
      ),
    );
  }
}
