import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/itinerary_item.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/presentation/widgets/itinerary_place_card.dart';

ItineraryItem _item() {
  return ItineraryItem(
    id: 3,
    dayDate: null,
    slot: null,
    position: 0,
    place: Place(
      id: 1,
      name: 'Mirador de la Catedral',
      description: null,
      latitude: 42.5,
      longitude: -3.5,
      category: const Category(id: 1, name: 'Naturaleza', icon: 'nature'),
    ),
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows the place name and category icon', (tester) async {
    await tester.pumpWidget(
      _wrap(ItineraryPlaceCard(item: _item(), onDelete: () {})),
    );

    expect(find.text('Mirador de la Catedral'), findsOneWidget);
    expect(find.byIcon(Icons.park), findsOneWidget);
  });

  testWidgets('is a LongPressDraggable carrying the itinerary item', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(ItineraryPlaceCard(item: _item(), onDelete: () {})),
    );

    final draggable = tester.widget<LongPressDraggable<ItineraryItem>>(
      find.byType(LongPressDraggable<ItineraryItem>),
    );
    expect(draggable.data, _item());
  });

  testWidgets('delete button calls onDelete', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      _wrap(ItineraryPlaceCard(item: _item(), onDelete: () => deleted = true)),
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    expect(deleted, isTrue);
  });
}
