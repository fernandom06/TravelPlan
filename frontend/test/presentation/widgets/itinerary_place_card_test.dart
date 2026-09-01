import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/category_palette.dart';
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

ItineraryItem _itemWithCategory(Category category, {String name = 'Mirador'}) {
  return ItineraryItem(
    id: 3,
    dayDate: null,
    slot: null,
    position: 0,
    place: Place(
      id: 1,
      name: name,
      description: null,
      latitude: 42.5,
      longitude: -3.5,
      category: category,
    ),
  );
}

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

  testWidgets(
    'category icon sits in a solid circular avatar colored by category',
    (tester) async {
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
      expect(
        avatar.backgroundColor,
        categoryColorFor(const Category(id: 1, name: 'Naturaleza')),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.park));
      expect(icon.color, Colors.white);
    },
  );

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

  testWidgets(
    'horizontal card shows the category name next to the place name',
    (tester) async {
      await tester.pumpWidget(
        _wrap(ItineraryPlaceCard(item: _item(), onDelete: () {})),
      );

      expect(find.text('Mirador de la Catedral'), findsOneWidget);
      expect(find.text('Naturaleza'), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    },
  );

  testWidgets('two categories produce differently colored icon circles', (
    tester,
  ) async {
    final nature = _itemWithCategory(
      const Category(id: 1, name: 'Naturaleza', icon: 'nature'),
    );
    final cafe = _itemWithCategory(
      const Category(id: 2, name: 'Café', icon: 'cafe'),
    );

    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 600,
          child: Row(
            children: [
              Expanded(
                child: ItineraryPlaceCard(item: nature, onDelete: () {}),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ItineraryPlaceCard(item: cafe, onDelete: () {}),
              ),
            ],
          ),
        ),
      ),
    );

    final natureAvatar = tester.widget<CircleAvatar>(
      find.ancestor(
        of: find.byIcon(Icons.park),
        matching: find.byType(CircleAvatar),
      ),
    );
    final cafeAvatar = tester.widget<CircleAvatar>(
      find.ancestor(
        of: find.byIcon(Icons.local_cafe),
        matching: find.byType(CircleAvatar),
      ),
    );
    expect(natureAvatar.backgroundColor, isNot(cafeAvatar.backgroundColor));
  });

  testWidgets('stacked card shows icon, name and category centered', (
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

    expect(find.text('Mirador de la Catedral'), findsOneWidget);
    expect(find.text('Naturaleza'), findsOneWidget);
    final nameText = tester.widget<Text>(find.text('Mirador de la Catedral'));
    expect(nameText.textAlign, TextAlign.center);
  });

  testWidgets('long place and category names ellipsize without overflow', (
    tester,
  ) async {
    final longName = List.filled(200, 'A').join();
    final longCategory = List.filled(80, 'C').join();
    final item = _itemWithCategory(
      Category(id: 1, name: longCategory, icon: 'nature'),
      name: longName,
    );

    await tester.pumpWidget(
      _wrap(ItineraryPlaceCard(item: item, onDelete: () {})),
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
