import 'package:connectivity_plus/connectivity_plus.dart';

Stream<bool> createConnectivityStream(Connectivity connectivity) {
  return connectivity.onConnectivityChanged.map(
    (results) => results.any((r) => r != ConnectivityResult.none),
  );
}
