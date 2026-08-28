import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/category_icon_catalog.dart';
import 'package:frontend/presentation/widgets/category_icon_picker.dart';

/// Pumps the app, opens the picker and returns a mutable list the button
/// callback appends the resolved [IconPickerResult] to.
Future<List<IconPickerResult?>> _openPicker(
  WidgetTester tester, {
  String? current,
}) async {
  final result = <IconPickerResult?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result.add(await pickCategoryIcon(context, current: current));
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
  return result;
}

void main() {
  testWidgets('tapping an icon returns IconPickerPicked with its id', (
    tester,
  ) async {
    final result = await _openPicker(tester);

    await tester.tap(find.byIcon(Icons.beach_access));
    await tester.pumpAndSettle();

    expect(result, hasLength(1));
    expect(result.single, isA<IconPickerPicked>());
    expect((result.single as IconPickerPicked).id, 'beach');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('tapping the "Sin icono" tile returns IconPickerCleared', (
    tester,
  ) async {
    final result = await _openPicker(tester);

    await tester.tap(find.byTooltip('Sin icono'));
    await tester.pumpAndSettle();

    expect(result, hasLength(1));
    expect(result.single, isA<IconPickerCleared>());
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('dismissing by tapping outside returns IconPickerCancelled', (
    tester,
  ) async {
    final result = await _openPicker(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(result, hasLength(1));
    expect(result.single, isA<IconPickerCancelled>());
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('dismissing with Escape returns IconPickerCancelled', (
    tester,
  ) async {
    final result = await _openPicker(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(result, hasLength(1));
    expect(result.single, isA<IconPickerCancelled>());
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('highlights the current icon', (tester) async {
    await _openPicker(tester, current: 'beach');

    final context = tester.element(find.byType(AlertDialog));
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;

    final selectedContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.byIcon(Icons.beach_access),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = selectedContainer.decoration! as BoxDecoration;
    expect(decoration.color, primaryContainer);
  });

  testWidgets('does not highlight a different icon', (tester) async {
    await _openPicker(tester, current: 'beach');

    final context = tester.element(find.byType(AlertDialog));
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;

    final unselectedContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.byIcon(Icons.park),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = unselectedContainer.decoration! as BoxDecoration;
    expect(decoration.color, isNot(primaryContainer));
  });

  testWidgets('highlights the "Sin icono" tile when current is null', (
    tester,
  ) async {
    await _openPicker(tester);

    final context = tester.element(find.byType(AlertDialog));
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;

    final clearContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.byIcon(categoryPlaceholderIcon),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = clearContainer.decoration! as BoxDecoration;
    expect(decoration.color, primaryContainer);
  });
}
