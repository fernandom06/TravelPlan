class PlaceUpdate {
  const PlaceUpdate({
    required this.name,
    required this.categoryId,
    this.description,
  });

  final String name;
  final int categoryId;
  final String? description;

  Map<String, dynamic> toJson() => {
    'name': name,
    'category_id': categoryId,
    'description': description,
  };
}
