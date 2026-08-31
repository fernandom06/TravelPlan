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
}

void _noop() {}
