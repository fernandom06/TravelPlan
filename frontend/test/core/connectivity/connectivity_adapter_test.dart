import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/connectivity/connectivity_adapter.dart';

class _FakeConnectivityPlatform extends ConnectivityPlatform {
  _FakeConnectivityPlatform(this._controller);

  final StreamController<List<ConnectivityResult>> _controller;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [
    ConnectivityResult.wifi,
  ];
}

void main() {
  test('maps connectivity results to online boolean', () async {
    final original = ConnectivityPlatform.instance;
    addTearDown(() => ConnectivityPlatform.instance = original);

    final controller = StreamController<List<ConnectivityResult>>();
    ConnectivityPlatform.instance = _FakeConnectivityPlatform(controller);

    final stream = createConnectivityStream(Connectivity());
    final emitted = <bool>[];
    final subscription = stream.listen(emitted.add);
    addTearDown(subscription.cancel);
    addTearDown(controller.close);

    controller.add([ConnectivityResult.none]);
    await pumpEventQueue();
    expect(emitted, [false]);

    controller.add([ConnectivityResult.wifi]);
    await pumpEventQueue();
    expect(emitted, [false, true]);

    controller.add([ConnectivityResult.mobile, ConnectivityResult.vpn]);
    await pumpEventQueue();
    expect(emitted, [false, true, true]);
  });
}
