import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/trip.dart';
import 'package:frontend/presentation/widgets/app_badge.dart';
import 'package:frontend/presentation/widgets/trip_card.dart';

Trip _trip({
  String? imageUrl,
  String name = 'Viaje a Galicia',
  String? description = 'Costas y comida',
  DateTime? startDate,
  DateTime? endDate,
}) {
  return Trip(
    id: 'abc',
    name: name,
    description: description,
    startDate: startDate ?? DateTime(2026, 6, 1),
    endDate: endDate ?? DateTime(2026, 6, 10),
    imageUrl: imageUrl,
    createdAt: '2026-01-01',
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows placeholder icon when imageUrl is null', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TripCard(
          trip: _trip(imageUrl: null),
          baseUrl: 'http://localhost:8000',
          onEdit: () {},
          onDelete: () {},
          onOpen: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.image), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('shows Image.network with prepended baseUrl for relative url', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TripCard(
          trip: _trip(imageUrl: '/uploads/x.jpg'),
          baseUrl: 'http://localhost:8000',
          onEdit: () {},
          onDelete: () {},
          onOpen: () {},
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as NetworkImage).url,
      'http://localhost:8000/uploads/x.jpg',
    );
  });

  testWidgets('shows Image.network with absolute url as-is', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TripCard(
          trip: _trip(imageUrl: 'https://example.com/photo.jpg'),
          baseUrl: 'http://localhost:8000',
          onEdit: () {},
          onDelete: () {},
          onOpen: () {},
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, 'https://example.com/photo.jpg');
  });

  testWidgets('shows name and wireframe-formatted dates', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TripCard(
          trip: _trip(),
          baseUrl: 'http://localhost:8000',
          onEdit: () {},
          onDelete: () {},
          onOpen: () {},
        ),
      ),
    );

    expect(find.text('Viaje a Galicia'), findsOneWidget);
    expect(find.text('01 Jun - 10 Jun, 2026'), findsOneWidget);
  });

  testWidgets('does not show the description', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TripCard(
          trip: _trip(description: 'Costas y comida'),
          baseUrl: 'http://localhost:8000',
          onEdit: () {},
          onDelete: () {},
          onOpen: () {},
        ),
      ),
    );

    expect(find.text('Costas y comida'), findsNothing);
  });

  testWidgets('shows no visible edit/delete buttons', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TripCard(
          trip: _trip(),
          baseUrl: 'http://localhost:8000',
          onEdit: () {},
          onDelete: () {},
          onOpen: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
  });

  testWidgets('long-press opens the menu and edit fires onEdit', (
    tester,
  ) async {
    var edited = false;
    await tester.pumpWidget(
      _wrap(
        TripCard(
          trip: _trip(),
          baseUrl: 'http://localhost:8000',
          onEdit: () => edited = true,
          onDelete: () {},
          onOpen: () {},
        ),
      ),
    );

    await tester.longPress(find.text('Viaje a Galicia'));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Borrar'), findsOneWidget);

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(edited, isTrue);
  });

  testWidgets('long-press menu delete fires onDelete', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      _wrap(
        TripCard(
          trip: _trip(),
          baseUrl: 'http://localhost:8000',
          onEdit: () {},
          onDelete: () => deleted = true,
          onOpen: () {},
        ),
      ),
    );

    await tester.longPress(find.text('Viaje a Galicia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  testWidgets('tapping the card calls onOpen', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      _wrap(
        TripCard(
          trip: _trip(),
          baseUrl: 'http://localhost:8000',
          onEdit: () {},
          onDelete: () {},
          onOpen: () => opened = true,
        ),
      ),
    );

    await tester.tap(find.text('Viaje a Galicia'));
    expect(opened, isTrue);
  });

  testWidgets('shows PRÓXIMAMENTE badge for an upcoming trip', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TripCard(
          trip: _trip(
            startDate: DateTime(2026, 7, 15),
            endDate: DateTime(2026, 7, 22),
          ),
          baseUrl: 'http://localhost:8000',
          onEdit: () {},
          onDelete: () {},
          onOpen: () {},
          today: DateTime(2026, 7, 1),
        ),
      ),
    );

    expect(find.byType(AppBadge), findsOneWidget);
    expect(find.text('PRÓXIMAMENTE'), findsOneWidget);
  });

  testWidgets('shows EN CURSO badge for an ongoing trip', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TripCard(
          trip: _trip(
            startDate: DateTime(2026, 7, 15),
            endDate: DateTime(2026, 7, 22),
          ),
          baseUrl: 'http://localhost:8000',
          onEdit: () {},
          onDelete: () {},
          onOpen: () {},
          today: DateTime(2026, 7, 19),
        ),
      ),
    );

    expect(find.text('EN CURSO'), findsOneWidget);
  });

  testWidgets('shows PASADO badge for a past trip', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TripCard(
          trip: _trip(
            startDate: DateTime(2026, 7, 15),
            endDate: DateTime(2026, 7, 22),
          ),
          baseUrl: 'http://localhost:8000',
          onEdit: () {},
          onDelete: () {},
          onOpen: () {},
          today: DateTime(2026, 7, 30),
        ),
      ),
    );

    expect(find.text('PASADO'), findsOneWidget);
  });

  testWidgets('TripImageError shows broken image icon and text', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const TripImageError()));

    expect(find.byIcon(Icons.broken_image), findsOneWidget);
    expect(find.text('Imagen no disponible'), findsOneWidget);
  });
}
