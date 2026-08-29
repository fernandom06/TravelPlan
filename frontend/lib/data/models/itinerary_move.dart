import 'itinerary_slot.dart';

class ItineraryMove {
  const ItineraryMove({
    required this.dayDate,
    required this.slot,
    required this.position,
  });

  final DateTime? dayDate;
  final ItinerarySlot? slot;
  final int position;

  Map<String, dynamic> toJson() => {
    'day_date': dayDate == null ? null : _formatDate(dayDate!),
    'slot': slot?.wireValue,
    'position': position,
  };

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
