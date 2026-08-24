class Category {
  const Category({required this.id, required this.name, this.icon});

  final int id;
  final String name;
  final String? icon;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'icon': icon};

  @override
  bool operator ==(Object other) => other is Category && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
