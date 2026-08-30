/// Lifecycle state of a trip derived purely from its dates.
enum TripStatus {
  upcoming,
  ongoing,
  past;

  /// Derives the status using date-only comparison (time-of-day ignored):
  /// `today < start` → [upcoming]; `start <= today <= end` → [ongoing];
  /// `today > end` → [past].
  static TripStatus fromDates(DateTime start, DateTime end, DateTime today) {
    final startDay = _dateOnly(start);
    final endDay = _dateOnly(end);
    final todayDay = _dateOnly(today);
    if (todayDay.isBefore(startDay)) return TripStatus.upcoming;
    if (todayDay.isAfter(endDay)) return TripStatus.past;
    return TripStatus.ongoing;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
