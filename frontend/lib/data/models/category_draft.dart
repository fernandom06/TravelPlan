class CategoryDraft {
  const CategoryDraft({required this.name, this.icon});

  final String name;
  final String? icon;

  Map<String, dynamic> toJson() => {'name': name, 'icon': icon};
}
