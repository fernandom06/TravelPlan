import 'zone_point.dart';

class TripDraft {
  const TripDraft({
    required this.name,
    required this.startDate,
    required this.endDate,
    this.description,
    this.imageUrl,
    this.zone,
  });

  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final String? imageUrl;
  final List<ZonePoint>? zone;

  TripDraft copyWith({List<ZonePoint>? zone}) => TripDraft(
    name: name,
    startDate: startDate,
    endDate: endDate,
    description: description,
    imageUrl: imageUrl,
    zone: zone ?? this.zone,
  );

  Map<String, dynamic> toJson() {
    final points = zone;
    return {
      'name': name,
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
      'description': description,
      'image_url': imageUrl,
      'zone': points == null ? null : {'points': [for (final p in points) p.toJson()]},
    };
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
