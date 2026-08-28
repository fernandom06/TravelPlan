class ZonePoint {
  const ZonePoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory ZonePoint.fromJson(Map<String, dynamic> json) {
    return ZonePoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  bool operator ==(Object other) =>
      other is ZonePoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}