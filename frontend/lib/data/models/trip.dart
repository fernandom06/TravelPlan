class Trip {
  const Trip({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.imageUrl,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String? imageUrl;
  final String createdAt;

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'start_date': _formatDate(startDate),
    'end_date': _formatDate(endDate),
    'image_url': imageUrl,
    'created_at': createdAt,
  };

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  bool get imageIsRelative =>
      imageUrl == null || !imageUrl!.startsWith('http');

  String displayImageUrl(String baseUrl) {
    final url = imageUrl;
    if (url == null || url.startsWith('http')) return url ?? '';
    return '$baseUrl$url';
  }

  @override
  bool operator ==(Object other) => other is Trip && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
