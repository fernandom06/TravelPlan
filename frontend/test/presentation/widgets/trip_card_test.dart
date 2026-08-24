import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/trip.dart';
import 'package:frontend/presentation/widgets/trip_card.dart';

Trip _trip({
  String? imageUrl,
  String name = 'Viaje a Galicia',
  String? description = 'Costas y comida',
}) {
  return Trip(
    id: 'abc',
    name: name,
    description: description,
    startDate: DateTime(2026, 6, 1),
    endDate: DateTime(2026, 6, 10),
    imageUrl: imageUrl,
    createdAt: '2026-01-01',
  );
}

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows placeholder icon when imageUrl is null', (tester) async {
    await tester.pumpWidget(wrap(TripCard(trip: _trip(imageUrl: null), baseUrl: 'http://localhost:8000', onEdit: () {}, onDelete: () {})));

    expect(find.byIcon(Icons.image), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('shows Image.network with prepended baseUrl for relative url',
      (tester) async {
    await tester.pumpWidget(wrap(TripCard(trip: _trip(imageUrl: '/uploads/x.jpg'), baseUrl: 'http://localhost:8000', onEdit: () {}, onDelete: () {})));

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, 'http://localhost:8000/uploads/x.jpg');
  });

  testWidgets('shows Image.network with absolute url as-is', (tester) async {
    await tester.pumpWidget(wrap(TripCard(trip: _trip(imageUrl: 'https://example.com/photo.jpg'), baseUrl: 'http://localhost:8000', onEdit: () {}, onDelete: () {})));

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, 'https://example.com/photo.jpg');
  });

  testWidgets('shows name and formatted dates', (tester) async {
    await tester.pumpWidget(wrap(TripCard(trip: _trip(), baseUrl: 'http://localhost:8000', onEdit: () {}, onDelete: () {})));

    expect(find.text('Viaje a Galicia'), findsOneWidget);
    expect(find.textContaining('01/06/2026'), findsOneWidget);
    expect(find.textContaining('10/06/2026'), findsOneWidget);
  });

  testWidgets('shows description when present', (tester) async {
    await tester.pumpWidget(wrap(TripCard(trip: _trip(description: 'Costas y comida'), baseUrl: 'http://localhost:8000', onEdit: () {}, onDelete: () {})));

    expect(find.text('Costas y comida'), findsOneWidget);
  });

  testWidgets('tapping edit calls onEdit', (tester) async {
    var edited = false;
    await tester.pumpWidget(wrap(TripCard(trip: _trip(), baseUrl: 'http://localhost:8000', onEdit: () => edited = true, onDelete: () {})));

    await tester.tap(find.byIcon(Icons.edit));
    expect(edited, isTrue);
  });

  testWidgets('tapping delete calls onDelete', (tester) async {
    var deleted = false;
    await tester.pumpWidget(wrap(TripCard(trip: _trip(), baseUrl: 'http://localhost:8000', onEdit: () {}, onDelete: () => deleted = true)));

    await tester.tap(find.byIcon(Icons.delete));
    expect(deleted, isTrue);
  });

  testWidgets('TripImageError shows broken image icon and text', (tester) async {
    await tester.pumpWidget(wrap(const TripImageError()));

    expect(find.byIcon(Icons.broken_image), findsOneWidget);
    expect(find.text('Imagen no disponible'), findsOneWidget);
  });
}
