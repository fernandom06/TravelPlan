import 'package:latlong2/latlong.dart';

import 'category.dart';

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.category,
  });

  final int id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final Category category;

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'category': category.toJson(),
  };

  LatLng get latLng => LatLng(latitude, longitude);

  @override
  bool operator ==(Object other) => other is Place && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
