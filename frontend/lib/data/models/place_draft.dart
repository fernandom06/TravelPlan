class PlaceDraft {
  const PlaceDraft({
    required this.name,
    required this.categoryId,
    this.description,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final int categoryId;
  final String? description;
  final double latitude;
  final double longitude;
}