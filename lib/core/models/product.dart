class Product {
  final int? id;
  final int? categoryId;
  final int? unitId;
  final String name;
  final String barcode;
  final double buyPrice;
  final double buyPricePpn;
  final double sellPrice;
  final int minStock;
  final int stock;
  final String? createdAt;
  final String? updatedAt;
  
  // Joined properties
  final String? categoryName;
  final String? unitName;
  List<int> supplierIds;
  final String? supplierNames; // For easy UI display

  Product({
    this.id,
    this.categoryId,
    this.unitId,
    required this.name,
    required this.barcode,
    this.buyPrice = 0,
    this.buyPricePpn = 0,
    this.sellPrice = 0,
    this.minStock = 0,
    this.stock = 0,
    this.createdAt,
    this.updatedAt,
    this.categoryName,
    this.unitName,
    this.supplierIds = const [],
    this.supplierNames,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int?,
      categoryId: json['category_id'] as int?,
      unitId: json['unit_id'] as int?,
      name: json['name'] as String,
      barcode: json['barcode'] as String,
      buyPrice: (json['buy_price'] as num?)?.toDouble() ?? 0,
      buyPricePpn: (json['buy_price_ppn'] as num?)?.toDouble() ?? 0,
      sellPrice: (json['sell_price'] as num?)?.toDouble() ?? 0,
      minStock: json['min_stock'] as int? ?? 0,
      stock: json['stock'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      categoryName: json['category_name'] as String?,
      unitName: json['unit_name'] as String?,
      supplierNames: json['supplier_names'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'category_id': categoryId,
      'unit_id': unitId,
      'name': name,
      'barcode': barcode,
      'buy_price': buyPrice,
      'buy_price_ppn': buyPricePpn,
      'sell_price': sellPrice,
      'min_stock': minStock,
      'stock': stock,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
