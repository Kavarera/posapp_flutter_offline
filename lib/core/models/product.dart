import 'package:posapp_w6zxit6s/core/models/product_unit.dart';

class Product {
  final int? id;
  final int? categoryId;
  final String name;
  final String barcode;
  final String baseUnit;
  final double buyPrice;
  final double buyPricePpn;
  final double sellPrice;
  final int minStock;
  final int stock;
  final String? createdAt;
  final String? updatedAt;
  
  // To hold joined/nested units if fetched
  final List<ProductUnit> units;

  Product({
    this.id,
    this.categoryId,
    required this.name,
    required this.barcode,
    required this.baseUnit,
    this.buyPrice = 0,
    this.buyPricePpn = 0,
    this.sellPrice = 0,
    this.minStock = 0,
    this.stock = 0,
    this.createdAt,
    this.updatedAt,
    this.units = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int?,
      categoryId: json['category_id'] as int?,
      name: json['name'] as String,
      barcode: json['barcode'] as String,
      baseUnit: json['base_unit'] as String,
      buyPrice: (json['buy_price'] as num?)?.toDouble() ?? 0,
      buyPricePpn: (json['buy_price_ppn'] as num?)?.toDouble() ?? 0,
      sellPrice: (json['sell_price'] as num?)?.toDouble() ?? 0,
      minStock: json['min_stock'] as int? ?? 0,
      stock: json['stock'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      // We manually populate 'units' later in the DB query logic, as SQLite doesn't natively return nested JSON
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'category_id': categoryId,
      'name': name,
      'barcode': barcode,
      'base_unit': baseUnit,
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
