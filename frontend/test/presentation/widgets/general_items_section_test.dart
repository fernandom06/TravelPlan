import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/itinerary_item.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/presentation/widgets/dashed_action_card.dart';
import 'package:frontend/presentation/widgets/general_items_section.dart';
import 'package:frontend/presentation/widgets/itinerary_place_card.dart';

ItineraryItem _item(int id, {required int position}) {
  return ItineraryItem(
    id: id,
    dayDate: null,
    slot: null,
    position: position,
    place: Place(
      id: id,
      name: 'Lugar $id',
      description: null,
      latitude: 42.5,
      longitude: -3.5,
      category: const Category(id: 1, name: 'Naturaleza', icon: 'nature'),
    ),
  );
}

Future<void> _dragCard(WidgetTester tester, Finder card, Offset to) async {
  final gesture = await tester.startGesture(tester.getCenter(card));
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
  await gesture.moveTo(to);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows the title with a counter and the cards', (tester) async {
    await tester.pumpWidget(
      wrap(
        GeneralItemsSection(
          items: [_item(1, position: 0), _item(2, position: 1)],
          onAcceptItem: (_, _) {},
          onDeleteItem: (_) {},
        ),
      ),
    );

    expect(find.text('LUGARES POR ASIGNAR'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byType(ItineraryPlaceCard), findsNWidgets(2));
  });

  testWidgets('renders the carousel as a horizontal scrollable list', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        GeneralItemsSection(
          items: [_item(1, position: 0), _item(2, position: 1)],
          onAcceptItem: (_, _) {},
          onDeleteItem: (_) {},
        ),
      ),
    );

    final scrollable = find.descendant(
      of: find.byType(GeneralItemsSection),
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);
    final axis = tester.widget<Scrollable>(scrollable).axisDirection;
    expect(axis, AxisDirection.right);
  });

  testWidgets('shows the empty hint when there are no items', (tester) async {
    await tester.pumpWidget(
      wrap(
        GeneralItemsSection(
          items: const [],
          onAcceptItem: (_, _) {},
          onDeleteItem: (_) {},
        ),
      ),
    );

    expect(find.text('Añade lugares al viaje'), findsOneWidget);
  });

  testWidgets('dropping a card on the empty section appends', (tester) async {
    ItineraryItem? accepted;
    int? acceptedIndex;
    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            ItineraryPlaceCard(item: _item(1, position: 0), onDelete: () {}),
            GeneralItemsSection(
              items: const [],
              onAcceptItem: (item, index) {
                accepted = item;
                acceptedIndex = index;
              },
              onDeleteItem: (_) {},
            ),
          ],
        ),
      ),
    );

    await _dragCard(
      tester,
      find.byType(ItineraryPlaceCard).first,
      tester.getCenter(find.byType(GeneralItemsSection)),
    );

    expect(accepted?.id, 1);
    expect(acceptedIndex, 0);
  });

  testWidgets('dropping a card on another card computes the insert index', (
    tester,
  ) async {
    ItineraryItem? accepted;
    int? acceptedIndex;
    await tester.pumpWidget(
      wrap(
        GeneralItemsSection(
          items: [_item(1, position: 0), _item(2, position: 1)],
          onAcceptItem: (item, index) {
            accepted = item;
            acceptedIndex = index;
          },
          onDeleteItem: (_) {},
        ),
      ),
    );

    final cards = find.byType(ItineraryPlaceCard);
    await _dragCard(tester, cards.at(1), tester.getCenter(cards.at(0)));

    expect(accepted?.id, 2);
    expect(acceptedIndex, 0);
  });

  testWidgets('delete button on a card calls onDeleteItem with its id', (
    tester,
  ) async {
    int? deletedId;
    await tester.pumpWidget(
      wrap(
        GeneralItemsSection(
          items: [_item(1, position: 0)],
          onAcceptItem: (_, _) {},
          onDeleteItem: (id) => deletedId = id,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    expect(deletedId, 1);
  });

  testWidgets('renders the trailing card after the mini-cards', (tester) async {
    await tester.pumpWidget(
      wrap(
        GeneralItemsSection(
          items: [_item(1, position: 0), _item(2, position: 1)],
          onAcceptItem: (_, _) {},
          onDeleteItem: (_) {},
          trailing: const DashedActionCard(
            label: '¿Añadimos un lugar?',
            onTap: _noop,
          ),
        ),
      ),
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.byType(DashedActionCard), findsOneWidget);
    final lastCardRight = tester.getTopRight(
      find.byType(ItineraryPlaceCard).last,
    );
    final cardLeft = tester.getTopLeft(find.byType(DashedActionCard));
    expect(cardLeft.dx, greaterThan(lastCardRight.dx));
  });

  testWidgets('empty state centers the trailing card without the hint', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        GeneralItemsSection(
          items: const [],
          onAcceptItem: (_, _) {},
          onDeleteItem: (_) {},
          trailing: const DashedActionCard(
            label: '¿Añadimos un lugar?',
            onTap: _noop,
          ),
        ),
      ),
    );

    expect(find.text('Añade lugares al viaje'), findsNothing);
    expect(find.byType(DashedActionCard), findsOneWidget);
    final sectionCenter = tester.getCenter(find.byType(GeneralItemsSection));
    final cardCenter = tester.getCenter(find.byType(DashedActionCard));
    expect((cardCenter.dx - sectionCenter.dx).abs(), lessThan(1));
  });

  testWidgets('does not render a trailing card without trailing', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        GeneralItemsSection(
          items: [_item(1, position: 0)],
          onAcceptItem: (_, _) {},
          onDeleteItem: (_) {},
        ),
      ),
    );

    expect(find.byType(DashedActionCard), findsNothing);
  });

  testWidgets('tapping the trailing card invokes its onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        GeneralItemsSection(
          items: const [],
          onAcceptItem: (_, _) {},
          onDeleteItem: (_) {},
          trailing: DashedActionCard(
            label: '¿Añadimos un lugar?',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('¿Añadimos un lugar?'));
    expect(tapped, isTrue);
  });

  testWidgets('grid layout renders no horizontal scrollable', (tester) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          child: GeneralItemsSection(
            items: [_item(1, position: 0), _item(2, position: 1)],
            onAcceptItem: (_, _) {},
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.grid,
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(GeneralItemsSection),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );
  });

  testWidgets('grid shows 2 cards per row on a 340-wide section', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          child: GeneralItemsSection(
            items: [
              _item(1, position: 0),
              _item(2, position: 1),
              _item(3, position: 2),
              _item(4, position: 3),
            ],
            onAcceptItem: (_, _) {},
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.grid,
          ),
        ),
      ),
    );

    final cards = find.byType(ItineraryPlaceCard);
    expect(cards, findsNWidgets(4));
    final row0 = tester.getTopLeft(cards.at(0)).dy;
    expect(tester.getTopLeft(cards.at(1)).dy, row0);
    expect(tester.getTopLeft(cards.at(2)).dy, greaterThan(row0));
    expect(
      tester.getTopLeft(cards.at(3)).dy,
      tester.getTopLeft(cards.at(2)).dy,
    );
  });

  testWidgets('grid shows 3 cards per row on a 500-wide section', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 500,
          child: GeneralItemsSection(
            items: [
              _item(1, position: 0),
              _item(2, position: 1),
              _item(3, position: 2),
              _item(4, position: 3),
            ],
            onAcceptItem: (_, _) {},
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.grid,
          ),
        ),
      ),
    );

    final cards = find.byType(ItineraryPlaceCard);
    expect(cards, findsNWidgets(4));
    final row0 = tester.getTopLeft(cards.at(0)).dy;
    expect(tester.getTopLeft(cards.at(1)).dy, row0);
    expect(tester.getTopLeft(cards.at(2)).dy, row0);
    expect(tester.getTopLeft(cards.at(3)).dy, greaterThan(row0));
  });

  testWidgets('grid cards use the computed width and vertical layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          child: GeneralItemsSection(
            items: [_item(1, position: 0), _item(2, position: 1)],
            onAcceptItem: (_, _) {},
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.grid,
          ),
        ),
      ),
    );

    final card = find.byType(ItineraryPlaceCard).first;
    final width = tester.getSize(card).width;
    expect(width, closeTo(154, 1));
    final placeCard = tester.widget<ItineraryPlaceCard>(card);
    expect(placeCard.horizontal, isFalse);
    expect(placeCard.width, closeTo(154, 1));
  });

  testWidgets('dropping a grid card on another grid card inserts before', (
    tester,
  ) async {
    ItineraryItem? accepted;
    int? acceptedIndex;
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          child: GeneralItemsSection(
            items: [
              _item(1, position: 0),
              _item(2, position: 1),
              _item(3, position: 2),
            ],
            onAcceptItem: (item, index) {
              accepted = item;
              acceptedIndex = index;
            },
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.grid,
          ),
        ),
      ),
    );

    final cards = find.byType(ItineraryPlaceCard);
    await _dragCard(tester, cards.at(1), tester.getCenter(cards.at(0)));

    expect(accepted?.id, 2);
    expect(acceptedIndex, 0);
  });

  testWidgets('dropping a card on the grid header appends', (tester) async {
    ItineraryItem? accepted;
    int? acceptedIndex;
    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            ItineraryPlaceCard(item: _item(1, position: 0), onDelete: () {}),
            SizedBox(
              width: 340,
              child: GeneralItemsSection(
                items: [_item(2, position: 0), _item(3, position: 1)],
                onAcceptItem: (item, index) {
                  accepted = item;
                  acceptedIndex = index;
                },
                onDeleteItem: (_) {},
                layout: GeneralItemsLayout.grid,
              ),
            ),
          ],
        ),
      ),
    );

    await _dragCard(
      tester,
      find.byType(ItineraryPlaceCard).first,
      tester.getTopLeft(find.text('LUGARES POR ASIGNAR')) +
          const Offset(40, 10),
    );

    expect(accepted?.id, 1);
    expect(acceptedIndex, 2);
  });

  testWidgets('grid empty state shows the hint', (tester) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          child: GeneralItemsSection(
            items: const [],
            onAcceptItem: (_, _) {},
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.grid,
          ),
        ),
      ),
    );

    expect(find.text('Añade lugares al viaje'), findsOneWidget);
    expect(find.byType(DashedActionCard), findsNothing);
  });

  testWidgets('grid empty state centers the trailing card', (tester) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          child: GeneralItemsSection(
            items: const [],
            onAcceptItem: (_, _) {},
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.grid,
            trailing: const DashedActionCard(
              label: '¿Añadimos un lugar?',
              onTap: _noop,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Añade lugares al viaje'), findsNothing);
    expect(find.byType(DashedActionCard), findsOneWidget);
    final sectionCenter = tester.getCenter(find.byType(GeneralItemsSection));
    final cardCenter = tester.getCenter(find.byType(DashedActionCard));
    expect((cardCenter.dx - sectionCenter.dx).abs(), lessThan(1));
  });

  testWidgets('grid renders the trailing card after the last card', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          child: GeneralItemsSection(
            items: [_item(1, position: 0), _item(2, position: 1)],
            onAcceptItem: (_, _) {},
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.grid,
            trailing: const DashedActionCard(
              label: '¿Añadimos un lugar?',
              onTap: _noop,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(DashedActionCard), findsOneWidget);
    final lastCard = find.byType(ItineraryPlaceCard).last;
    final trailingTop = tester.getTopLeft(find.byType(DashedActionCard));
    expect(trailingTop.dy, greaterThan(tester.getBottomLeft(lastCard).dy));
    final firstCardLeft = tester.getTopLeft(
      find.byType(ItineraryPlaceCard).at(0),
    );
    expect(trailingTop.dx, closeTo(firstCardLeft.dx, 1));
  });

  testWidgets('grid delete button calls onDeleteItem with its id', (
    tester,
  ) async {
    int? deletedId;
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          child: GeneralItemsSection(
            items: [_item(1, position: 0)],
            onAcceptItem: (_, _) {},
            onDeleteItem: (id) => deletedId = id,
            layout: GeneralItemsLayout.grid,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    expect(deletedId, 1);
  });
}

void _noop() {}
