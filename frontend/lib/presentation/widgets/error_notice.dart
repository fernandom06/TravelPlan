import 'dart:async';

import 'package:flutter/material.dart';

/// Persistent error snackbar with a retry action — the shared pattern that
/// itinerary, trips, map and settings use to report failures in human words.
///
/// It stays until the user retries or dismisses it: on an unreliable field
/// connection a 4-second snackbar would vanish unheard. A successful retry
/// dismisses it; a failed one re-shows the same notice.
void showErrorNotice(
  BuildContext context,
  String message,
  Future<void> Function() retry,
) {
  if (!context.mounted) return;
  // The messenger is captured before any await: retries may resolve long
  // after the widget that reported the error is gone.
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(_notice(message, retry, messenger));
}

SnackBar _notice(
  String message,
  Future<void> Function() retry,
  ScaffoldMessengerState messenger,
) {
  return SnackBar(
    content: Text(message),
    duration: const Duration(days: 1),
    showCloseIcon: true,
    action: SnackBarAction(
      label: 'Reintentar',
      onPressed: () => unawaited(_runRetry(messenger, message, retry)),
    ),
  );
}

Future<void> _runRetry(
  ScaffoldMessengerState messenger,
  String message,
  Future<void> Function() retry,
) async {
  try {
    await retry();
    messenger.hideCurrentSnackBar();
  } catch (_) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(_notice(message, retry, messenger));
  }
}
