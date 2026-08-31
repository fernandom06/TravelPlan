import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
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

  testWidgets('shows a drag handle indicator', (tester) async {
    await tester.pumpWidget(
      _wrap(ItineraryPlaceCard(item: _item(), onDelete: () {})),
    );

    expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
  });

  testWidgets('uses immediate Draggable on desktop platforms', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await tester.pumpWidget(
        _wrap(ItineraryPlaceCard(item: _item(), onDelete: () {})),
      );

      expect(find.byType(Draggable<ItineraryItem>), findsOneWidget);
      expect(find.byType(LongPressDraggable<ItineraryItem>), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('delete button calls onDelete', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      _wrap(ItineraryPlaceCard(item: _item(), onDelete: () => deleted = true)),
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    expect(deleted, isTrue);
  });

  testWidgets('category icon sits in a circular tinted avatar', (tester) async {
    await tester.pumpWidget(
      _wrap(ItineraryPlaceCard(item: _item(), onDelete: () {})),
    );

    final avatar = tester.widget<CircleAvatar>(
      find.ancestor(
        of: find.byIcon(Icons.park),
        matching: find.byType(CircleAvatar),
      ),
    );
    expect(avatar.radius, greaterThanOrEqualTo(16));
    expect(avatar.backgroundColor, AppColors.primary.withValues(alpha: 0.15));
  });

  testWidgets('card casts the soft AppShadows shadow', (tester) async {
    await tester.pumpWidget(
      _wrap(ItineraryPlaceCard(item: _item(), onDelete: () {})),
    );

    final container = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Mirador de la Catedral'),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration as BoxDecoration?;
    expect(decoration?.boxShadow, contains(AppShadows.soft));
  });

  testWidgets('vertical card applies a custom width when provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Center(
          child: ItineraryPlaceCard(
            item: _item(),
            onDelete: () {},
            horizontal: false,
            width: 200,
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(ItineraryPlaceCard)).width,
      closeTo(200, 0.5),
    );
  });

  testWidgets('vertical card keeps the default 104 width without width', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Center(
          child: ItineraryPlaceCard(
            item: _item(),
            onDelete: () {},
            horizontal: false,
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(ItineraryPlaceCard)).width,
      closeTo(104, 0.5),
    );
  });

  testWidgets('drag feedback uses the configured width for vertical cards', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await tester.pumpWidget(
        _wrap(
          ItineraryPlaceCard(
            item: _item(),
            onDelete: () {},
            horizontal: false,
            width: 200,
          ),
        ),
      );

      final draggable = tester.widget<Draggable<ItineraryItem>>(
        find.byType(Draggable<ItineraryItem>),
      );
      final feedback = draggable.feedback as Material;
      expect(feedback.child, isA<SizedBox>());
      expect((feedback.child as SizedBox).width, 200);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('long place names truncate with ellipsis without overflow', (
    tester,
  ) async {
    final longName = List.filled(220, 'A').join();
    final item = ItineraryItem(
      id: 3,
      dayDate: null,
      slot: null,
      position: 0,
      place: Place(
        id: 1,
        name: longName,
        description: null,
        latitude: 42.5,
        longitude: -3.5,
        category: const Category(id: 1, name: 'Naturaleza', icon: 'nature'),
      ),
    );

    await tester.pumpWidget(
      _wrap(ItineraryPlaceCard(item: item, onDelete: () {})),
    );

    final text = tester.widget<Text>(find.text(longName));
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
