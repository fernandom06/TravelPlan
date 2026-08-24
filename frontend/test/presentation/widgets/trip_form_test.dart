import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/trip.dart';
import 'package:frontend/data/models/trip_draft.dart';
import 'package:frontend/presentation/widgets/trip_form.dart';

Trip _trip({
  String name = 'Viaje a Galicia',
  String? description = 'Costas',
  DateTime? start,
  DateTime? end,
  String? imageUrl,
}) {
  return Trip(
    id: 'abc',
    name: name,
    description: description,
    startDate: start ?? DateTime(2026, 6, 1),
    endDate: end ?? DateTime(2026, 6, 10),
    imageUrl: imageUrl,
    createdAt: '2026-01-01',
  );
}

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders name, dates, description and save button',
      (tester) async {
    await tester.pumpWidget(wrap(TripForm(onSave: (_) {}, onCancel: () {})));

    expect(find.text('Nombre'), findsOneWidget);
    expect(find.textContaining('Fecha inicio'), findsOneWidget);
    expect(find.textContaining('Fecha fin'), findsOneWidget);
    expect(find.text('Descripción'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('save is disabled when name is empty', (tester) async {
    await tester.pumpWidget(wrap(TripForm(onSave: (_) {}, onCancel: () {})));

    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Guardar'),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('save is disabled when end date before start date',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        TripForm(
          onSave: (_) {},
          onCancel: () {},
          initialTrip: _trip(
            name: 'Viaje',
            start: DateTime(2026, 6, 10),
            end: DateTime(2026, 6, 1),
          ),
        ),
      ),
    );

    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Guardar'),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('typing a name enables save', (tester) async {
    await tester.pumpWidget(wrap(TripForm(onSave: (_) {}, onCancel: () {})));

    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Viaje');
    await tester.pump();

    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Guardar'),
    );
    expect(saveButton.onPressed, isNotNull);
  });

  testWidgets('save calls onSave with correct TripDraft', (tester) async {
    TripDraft? saved;
    await tester.pumpWidget(
      wrap(
        TripForm(
          onSave: (draft) => saved = draft,
          onCancel: () {},
          initialTrip: _trip(name: 'Viaje', description: 'Costas'),
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Viaje nuevo');
    await tester.tap(find.text('Guardar'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.name, 'Viaje nuevo');
    expect(saved!.description, 'Costas');
    expect(saved!.startDate, DateTime(2026, 6, 1));
    expect(saved!.endDate, DateTime(2026, 6, 10));
  });

  testWidgets('edit mode preloads trip values', (tester) async {
    await tester.pumpWidget(
      wrap(
        TripForm(
          onSave: (_) {},
          onCancel: () {},
          initialTrip: _trip(name: 'Viaje a Galicia', description: 'Costas'),
        ),
      ),
    );

    expect(find.text('Viaje a Galicia'), findsOneWidget);
    expect(find.text('Costas'), findsOneWidget);
  });

  testWidgets('delete button opens confirm and confirms calls onDelete',
      (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      wrap(
        TripForm(
          onSave: (_) {},
          onCancel: () {},
          initialTrip: _trip(),
          onDelete: () => deleted = true,
        ),
      ),
    );

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Eliminar viaje'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
  });

  testWidgets('onPickImage returning url shows preview and includes in draft',
      (tester) async {
    TripDraft? saved;
    await tester.pumpWidget(
      wrap(
        TripForm(
          onSave: (draft) => saved = draft,
          onCancel: () {},
          onPickImage: () async => '/uploads/picked.jpg',
        ),
      ),
    );

    await tester.tap(find.text('Subir imagen'));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Viaje');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pump();

    expect(saved!.imageUrl, '/uploads/picked.jpg');
  });

  testWidgets('remove image button clears imageUrl', (tester) async {
    TripDraft? saved;
    await tester.pumpWidget(
      wrap(
        TripForm(
          onSave: (draft) => saved = draft,
          onCancel: () {},
          initialTrip: _trip(imageUrl: '/uploads/x.jpg'),
        ),
      ),
    );

    await tester.tap(find.text('Quitar imagen'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Viaje');
    await tester.tap(find.text('Guardar'));
    await tester.pump();

    expect(saved!.imageUrl, isNull);
  });

  testWidgets('cancel calls onCancel', (tester) async {
    var cancelled = false;
    await tester.pumpWidget(
      wrap(
        TripForm(onSave: (_) {}, onCancel: () => cancelled = true),
      ),
    );

    await tester.tap(find.text('Cancelar'));
    expect(cancelled, isTrue);
  });
}
