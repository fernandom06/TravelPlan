import 'dart:async';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/connectivity/connectivity_controller.dart';

class _FakeConnectivityPlatform extends ConnectivityPlatform {
  _FakeConnectivityPlatform(this.checkResult, this._controller);

  final List<ConnectivityResult> checkResult;
  final StreamController<List<ConnectivityResult>> _controller;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => checkResult;
}

void main() {
  test('value tracks stream emissions', () async {
    final streamController = StreamController<bool>();
    final controller = ConnectivityController(streamController.stream);

    expect(controller.value, isFalse);

    streamController.add(false);
    await pumpEventQueue();
    expect(controller.value, isFalse);

    streamController.add(true);
    await pumpEventQueue();
    expect(controller.value, isTrue);

    controller.dispose();
    await streamController.close();
  });

  test('starts offline when the device is offline', () async {
    final original = ConnectivityPlatform.instance;
    addTearDown(() => ConnectivityPlatform.instance = original);

    final streamController = StreamController<List<ConnectivityResult>>();
    ConnectivityPlatform.instance = _FakeConnectivityPlatform([
      ConnectivityResult.none,
    ], streamController);

    final controller = ConnectivityController.live();
    addTearDown(controller.dispose);
    addTearDown(streamController.close);

    await pumpEventQueue();

    expect(controller.value, isFalse);
  });

  test(
    'seeds initial state from checkConnectivity and follows change events',
    () async {
      final original = ConnectivityPlatform.instance;
      addTearDown(() => ConnectivityPlatform.instance = original);

      final streamController = StreamController<List<ConnectivityResult>>();
      ConnectivityPlatform.instance = _FakeConnectivityPlatform([
        ConnectivityResult.wifi,
      ], streamController);

      final controller = ConnectivityController.live();
      addTearDown(controller.dispose);
      addTearDown(streamController.close);

      await pumpEventQueue();
      expect(controller.value, isTrue);

      streamController.add([ConnectivityResult.none]);
      await pumpEventQueue();
      expect(controller.value, isFalse);

      streamController.add([ConnectivityResult.wifi]);
      await pumpEventQueue();
      expect(controller.value, isTrue);

      streamController.add([ConnectivityResult.mobile, ConnectivityResult.vpn]);
      await pumpEventQueue();
      expect(controller.value, isTrue);
    },
  );
}
