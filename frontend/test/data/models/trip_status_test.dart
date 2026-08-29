import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/models/trip_status.dart';

void main() {
  group('TripStatus.fromDates', () {
    final start = DateTime(2026, 7, 15);
    final end = DateTime(2026, 7, 22);

    test('before the start date is upcoming', () {
      expect(
        TripStatus.fromDates(start, end, DateTime(2026, 7, 14)),
        TripStatus.upcoming,
      );
    });

    test('the day before the start is upcoming', () {
      expect(
        TripStatus.fromDates(start, end, DateTime(2026, 7, 14)),
        TripStatus.upcoming,
      );
    });

    test('a trip starting today is ongoing (start included)', () {
      expect(
        TripStatus.fromDates(start, end, DateTime(2026, 7, 15)),
        TripStatus.ongoing,
      );
    });

    test('mid trip is ongoing', () {
      expect(
        TripStatus.fromDates(start, end, DateTime(2026, 7, 19)),
        TripStatus.ongoing,
      );
    });

    test('a trip ending today is ongoing (end included)', () {
      expect(
        TripStatus.fromDates(start, end, DateTime(2026, 7, 22)),
        TripStatus.ongoing,
      );
    });

    test('the day after the end is past', () {
      expect(
        TripStatus.fromDates(start, end, DateTime(2026, 7, 23)),
        TripStatus.past,
      );
    });

    test('much later than the end is past', () {
      expect(
        TripStatus.fromDates(start, end, DateTime(2026, 8, 1)),
        TripStatus.past,
      );
    });

    test('comparison ignores the time-of-day component', () {
      expect(
        TripStatus.fromDates(
          start,
          end,
          DateTime(2026, 7, 15, 23, 59),
        ),
        TripStatus.ongoing,
      );
    });
  });
}