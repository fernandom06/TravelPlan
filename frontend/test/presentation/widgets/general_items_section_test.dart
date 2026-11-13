import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/itinerary_item.dart';
import 'package:frontend/data/models/itinerary_slot.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/presentation/controllers/itinerary_drag_session.dart';
import 'package:frontend/presentation/widgets/general_items_section.dart';
import 'package:frontend/presentation/widgets/itinerary_place_card.dart';

ItineraryItem _item(
  int id, {
  required int position,
  DateTime? day,
  ItinerarySlot? slot,
}) {
  return ItineraryItem(
    id: id,
    dayDate: day,
    slot: slot,
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

Future<TestGesture> _startDrag(
  WidgetTester tester,
  Finder card,
  Offset to,
) async {
  final from = tester.getCenter(card);
  final gesture = await tester.startGesture(from);
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
  for (var step = 1; step <= 6; step++) {
    await gesture.moveTo(Offset.lerp(from, to, step / 6)!);
    await tester.pump();
  }
  await gesture.moveTo(to);
  await tester.pump();
  return gesture;
}

Future<void> _dragCard(WidgetTester tester, Finder card, Offset to) async {
  final gesture = await _startDrag(tester, card, to);
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

    expect(
      find.text('Todavía no hay lugares por asignar. ¿Añadimos uno?'),
      findsOneWidget,
    );
  });

  testWidgets('dropping a card on the empty section appends', (tester) async {
    ItineraryItem? accepted;
    int? acceptedIndex;
    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            // Viene de un bloque del día: al llegar a la lista general vacía
            // se coloca al final (índice 0), no es un no-op sobre sí mismo.
            ItineraryPlaceCard(
              item: _item(
                1,
                position: 0,
                day: DateTime(2026, 6, 1),
                slot: ItinerarySlot.morning,
              ),
              onDelete: () {},
            ),
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

  testWidgets('vertical empty state shows the hint', (tester) async {
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

    expect(
      find.text('Todavía no hay lugares por asignar. ¿Añadimos uno?'),
      findsOneWidget,
    );
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

  testWidgets('dropping a card on the vertical header inserts at the top', (
    tester,
  ) async {
    ItineraryItem? accepted;
    int? acceptedIndex;
    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            // Posición 2: el arrastrado no ocupaba ya el hueco superior, así
            // que el drop no es un no-op.
            ItineraryPlaceCard(item: _item(1, position: 2), onDelete: () {}),
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
    expect(acceptedIndex, 0);
  });

  testWidgets('the carousel inserts by horizontal position', (tester) async {
    int? acceptedIndex;
    await tester.pumpWidget(
      wrap(
        GeneralItemsSection(
          items: [_item(1, position: 0), _item(2, position: 1)],
          onAcceptItem: (_, index) => acceptedIndex = index,
          onDeleteItem: (_) {},
        ),
      ),
    );

    // Arrastrar la primera tarjeta sobre el centro de la segunda: el hueco
    // cae entre ambas (índice 1), medido en el eje horizontal.
    final cards = find.byType(ItineraryPlaceCard);
    await _dragCard(tester, cards.at(0), tester.getCenter(cards.at(1)));

    expect(acceptedIndex, 1);
  });

  testWidgets('dropping below the last vertical card appends', (tester) async {
    int? acceptedIndex;
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          child: GeneralItemsSection(
            items: [_item(1, position: 0), _item(2, position: 1)],
            onAcceptItem: (_, index) => acceptedIndex = index,
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.vertical,
          ),
        ),
      ),
    );

    await _dragCard(
      tester,
      find.byType(ItineraryPlaceCard).first,
      tester.getBottomLeft(find.byType(GeneralItemsSection)) +
          const Offset(60, -2),
    );

    expect(acceptedIndex, 2);
  });

  testWidgets('dropping a card on its own place does not move it', (
    tester,
  ) async {
    var accepted = 0;
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 340,
          child: GeneralItemsSection(
            items: [_item(1, position: 0), _item(2, position: 1)],
            onAcceptItem: (_, _) => accepted++,
            onDeleteItem: (_) {},
            layout: GeneralItemsLayout.vertical,
          ),
        ),
      ),
    );

    final card = find.byType(ItineraryPlaceCard).first;
    await _dragCard(tester, card, tester.getCenter(card));

    expect(accepted, 0);
  });

  testWidgets(
    'shows the drop placeholder in the vertical list while dragging',
    (tester) async {
      final session = ItineraryDragSession();
      addTearDown(session.dispose);
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 340,
            child: GeneralItemsSection(
              items: [_item(1, position: 0), _item(2, position: 1)],
              onAcceptItem: (_, _) {},
              onDeleteItem: (_) {},
              layout: GeneralItemsLayout.vertical,
              dragSession: session,
            ),
          ),
        ),
      );

      const placeholder = ValueKey('itinerary-drop-placeholder');
      expect(find.byKey(placeholder), findsNothing);

      final cards = find.byType(ItineraryPlaceCard);
      final gesture = await _startDrag(
        tester,
        cards.at(1),
        tester.getCenter(cards.at(0)),
      );

      expect(find.byKey(placeholder), findsOneWidget);
      expect(session.previewContainer, (day: null, slot: null));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byKey(placeholder), findsNothing);
    },
  );

  testWidgets('shows the drop placeholder in the empty vertical list', (
    tester,
  ) async {
    final session = ItineraryDragSession();
    addTearDown(session.dispose);
    final external = _item(
      1,
      position: 0,
      day: DateTime(2026, 6, 1),
      slot: ItinerarySlot.morning,
    );
    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            ItineraryPlaceCard(
              item: external,
              onDelete: () {},
              onDragStarted: (anchor) => session.start(external, anchor),
              onDragEnd: session.end,
            ),
            SizedBox(
              width: 340,
              child: GeneralItemsSection(
                items: const [],
                onAcceptItem: (_, _) {},
                onDeleteItem: (_) {},
                layout: GeneralItemsLayout.vertical,
                dragSession: session,
              ),
            ),
          ],
        ),
      ),
    );

    const placeholder = ValueKey('itinerary-drop-placeholder');
    expect(find.byKey(placeholder), findsNothing);

    final gesture = await _startDrag(
      tester,
      find.byType(ItineraryPlaceCard).first,
      tester.getCenter(find.byType(GeneralItemsSection)),
    );

    expect(session.previewIndex, 0);
    expect(find.byKey(placeholder), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byKey(placeholder), findsNothing);
  });

  testWidgets('shows the drop placeholder in the empty carousel', (
    tester,
  ) async {
    final session = ItineraryDragSession();
    addTearDown(session.dispose);
    final external = _item(
      1,
      position: 0,
      day: DateTime(2026, 6, 1),
      slot: ItinerarySlot.morning,
    );
    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            ItineraryPlaceCard(
              item: external,
              onDelete: () {},
              onDragStarted: (anchor) => session.start(external, anchor),
              onDragEnd: session.end,
            ),
            GeneralItemsSection(
              items: const [],
              onAcceptItem: (_, _) {},
              onDeleteItem: (_) {},
              dragSession: session,
            ),
          ],
        ),
      ),
    );

    const placeholder = ValueKey('itinerary-drop-placeholder');
    expect(find.byKey(placeholder), findsNothing);

    final gesture = await _startDrag(
      tester,
      find.byType(ItineraryPlaceCard).first,
      tester.getCenter(find.byType(GeneralItemsSection)),
    );

    expect(session.previewIndex, 0);
    expect(find.byKey(placeholder), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byKey(placeholder), findsNothing);
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
