import 'itinerary_slot.dart';
import 'place.dart';

class ItineraryItem {
  const ItineraryItem({
    required this.id,
    required this.dayDate,
    required this.slot,
    required this.position,
    required this.place,
  });

  final int id;
  final DateTime? dayDate;
  final ItinerarySlot? slot;
  final int position;
  final Place place;

  bool get isUnassigned => dayDate == null && slot == null;

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    final dayDate = json['day_date'] as String?;
    return ItineraryItem(
      id: json['id'] as int,
      dayDate: dayDate == null ? null : DateTime.parse(dayDate),
      slot: ItinerarySlot.fromWireValue(json['slot'] as String?),
      position: json['position'] as int,
      place: Place.fromJson(json['place'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'day_date': dayDate == null ? null : _formatDate(dayDate!),
    'slot': slot?.wireValue,
    'position': position,
    'place': place.toJson(),
  };

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) => other is ItineraryItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}