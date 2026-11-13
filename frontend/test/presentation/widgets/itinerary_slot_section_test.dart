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

    expect(find.byIcon(Icons.wb_twilight), findsOneWidget);
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

    // Tests run on the Android target platform, so the hint names the
    // long-press gesture.
    expect(find.text('Mantén pulsado y arrastra lugares aquí'), findsOneWidget);
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

  testWidgets('renders assigned cards directly on the timeline when at rest', (
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

    expect(find.byType(DashedBorderContainer), findsNothing);
    expect(find.byType(ItineraryPlaceCard), findsNWidgets(2));
    expect(find.text('Arrastra lugares aquí'), findsNothing);
  });

  testWidgets('shows the dashed drop zone while dragging over a slot with '
      'items', (tester) async {
    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            ItineraryPlaceCard(item: _item(1, position: 0), onDelete: () {}),
            ItinerarySlotSection(
              title: 'Mañana',
              slot: _slot,
              items: [_item(2, position: 0)],
              onAcceptItem: (_, _, _) {},
              onDeleteItem: (_) {},
            ),
          ],
        ),
      ),
    );

    expect(find.byType(DashedBorderContainer), findsNothing);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ItineraryPlaceCard).first),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(tester.getCenter(find.text('Mañana')));
    await tester.pump();

    expect(find.byType(DashedBorderContainer), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byType(DashedBorderContainer), findsNothing);
  });

  testWidgets('tapping the empty drop zone asks to open the picker', (
    tester,
  ) async {
    var picked = 0;
    await tester.pumpWidget(
      wrap(
        ItinerarySlotSection(
          title: 'Mañana',
          slot: _slot,
          items: const [],
          onAcceptItem: (_, _, _) {},
          onDeleteItem: (_) {},
          onAddPlace: () => picked++,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    expect(picked, 1);
  });

  testWidgets('without onAddPlace the empty zone stays drag-only', (
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

    // No Semantics button wraps the zone when there is no tap handler.
    expect(find.bySemanticsLabel('Añadir lugar en Mañana'), findsNothing);
  });

  testWidgets('the empty-zone label carries the day context', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        ItinerarySlotSection(
          title: 'Mañana',
          slot: _slot,
          items: const [],
          onAcceptItem: (_, _, _) {},
          onDeleteItem: (_) {},
          onAddPlace: () {},
          dayLabel: 'Día 2 · 02 Jun',
        ),
      ),
    );

    // "Mañana" alone is ambiguous across days; the label names the day too.
    expect(
      find.bySemanticsLabel(RegExp('Añadir lugar en Mañana · Día 2 · 02 Jun')),
      findsOneWidget,
    );
    semantics.dispose();
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

  testWidgets('the hint keeps its secondary color while the slot is dragged '
      'over', (tester) async {
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

    Color hintColor() => tester
        .widget<Text>(find.text('Mantén pulsado y arrastra lugares aquí'))
        .style!
        .color!;

    expect(hintColor(), AppColors.textSecondary);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ItineraryPlaceCard).first),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(tester.getCenter(find.byType(ItinerarySlotSection)));
    await tester.pump();

    // Mint accent text on the paper background is ~2.1:1 — the hint stays
    // secondary even while the drop zone is highlighted.
    expect(hintColor(), AppColors.textSecondary);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('slot with five or more items keeps cards on the timeline at '
      'rest', (tester) async {
    await tester.pumpWidget(
      wrap(
        ItinerarySlotSection(
          title: 'Mañana',
          slot: _slot,
          items: [for (var i = 1; i <= 5; i++) _item(i, position: i - 1)],
          onAcceptItem: (_, _, _) {},
          onDeleteItem: (_) {},
        ),
      ),
    );

    expect(find.byType(DashedBorderContainer), findsNothing);
    expect(find.byType(ItineraryPlaceCard), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('slot handles very long place and category names without '
      'overflow', (tester) async {
    final longName = List.filled(200, 'A').join();
    final longCategory = List.filled(80, 'C').join();
    final item = ItineraryItem(
      id: 1,
      dayDate: null,
      slot: null,
      position: 0,
      place: Place(
        id: 1,
        name: longName,
        description: null,
        latitude: 42.5,
        longitude: -3.5,
        category: Category(id: 1, name: longCategory, icon: 'nature'),
      ),
    );

    await tester.pumpWidget(
      wrap(
        ItinerarySlotSection(
          title: 'Mañana',
          slot: _slot,
          items: [item],
          onAcceptItem: (_, _, _) {},
          onDeleteItem: (_) {},
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text(longName)).overflow,
      TextOverflow.ellipsis,
    );
    expect(
      tester.widget<Text>(find.text(longCategory)).overflow,
      TextOverflow.ellipsis,
    );
    expect(tester.takeException(), isNull);
  });
}
