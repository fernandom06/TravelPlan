import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/zone_point.dart';

void main() {
  group('ZonePoint', () {
    test('toJson uses latitude and longitude keys', () {
      const point = ZonePoint(latitude: 42.5, longitude: -3.5);

      expect(point.toJson(), {'latitude': 42.5, 'longitude': -3.5});
    });

    test('fromJson roundtrips toJson', () {
      const point = ZonePoint(latitude: 42.5, longitude: -3.5);

      expect(ZonePoint.fromJson(point.toJson()), point);
    });

    test('fromJson parses integer-valued doubles', () {
      final point = ZonePoint.fromJson({'latitude': 42, 'longitude': -3});

      expect(point.latitude, 42.0);
      expect(point.longitude, -3.0);
    });

    test('equality compares both coordinates', () {
      const a = ZonePoint(latitude: 42.5, longitude: -3.5);
      const same = ZonePoint(latitude: 42.5, longitude: -3.5);
      const different = ZonePoint(latitude: 42.6, longitude: -3.5);

      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a, isNot(different));
    });
  });
}
