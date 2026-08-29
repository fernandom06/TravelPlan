import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/presentation/widgets/place_form_container.dart';

class _FormProbe extends StatefulWidget {
  const _FormProbe();

  @override
  State<_FormProbe> createState() => _FormProbeState();
}

class _FormProbeState extends State<_FormProbe> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'Nombre'),
    );
  }
}

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Material(
        child: Stack(
          children: const [
            PlaceFormContainer(child: _FormProbe()),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('narrow layout shows a bottom sheet with a drag handle', (
    tester,
  ) async {
    await _pump(tester, const Size(500, 900));

    expect(find.byKey(const Key('place-form-sheet')), findsOneWidget);
    expect(find.byKey(const Key('place-form-drag-handle')), findsOneWidget);
    expect(find.byKey(const Key('place-form-panel')), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('wide layout shows a right-anchored panel', (tester) async {
    await _pump(tester, const Size(1200, 800));

    expect(find.byKey(const Key('place-form-panel')), findsOneWidget);
    expect(find.byKey(const Key('place-form-sheet')), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('text is preserved when crossing the breakpoint', (tester) async {
    await _pump(tester, const Size(500, 900));
    await tester.enterText(find.byType(TextField), 'Mirador');

    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Mirador'), findsOneWidget);
  });

  testWidgets('text is preserved when crossing back to mobile', (tester) async {
    await _pump(tester, const Size(1200, 800));
    await tester.enterText(find.byType(TextField), 'Cascada');

    tester.view.physicalSize = const Size(500, 900);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Cascada'), findsOneWidget);
  });

  testWidgets('keyboard insets lift the mobile sheet', (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tester.view.viewInsets = FakeViewPadding(bottom: 300);
    addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Material(
          child: Stack(
            children: const [
              PlaceFormContainer(child: _FormProbe()),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final sheet = tester.widget<Container>(
      find.byKey(const Key('place-form-sheet')),
    );
    expect(sheet.margin, const EdgeInsets.only(bottom: 300));
  });
}