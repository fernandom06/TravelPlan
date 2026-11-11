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

ItineraryItem _longItem(int id) {
  return ItineraryItem(
    id: id,
    dayDate: null,
    slot: null,
    position: 0,
    place: Place(
      id: id,
      name: List.filled(200, 'A').join(),
      description: null,
      latitude: 42.5,
      longitude: -3.5,
      category: Category(
        id: 1,
        name: List.filled(80, 'C').join(),
        icon: 'nature',
      ),
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

  testWidgets('shows the title and the cards without a counter', (
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

    expect(find.text('Lugares por asignar'), findsOneWidget);
    expect(find.text('2'), findsNothing);
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

  testWidgets('vertical layout renders no horizontal scrollable', (
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
            layout: GeneralItemsLayout.vertical,
          ),
        ),
      ),
    );

    final scrollables = tester.widgetList<Scrollable>(
      find.descendant(
        of: find.byType(GeneralItemsSection),
        matching: find.byType(Scrollable),
      ),
    );
    for (final scrollable in scrollables) {
      expect(scrollable.axisDirection, AxisDirection.down);
    }
  });

  testWidgets('vertical layout renders one card per row at full width', (
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
            layout: GeneralItemsLayout.vertical,
          ),
        ),
      ),
    );

    final cards = find.byType(ItineraryPlaceCard);
    expect(cards, findsNWidgets(4));
    final widths = <double>[
      for (var i = 0; i < 4; i++) tester.getSize(cards.at(i)).width,
    ];
    expect(widths.toSet(), hasLength(1));
    expect(widths.first, greaterThan(280));
    for (var i = 1; i < 4; i++) {
      expect(
        tester.getTopLeft(cards.at(i)).dy,
        greaterThan(tester.getTopLeft(cards.at(i - 1)).dy),
      );
    }
    final placeCard = tester.widget<ItineraryPlaceCard>(cards.first);
    expect(placeCard.horizontal, isTrue);
  });

  testWidgets('vertical list centers the header with its cards when there is '
      'spare height', (tester) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          height: 600,
          child: GeneralItemsSection(
            items: [_item(1, position: 0)],
            onAcceptItem: (_, _) {},
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.vertical,
          ),
        ),
      ),
    );

    final panel = tester.getRect(
      find.byKey(const ValueKey('general-items-panel')),
    );
    final header = tester.getRect(find.text('Lugares por asignar'));
    final card = tester.getRect(find.byType(ItineraryPlaceCard));
    // Header sits above the card, and the whole group is centered.
    expect(header.bottom, lessThanOrEqualTo(card.top));
    expect((header.top + card.bottom) / 2, closeTo(panel.center.dy, 10));
  });

  testWidgets('vertical list puts the trailing card below at full width', (
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
            layout: GeneralItemsLayout.vertical,
            trailing: const DashedActionCard(
              label: '¿Añadimos un lugar?',
              onTap: _noop,
              compact: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(DashedActionCard), findsOneWidget);
    final lastCard = find.byType(ItineraryPlaceCard).last;
    final trailingTop = tester.getTopLeft(find.byType(DashedActionCard));
    expect(trailingTop.dy, greaterThan(tester.getBottomLeft(lastCard).dy));
    final cardWidth = tester.getSize(lastCard).width;
    expect(tester.getSize(find.byType(DashedActionCard)).width, cardWidth);
    expect(
      tester.getSize(find.byType(DashedActionCard)).height,
      closeTo(72, 1),
    );
  });

  testWidgets('vertical empty state shows only the add card with trailing', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          child: GeneralItemsSection(
            items: const [],
            onAcceptItem: (_, _) {},
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.vertical,
            trailing: const DashedActionCard(
              label: '¿Añadimos un lugar?',
              onTap: _noop,
              compact: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Añade lugares al viaje'), findsNothing);
    expect(find.byType(DashedActionCard), findsOneWidget);
  });

  testWidgets('vertical empty state without trailing shows the hint', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          child: GeneralItemsSection(
            items: const [],
            onAcceptItem: (_, _) {},
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.vertical,
          ),
        ),
      ),
    );

    expect(find.text('Añade lugares al viaje'), findsOneWidget);
    expect(find.byType(DashedActionCard), findsNothing);
  });

  testWidgets('dropping a vertical card on another vertical card inserts '
      'before', (tester) async {
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
            layout: GeneralItemsLayout.vertical,
          ),
        ),
      ),
    );

    final cards = find.byType(ItineraryPlaceCard);
    await _dragCard(tester, cards.at(1), tester.getCenter(cards.at(0)));

    expect(accepted?.id, 2);
    expect(acceptedIndex, 0);
  });

  testWidgets('dropping a card on the vertical header appends', (tester) async {
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
                layout: GeneralItemsLayout.vertical,
              ),
            ),
          ],
        ),
      ),
    );

    await _dragCard(
      tester,
      find.byType(ItineraryPlaceCard).first,
      tester.getTopLeft(find.text('Lugares por asignar')) +
          const Offset(40, 10),
    );

    expect(accepted?.id, 1);
    expect(acceptedIndex, 2);
  });

  testWidgets('vertical delete button calls onDeleteItem with its id', (
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
            layout: GeneralItemsLayout.vertical,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    expect(deletedId, 1);
  });

  testWidgets('carousel handles very long names without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        GeneralItemsSection(
          items: [_longItem(1)],
          onAcceptItem: (_, _) {},
          onDeleteItem: (_) {},
        ),
      ),
    );

    expect(find.text(List.filled(200, 'A').join()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vertical list handles very long names without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          child: GeneralItemsSection(
            items: [_longItem(1)],
            onAcceptItem: (_, _) {},
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.vertical,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final nameText = tester.widget<Text>(
      find.text(List.filled(200, 'A').join()),
    );
    expect(nameText.overflow, TextOverflow.ellipsis);
  });

  testWidgets('vertical empty state keeps the add card visible and tappable', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          child: GeneralItemsSection(
            items: const [],
            onAcceptItem: (_, _) {},
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.vertical,
            trailing: DashedActionCard(
              label: '¿Añadimos un lugar?',
              onTap: () => tapped = true,
              compact: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(DashedActionCard), findsOneWidget);
    expect(find.text('Añade lugares al viaje'), findsNothing);
    await tester.tap(find.text('¿Añadimos un lugar?'));
    expect(tapped, isTrue);
  });

  testWidgets('vertical panel is unframed at rest and fills while dragging', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          child: GeneralItemsSection(
            items: [_item(1, position: 0)],
            onAcceptItem: (_, _) {},
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.vertical,
          ),
        ),
      ),
    );

    BoxDecoration? panelDecoration() {
      final animated = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('general-items-panel')),
      );
      return animated.decoration as BoxDecoration?;
    }

    expect(panelDecoration()?.color, isNull);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ItineraryPlaceCard).first),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(tester.getCenter(find.text('Lugares por asignar')));
    await tester.pump();

    expect(panelDecoration()?.color, isNotNull);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(panelDecoration()?.color, isNull);
  });

  testWidgets('vertical panel fills the height it is given and scrolls when '
      'the cards overflow', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          child: GeneralItemsSection(
            items: [for (var i = 0; i < 12; i++) _item(i, position: i)],
            onAcceptItem: (_, _) {},
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.vertical,
          ),
        ),
      ),
    );

    final section = tester.getRect(find.byType(GeneralItemsSection));
    expect(section.height, closeTo(600, 1));
    final scrollable = tester.widget<Scrollable>(
      find.descendant(
        of: find.byType(GeneralItemsSection),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.axisDirection, AxisDirection.down);
    await tester.drag(
      find.descendant(
        of: find.byType(GeneralItemsSection),
        matching: find.byType(Scrollable),
      ),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
