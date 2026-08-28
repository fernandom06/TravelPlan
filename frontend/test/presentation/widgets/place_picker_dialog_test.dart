import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/presentation/widgets/place_picker_dialog.dart';

Place _place(int id, String name) => Place(
  id: id,
  name: name,
  description: null,
  latitude: 42.5,
  longitude: -3.5,
  category: const Category(id: 1, name: 'Naturaleza', icon: 'nature'),
);

final _places = [
  _place(1, 'Mirador de la Catedral'),
  _place(2, 'Playa de la Concha'),
  _place(3, 'Casco Viejo'),
];

void main() {
  Widget wrap(List<Place> places, void Function(int) onSelect) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => PlacePickerDialog(
                places: places,
                onPlaceSelected: onSelect,
              ),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
  }

  testWidgets('lists every place', (tester) async {
    await tester.pumpWidget(wrap(_places, (_) {}));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Mirador de la Catedral'), findsOneWidget);
    expect(find.text('Playa de la Concha'), findsOneWidget);
    expect(find.text('Casco Viejo'), findsOneWidget);
  });

  testWidgets('search filters the list', (tester) async {
    await tester.pumpWidget(wrap(_places, (_) {}));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'playa');
    await tester.pumpAndSettle();

    expect(find.text('Playa de la Concha'), findsOneWidget);
    expect(find.text('Mirador de la Catedral'), findsNothing);
    expect(find.text('Casco Viejo'), findsNothing);
  });

  testWidgets('tapping a place calls onPlaceSelected and keeps the dialog open', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(wrap(_places, selected.add));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Playa de la Concha'));
    await tester.pump();
    await tester.tap(find.text('Playa de la Concha'));
    await tester.pump();

    expect(selected, [2, 2]);
    expect(find.byType(PlacePickerDialog), findsOneWidget);
    expect(find.text('2 añadidos'), findsOneWidget);
  });

  testWidgets('close button dismisses the dialog', (tester) async {
    await tester.pumpWidget(wrap(_places, (_) {}));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.byType(PlacePickerDialog), findsNothing);
  });
}