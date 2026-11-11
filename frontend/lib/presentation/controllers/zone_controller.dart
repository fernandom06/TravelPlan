import 'package:flutter/foundation.dart' show ValueNotifier;

import '../../data/models/zone_point.dart';

class ZoneState {
  const ZoneState({required this.points});

  final List<ZonePoint> points;
}

class ZoneController extends ValueNotifier<ZoneState> {
  ZoneController() : super(const ZoneState(points: []));

  bool get canCreate => value.points.length >= 3;

  void addPoint(ZonePoint point) {
    value = ZoneState(points: [...value.points, point]);
  }

  void undoLast() {
    if (value.points.isEmpty) return;
    value = ZoneState(points: value.points.sublist(0, value.points.length - 1));
  }

  void clear() {
    value = const ZoneState(points: []);
  }
}
