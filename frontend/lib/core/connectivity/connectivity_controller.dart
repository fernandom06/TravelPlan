import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'connectivity_adapter.dart';

class ConnectivityController extends ValueNotifier<bool> {
  ConnectivityController(Stream<bool> onlineStream) : super(true) {
    _subscription = onlineStream.listen((isOnline) => value = isOnline);
  }

  factory ConnectivityController.defaultConnectivity() {
    return ConnectivityController(createConnectivityStream(Connectivity()));
  }

  StreamSubscription<bool>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
