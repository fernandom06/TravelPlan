import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/presentation/screens/settings_screen.dart';

Widget _screen({
  List<Category> categories = const [
    Category(id: 1, name: 'Playa'),
    Category(id: 2, name: 'Restaurante', icon: 'restaurant'),
  ],
  bool isOnline = true,
}) {
  return MaterialApp(
    home: SettingsScreen(
      categories: categories,
      places: const [],
      isOnline: isOnline,
      onCreate: (name, icon) async => Category(id: 9, name: name, icon: icon),
      onRename: (id, name, icon) async =>
          Category(id: id, name: name, icon: icon),
      onDelete: (id, reassignTo) async {},
    ),
  );
}

void main() {
  testWidgets('shows the Ajustes page title and the Categorias section', (
    tester,
  ) async {
    await tester.pumpWidget(_screen());

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Categorías'), findsOneWidget);
    expect(find.text('Playa'), findsOneWidget);
    expect(find.text('Restaurante'), findsOneWidget);
  });
}
