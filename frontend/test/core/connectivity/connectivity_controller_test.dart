import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/connectivity/connectivity_controller.dart';

void main() {
  test('initial value is true before any emission', () {
    final controller = ConnectivityController(const Stream<bool>.empty());

    expect(controller.value, isTrue);

    controller.dispose();
  });

  test('value tracks stream emissions', () async {
    final streamController = StreamController<bool>();
    final controller = ConnectivityController(streamController.stream);

    expect(controller.value, isTrue);

    streamController.add(false);
    await pumpEventQueue();
    expect(controller.value, isFalse);

    streamController.add(true);
    await pumpEventQueue();
    expect(controller.value, isTrue);

    controller.dispose();
    await streamController.close();
  });
}
