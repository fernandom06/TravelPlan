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
  Widget wrap(
    List<Place> places,
    void Function(int) onSelect, {
    String? subtitle,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => PlacePickerDialog(
                places: places,
                onPlaceSelected: onSelect,
                subtitle: subtitle,
              ),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the target subtitle when the picker is pre-targeted', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(_places, (_) {}, subtitle: 'Mañana · Día 2 · 02 Jun'),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Añadir lugares'), findsOneWidget);
    expect(find.text('Mañana · Día 2 · 02 Jun'), findsOneWidget);
  });

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

  testWidgets(
    'tapping a place calls onPlaceSelected and keeps the dialog open',
    (tester) async {
      final selected = <int>[];
      await tester.pumpWidget(wrap(_places, selected.add));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Playa de la Concha'));
      await tester.pump();
      await tester.tap(find.text('Playa de la Concha'));
      await tester.pump();

      // The same place can be added twice: visiting a spot again is a
      // legitimate plan.
      expect(selected, [2, 2]);
      expect(find.byType(PlacePickerDialog), findsOneWidget);
      expect(find.text('2 añadidos'), findsOneWidget);
    },
  );

  testWidgets('an empty trip shows "no places yet" guidance', (tester) async {
    await tester.pumpWidget(wrap(const [], (_) {}));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay lugares en el viaje'), findsOneWidget);
  });

  testWidgets('an empty search shows "no matches" guidance', (tester) async {
    await tester.pumpWidget(wrap(_places, (_) {}));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('Ningún lugar coincide con la búsqueda'), findsOneWidget);
  });

  testWidgets('close button dismisses the dialog', (tester) async {
    await tester.pumpWidget(wrap(_places, (_) {}));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.byType(PlacePickerDialog), findsNothing);
  });

  testWidgets('rows picked this session show an Añadido badge, and stay '
      'tappable', (tester) async {
    await tester.pumpWidget(wrap(_places, (_) {}));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    // Nothing marked before the first pick.
    expect(find.text('Añadido'), findsNothing);

    await tester.tap(find.text('Playa de la Concha'));
    await tester.pump();
    expect(find.text('Añadido'), findsOneWidget);
    expect(find.text('1 añadido'), findsOneWidget);

    // A different pick marks only its own row.
    await tester.tap(find.text('Casco Viejo'));
    await tester.pump();
    expect(find.text('Añadido'), findsNWidgets(2));

    // Tapping the same place again stays legal (repeat visits) and does
    // not duplicate the badge.
    await tester.tap(find.text('Playa de la Concha'));
    await tester.pump();
    expect(find.text('Añadido'), findsNWidgets(2));
    expect(find.text('3 añadidos'), findsOneWidget);
  });

  testWidgets('renders the title in Fraunces with an added-counter pill', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(_places, (_) {}));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(find.text('Añadir lugares'));
    expect(title.style?.fontFamily, 'Fraunces');
    expect(find.text('0 añadidos'), findsOneWidget);
  });
}
