class ProductUnit {
  final int? id;
  final int productId;
  final String unitName;
  final int multiplier;

  ProductUnit({
    this.id,
    required this.productId,
    required this.unitName,
    required this.multiplier,
  });

  factory ProductUnit.fromJson(Map<String, dynamic> json) {
    return ProductUnit(
      id: json['id'] as int?,
      productId: json['product_id'] as int,
      unitName: json['unit_name'] as String,
      multiplier: json['multiplier'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'product_id': productId,
      'unit_name': unitName,
      'multiplier': multiplier,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
