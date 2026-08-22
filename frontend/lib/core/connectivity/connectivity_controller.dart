import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityController extends ValueNotifier<bool> {
  ConnectivityController(Stream<bool> onlineStream) : super(true) {
    _subscription = onlineStream.listen((isOnline) => value = isOnline);
  }

  factory ConnectivityController.defaultConnectivity() {
    final connectivity = Connectivity();
    final onlineStream = connectivity.onConnectivityChanged.map(
      (results) => results.any((r) => r != ConnectivityResult.none),
    );
    return ConnectivityController(onlineStream);
  }

  StreamSubscription<bool>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
