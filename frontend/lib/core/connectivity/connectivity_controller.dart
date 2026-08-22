import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityController extends ValueNotifier<bool> {
  ConnectivityController(Stream<bool> onlineStream) : super(false) {
    _subscription = onlineStream.listen((isOnline) => value = isOnline);
  }

  factory ConnectivityController.live() {
    return ConnectivityController(_liveStream(Connectivity()));
  }

  static Stream<bool> _liveStream(Connectivity connectivity) async* {
    final results = await connectivity.checkConnectivity();
    yield results.any((r) => r != ConnectivityResult.none);
    yield* connectivity.onConnectivityChanged.map(
      (results) => results.any((r) => r != ConnectivityResult.none),
    );
  }

  StreamSubscription<bool>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
