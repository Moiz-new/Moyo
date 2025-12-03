class Category {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final String icon;

  Category({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      icon: json['icon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'icon': icon,
    };
  }
}

class CategoryResponse {
  final List<Category> categories;

  CategoryResponse({required this.categories});

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    var categoriesList = json['categories'] as List<dynamic>?;
    List<Category> categories = categoriesList != null
        ? categoriesList.map((cat) => Category.fromJson(cat)).toList()
        : [];

    return CategoryResponse(categories: categories);
  }
}