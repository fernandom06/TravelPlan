import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/category.dart';
import 'package:frontend/data/models/itinerary_item.dart';
import 'package:frontend/data/models/itinerary_slot.dart';
import 'package:frontend/data/models/place.dart';
import 'package:frontend/presentation/controllers/itinerary_controller.dart';
import 'package:frontend/presentation/controllers/itinerary_drag_session.dart';

ItineraryItem _item(int id, {required int position, String? name}) {
  return ItineraryItem(
    id: id,
    dayDate: DateTime(2026, 6, 3),
    slot: ItinerarySlot.night,
    position: position,
    place: Place(
      id: id,
      name: name ?? 'Lugar $id',
      description: null,
      latitude: 42.5,
      longitude: -3.5,
      category: const Category(id: 1, name: 'Naturaleza', icon: 'nature'),
    ),
  );
}

void main() {
  group('computeInsertIndex', () {
    test('dropping on the centre of the first card inserts before it', () {
      expect(computeInsertIndex(cardCenters: [50, 150], dropPosition: 50), 0);
    });

    test('dropping on the centre of the second card inserts before it', () {
      expect(computeInsertIndex(cardCenters: [50, 150], dropPosition: 150), 1);
    });

    test('dropping below the last card appends', () {
      expect(computeInsertIndex(cardCenters: [50, 150], dropPosition: 300), 2);
    });

    test('dropping above every card inserts at the top', () {
      expect(computeInsertIndex(cardCenters: [50, 150], dropPosition: 10), 0);
    });

    test('a container without cards inserts at the top', () {
      expect(computeInsertIndex(cardCenters: [], dropPosition: 10), 0);
    });

    test('works along the horizontal axis of the carousel', () {
      expect(computeInsertIndex(cardCenters: [80, 240], dropPosition: 240), 1);
      expect(computeInsertIndex(cardCenters: [80, 240], dropPosition: 500), 2);
    });

    test(
      'the computed index reorders the moved item before the target card',
      () {
        final items = [
          _item(1, position: 0, name: 'A'),
          _item(2, position: 1, name: 'B'),
        ];

        // El item en la posición 1 se suelta sobre el centro del item en la
        // posición 0: el índice calculado es 0 y el orden resultante [B, A].
        final index = computeInsertIndex(
          cardCenters: const [50, 150],
          dropPosition: 50,
        );
        final moved = computeMove(
          items,
          2,
          DateTime(2026, 6, 3),
          ItinerarySlot.night,
          index,
        );

        expect(moved.map((item) => item.place.name), ['B', 'A']);
        expect(moved.first.position, 0);
        expect(moved.last.position, 1);
      },
    );
  });

  group('ItineraryDragSession', () {
    test('tracks the dragged item and the preview, then clears on end', () {
      final session = ItineraryDragSession();
      addTearDown(session.dispose);
      var notifications = 0;
      session.addListener(() => notifications++);
      final item = _item(1, position: 0);

      session.start(item, Offset.zero);

      expect(session.draggedItem, item);
      expect(session.previewContainer, isNull);
      expect(session.previewIndex, isNull);
      expect(notifications, 1);

      const container = (day: null, slot: null);
      session.updatePreview(container, 1);

      expect(session.previewContainer, container);
      expect(session.previewIndex, 1);
      expect(notifications, 2);

      session.end();

      expect(session.draggedItem, isNull);
      expect(session.previewContainer, isNull);
      expect(session.previewIndex, isNull);
      expect(notifications, 3);
    });

    test('carries the grab anchor of the drag and clears it on end', () {
      final session = ItineraryDragSession();
      addTearDown(session.dispose);
      var notifications = 0;
      session.addListener(() => notifications++);
      final item = _item(1, position: 0);

      session.start(item, const Offset(8, 24));

      expect(session.dragAnchor, const Offset(8, 24));
      expect(session.draggedItem, item);
      expect(notifications, 1);

      session.end();

      expect(session.dragAnchor, Offset.zero);
      expect(session.draggedItem, isNull);
      expect(notifications, 2);
    });
  });
}
