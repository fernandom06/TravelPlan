import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/presentation/widgets/entity_actions.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 220,
          height: 120,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('touch platforms open the menu on long-press', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var edited = false;
    var deleted = false;

    await tester.pumpWidget(
      _wrap(
        EntityActions(
          child: const Center(child: Text('card')),
          onEdit: () => edited = true,
          onDelete: () => deleted = true,
        ),
      ),
    );

    expect(find.byIcon(Icons.more_vert), findsNothing);

    await tester.longPress(find.text('card'));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Borrar'), findsOneWidget);

    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
    expect(edited, isFalse);

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('desktop platforms show an overflow button on hover', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    var edited = false;
    var deleted = false;

    await tester.pumpWidget(
      _wrap(
        EntityActions(
          child: const Center(child: Text('card')),
          onEdit: () => edited = true,
          onDelete: () => deleted = true,
        ),
      ),
    );

    expect(find.byIcon(Icons.more_vert), findsNothing);

    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: const Offset(10, 10));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('card')));
    await tester.pump();

    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    await gesture.removePointer();
    await tester.pump();

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('desktop overflow button opens the menu and fires onEdit', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    var edited = false;
    var deleted = false;

    await tester.pumpWidget(
      _wrap(
        EntityActions(
          child: const Center(child: Text('card')),
          onEdit: () => edited = true,
          onDelete: () => deleted = true,
        ),
      ),
    );

    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: const Offset(10, 10));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('card')));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Borrar'), findsOneWidget);

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(edited, isTrue);

    await gesture.removePointer();
    await tester.pump();

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('shows only the actions provided', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    var deleted = false;

    await tester.pumpWidget(
      _wrap(
        EntityActions(
          child: const Center(child: Text('card')),
          onDelete: () => deleted = true,
        ),
      ),
    );

    await tester.longPress(find.text('card'));
    await tester.pumpAndSettle();

    expect(find.text('Borrar'), findsOneWidget);
    expect(find.text('Editar'), findsNothing);

    debugDefaultTargetPlatformOverride = null;
  });
}