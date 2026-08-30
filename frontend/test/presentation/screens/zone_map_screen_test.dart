import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/trip_draft.dart';
import 'package:frontend/presentation/screens/zone_map_screen.dart';

final _draft = TripDraft(
  name: 'Viaje a Galicia',
  startDate: DateTime(2026, 6, 1),
  endDate: DateTime(2026, 6, 10),
  description: 'Costas',
);

class _Host extends StatelessWidget {
  const _Host({required this.onResult});

  final void Function(TripDraft?) onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push<TripDraft>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ZoneMapScreen(draft: _draft),
                  ),
                );
                onResult(result);
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
  }
}

Future<TripDraft?> _openScreen(WidgetTester tester) async {
  TripDraft? result;
  await tester.pumpWidget(_Host(onResult: (r) => result = r));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return result;
}

Future<void> _drawPoint(WidgetTester tester, Offset offset) async {
  await tester.tapAt(tester.getCenter(find.byType(FlutterMap)) + offset);
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> _drawThreePoints(WidgetTester tester) async {
  await _drawPoint(tester, Offset.zero);
  await _drawPoint(tester, const Offset(40, 0));
  await _drawPoint(tester, const Offset(0, 40));
}

Future<void> _tapInDialog(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(AlertDialog), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the Área de Viaje pill over the map', (tester) async {
    await _openScreen(tester);

    expect(find.text('Área de Viaje'), findsOneWidget);
  });

  testWidgets('Crear viaje is disabled with fewer than 3 points', (
    tester,
  ) async {
    await _openScreen(tester);
    await _drawPoint(tester, Offset.zero);

    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Crear viaje'),
    );
    expect(createButton.onPressed, isNull);
  });

  testWidgets('Crear viaje is enabled with 3 points and pops draft with zone', (
    tester,
  ) async {
    TripDraft? result;
    await tester.pumpWidget(_Host(onResult: (r) => result = r));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await _drawThreePoints(tester);

    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Crear viaje'),
    );
    expect(createButton.onPressed, isNotNull);

    await tester.tap(find.text('Crear viaje'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.zone, hasLength(3));
    expect(result!.name, 'Viaje a Galicia');
    expect(result!.description, 'Costas');
    expect(result!.startDate, DateTime(2026, 6, 1));
    expect(result!.endDate, DateTime(2026, 6, 10));
  });

  testWidgets('Omitir first dialog Cancelar does nothing', (tester) async {
    await _openScreen(tester);
    await _drawThreePoints(tester);

    await tester.tap(find.text('Omitir'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await _tapInDialog(tester, 'Cancelar');

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(ZoneMapScreen), findsOneWidget);
  });

  testWidgets('confirming first dialog opens the second one', (tester) async {
    await _openScreen(tester);
    await _drawThreePoints(tester);

    await tester.tap(find.text('Omitir'));
    await tester.pumpAndSettle();
    await _tapInDialog(tester, 'Continuar');

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('puntos dibujados'), findsOneWidget);
  });

  testWidgets('Cancelar on the second dialog does nothing', (tester) async {
    await _openScreen(tester);
    await _drawThreePoints(tester);

    await tester.tap(find.text('Omitir'));
    await tester.pumpAndSettle();
    await _tapInDialog(tester, 'Continuar');
    await _tapInDialog(tester, 'Cancelar');

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(ZoneMapScreen), findsOneWidget);
  });

  testWidgets('confirming second dialog pops draft without zone', (
    tester,
  ) async {
    TripDraft? result;
    await tester.pumpWidget(_Host(onResult: (r) => result = r));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await _drawThreePoints(tester);
    await tester.tap(find.text('Omitir'));
    await tester.pumpAndSettle();
    await _tapInDialog(tester, 'Continuar');
    await _tapInDialog(tester, 'Omitir');

    expect(result, isNotNull);
    expect(result!.zone, isNull);
    expect(result!.name, 'Viaje a Galicia');
    expect(find.byType(ZoneMapScreen), findsNothing);
  });

  testWidgets('second dialog uses neutral wording with 0 points', (
    tester,
  ) async {
    await _openScreen(tester);

    await tester.tap(find.text('Omitir'));
    await tester.pumpAndSettle();
    await _tapInDialog(tester, 'Continuar');

    expect(find.textContaining('polígono dibujado'), findsOneWidget);
  });

  testWidgets('system back pops with null', (tester) async {
    TripDraft? result;
    await tester.pumpWidget(_Host(onResult: (r) => result = r));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.byType(ZoneMapScreen), findsNothing);
  });

  testWidgets('BackButton after drawing points pops with null and discards', (
    tester,
  ) async {
    TripDraft? result;
    await tester.pumpWidget(_Host(onResult: (r) => result = r));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await _drawThreePoints(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.byType(ZoneMapScreen), findsNothing);
  });
}