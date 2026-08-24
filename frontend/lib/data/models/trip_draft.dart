class TripDraft {
  const TripDraft({
    required this.name,
    required this.startDate,
    required this.endDate,
    this.description,
    this.imageUrl,
  });

  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final String? imageUrl;

  Map<String, dynamic> toJson() => {
    'name': name,
    'start_date': _formatDate(startDate),
    'end_date': _formatDate(endDate),
    'description': description,
    'image_url': imageUrl,
  };

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
