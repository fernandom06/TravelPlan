import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:frontend/presentation/widgets/import_url_dialog.dart';

Future<void> _pumpDialog(
  WidgetTester tester,
  Future<LatLng> Function(String url) onResolve,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () {
              showDialog<LatLng>(
                context: context,
                builder: (_) => ImportUrlDialog(onResolve: onResolve),
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows error on empty input without resolving', (tester) async {
    var resolved = false;
    await _pumpDialog(tester, (url) async {
      resolved = true;
      return const LatLng(41.6474339, -0.8861451);
    });

    await tester.tap(find.text('Importar'));
    await tester.pump();

    expect(find.text('Pega una URL'), findsOneWidget);
    expect(resolved, isFalse);
    expect(find.byType(ImportUrlDialog), findsOneWidget);
  });

  testWidgets('pops with the resolved LatLng on success', (tester) async {
    LatLng? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showDialog<LatLng>(
                  context: context,
                  builder: (_) => ImportUrlDialog(
                    onResolve: (url) async =>
                        const LatLng(41.6474339, -0.8861451),
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'https://maps.app.goo.gl/tpabGChzziYCfgjy5',
    );
    await tester.tap(find.text('Importar'));
    await tester.pumpAndSettle();

    expect(result, const LatLng(41.6474339, -0.8861451));
    expect(find.byType(ImportUrlDialog), findsNothing);
  });

  testWidgets('shows the error message and stays open on failure', (
    tester,
  ) async {
    await _pumpDialog(
      tester,
      (url) async => throw MapUrlResolveTestException('No se pudo resolver'),
    );

    await tester.enterText(
      find.byType(TextField),
      'https://maps.app.goo.gl/tpabGChzziYCfgjy5',
    );
    await tester.tap(find.text('Importar'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo resolver'), findsOneWidget);
    expect(find.byType(ImportUrlDialog), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('disables the Importar button while submitting', (tester) async {
    final completer = Completer<LatLng>();
    await _pumpDialog(tester, (url) => completer.future);

    await tester.enterText(
      find.byType(TextField),
      'https://maps.app.goo.gl/tpabGChzziYCfgjy5',
    );
    await tester.tap(find.text('Importar'));
    await tester.pump();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    completer.complete(const LatLng(41.6474339, -0.8861451));
    await tester.pumpAndSettle();
    expect(find.byType(ImportUrlDialog), findsNothing);
  });
}

class MapUrlResolveTestException implements Exception {
  const MapUrlResolveTestException(this.message);

  final String message;

  @override
  String toString() => message;
}
