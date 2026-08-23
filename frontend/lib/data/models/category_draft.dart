class CategoryDraft {
  const CategoryDraft({required this.name});

  final String name;

  Map<String, dynamic> toJson() => {'name': name};
}
