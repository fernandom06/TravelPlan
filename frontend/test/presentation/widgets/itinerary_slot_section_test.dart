import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/itinerary_item.dart';
import 'package:frontend/data/models/itinerary_slot.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/presentation/widgets/dashed_border_container.dart';
import 'package:frontend/presentation/widgets/itinerary_place_card.dart';
import 'package:frontend/presentation/widgets/itinerary_slot_section.dart';

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

final _slot = ItinerarySlot.morning;

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

  testWidgets('shows the slot title and its cards', (tester) async {
    await tester.pumpWidget(
      wrap(
        ItinerarySlotSection(
          title: 'Mañana',
          slot: _slot,
          items: [_item(1, position: 0), _item(2, position: 1)],
          onAcceptItem: (_, _, _) {},
          onDeleteItem: (_) {},
        ),
      ),
    );

    expect(find.text('Mañana'), findsOneWidget);
    expect(find.byType(ItineraryPlaceCard), findsNWidgets(2));
    expect(find.text('Lugar 1'), findsOneWidget);
    expect(find.text('Lugar 2'), findsOneWidget);
  });

  testWidgets('renders the slot header with its timeline icon', (tester) async {
    await tester.pumpWidget(
      wrap(
        ItinerarySlotSection(
          title: 'Mañana',
          slot: _slot,
          items: const [],
          onAcceptItem: (_, _, _) {},
          onDeleteItem: (_) {},
        ),
      ),
    );

    expect(find.byIcon(Icons.light_mode), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny), findsNothing);
    expect(find.byIcon(Icons.dark_mode), findsNothing);
  });

  testWidgets('renders a hollow circular marker in the timeline rail', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ItinerarySlotSection(
          title: 'Mañana',
          slot: _slot,
          items: const [],
          onAcceptItem: (_, _, _) {},
          onDeleteItem: (_) {},
        ),
      ),
    );

    final marker = tester.widget<Container>(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
      ),
    );
    final decoration = marker.decoration as BoxDecoration;
    expect(decoration.color, AppColors.background);
    expect(decoration.border, Border.all(color: AppColors.primary, width: 2));
  });

  testWidgets('renders the connecting rail line for non-final sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ItinerarySlotSection(
          title: 'Mañana',
          slot: _slot,
          items: const [],
          onAcceptItem: (_, _, _) {},
          onDeleteItem: (_) {},
        ),
      ),
    );

    final line = find.byWidgetPredicate(
      (w) =>
          w is Container && w.color == AppColors.primary.withValues(alpha: 0.4),
    );
    expect(line, findsOneWidget);
  });

  testWidgets('isLast stops the rail at the marker', (tester) async {
    await tester.pumpWidget(
      wrap(
        ItinerarySlotSection(
          title: 'Noche',
          slot: ItinerarySlot.night,
          isLast: true,
          items: const [],
          onAcceptItem: (_, _, _) {},
          onDeleteItem: (_) {},
        ),
      ),
    );

    final line = find.byWidgetPredicate(
      (w) =>
          w is Container && w.color == AppColors.primary.withValues(alpha: 0.4),
    );
    expect(line, findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the empty hint when there are no items', (tester) async {
    await tester.pumpWidget(
      wrap(
        ItinerarySlotSection(
          title: 'Mañana',
          slot: _slot,
          items: const [],
          onAcceptItem: (_, _, _) {},
          onDeleteItem: (_) {},
        ),
      ),
    );

    expect(find.text('Arrastra lugares aquí'), findsOneWidget);
  });

  testWidgets('dropping a card on the empty section appends to the end', (
    tester,
  ) async {
    ItineraryItem? accepted;
    ItinerarySlot? acceptedSlot;
    int? acceptedIndex;
    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            ItineraryPlaceCard(item: _item(1, position: 0), onDelete: () {}),
            ItinerarySlotSection(
              title: 'Mañana',
              slot: _slot,
              items: const [],
              onAcceptItem: (item, slot, index) {
                accepted = item;
                acceptedSlot = slot;
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
      tester.getCenter(find.byType(ItinerarySlotSection)),
    );

    expect(accepted?.id, 1);
    expect(acceptedSlot, _slot);
    expect(acceptedIndex, 0);
  });

  testWidgets('dropping a card on another card computes the insert index', (
    tester,
  ) async {
    ItineraryItem? accepted;
    int? acceptedIndex;
    await tester.pumpWidget(
      wrap(
        ItinerarySlotSection(
          title: 'Mañana',
          slot: _slot,
          items: [_item(1, position: 0), _item(2, position: 1)],
          onAcceptItem: (item, _, index) {
            accepted = item;
            acceptedIndex = index;
          },
          onDeleteItem: (_) {},
        ),
      ),
    );

    // Arrastrar la card 2 sobre la card 1 → insertar antes del índice 0.
    final cards = find.byType(ItineraryPlaceCard);
    await _dragCard(tester, cards.at(1), tester.getCenter(cards.at(0)));

    expect(accepted?.id, 2);
    expect(acceptedIndex, 0);
  });

  testWidgets('dropping on the section title appends', (tester) async {
    ItineraryItem? accepted;
    int? acceptedIndex;
    await tester.pumpWidget(
      wrap(
        ItinerarySlotSection(
          title: 'Mañana',
          slot: _slot,
          items: [_item(1, position: 0), _item(2, position: 1)],
          onAcceptItem: (item, _, index) {
            accepted = item;
            acceptedIndex = index;
          },
          onDeleteItem: (_) {},
        ),
      ),
    );

    await _dragCard(
      tester,
      find.byType(ItineraryPlaceCard).first,
      tester.getCenter(find.text('Mañana')),
    );

    expect(accepted?.id, 1);
    expect(acceptedIndex, 2);
  });

  testWidgets('delete button on a card calls onDeleteItem with its id', (
    tester,
  ) async {
    int? deletedId;
    await tester.pumpWidget(
      wrap(
        ItinerarySlotSection(
          title: 'Mañana',
          slot: _slot,
          items: [_item(1, position: 0)],
          onAcceptItem: (_, _, _) {},
          onDeleteItem: (id) => deletedId = id,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    expect(deletedId, 1);
  });

  testWidgets('wraps assigned cards in a single dashed container', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ItinerarySlotSection(
          title: 'Mañana',
          slot: _slot,
          items: [_item(1, position: 0), _item(2, position: 1)],
          onAcceptItem: (_, _, _) {},
          onDeleteItem: (_) {},
        ),
      ),
    );

    expect(find.byType(DashedBorderContainer), findsOneWidget);
    expect(find.text('Arrastra lugares aquí'), findsNothing);
  });

  testWidgets('dashed border turns accent while dragging over the slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            ItineraryPlaceCard(item: _item(1, position: 0), onDelete: () {}),
            ItinerarySlotSection(
              title: 'Mañana',
              slot: _slot,
              items: const [],
              onAcceptItem: (_, _, _) {},
              onDeleteItem: (_) {},
            ),
          ],
        ),
      ),
    );

    Color borderColor() {
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(DashedBorderContainer),
          matching: find.byType(CustomPaint),
        ),
      );
      return (paint.painter as DashedBorderPainter).color;
    }

    expect(borderColor(), AppColors.muted);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ItineraryPlaceCard).first),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(tester.getCenter(find.byType(ItinerarySlotSection)));
    await tester.pump();

    expect(borderColor(), AppColors.accent);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(borderColor(), AppColors.muted);
  });
}
