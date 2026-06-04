class Category {
  final int? id;
  final String name;
  final int productCount;

  Category({
    this.id,
    required this.name,
    this.productCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int?,
      name: json['name'] as String,
      productCount: json['product_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
