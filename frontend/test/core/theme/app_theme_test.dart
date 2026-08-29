import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('bundled fonts', () {
    for (final entry in [
      ('Fraunces-600.ttf', 'Fraunces'),
      ('Fraunces-700.ttf', 'Fraunces'),
      ('Lora-400.ttf', 'Lora'),
    ]) {
      test('${entry.$2} asset ${entry.$1} is declared and loadable', () async {
        final data = await rootBundle.load('assets/fonts/${entry.$1}');
        expect(data.lengthInBytes, greaterThan(0));
      });
    }
  });
}