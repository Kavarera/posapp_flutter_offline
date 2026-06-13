import 'package:posapp_w6zxit6s/core/models/unit.dart';

class ProductUnit {
  final int? id;
  final int productId;
  final int unitId;
  final bool isBase;
  final int? parentUnitId;
  final int? multiplierToParent;
  final int multiplierToBase;

  // Joined properties for UI
  final Unit? unit;
  final Unit? parentUnit;

  ProductUnit({
    this.id,
    required this.productId,
    required this.unitId,
    this.isBase = false,
    this.parentUnitId,
    this.multiplierToParent,
    required this.multiplierToBase,
    this.unit,
    this.parentUnit,
  });

  factory ProductUnit.fromJson(Map<String, dynamic> json) {
    return ProductUnit(
      id: json['id'] as int?,
      productId: json['product_id'] as int,
      unitId: json['unit_id'] as int,
      isBase: (json['is_base'] as int? ?? 0) == 1,
      parentUnitId: json['parent_unit_id'] as int?,
      multiplierToParent: json['multiplier_to_parent'] as int?,
      multiplierToBase: json['multiplier_to_base'] as int,
      unit: json['unit_name'] != null
          ? Unit(id: json['unit_id'] as int, name: json['unit_name'] as String)
          : null,
      parentUnit: json['parent_unit_name'] != null
          ? Unit(
              id: json['parent_unit_id'] as int,
              name: json['parent_unit_name'] as String,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'product_id': productId,
      'unit_id': unitId,
      'is_base': isBase ? 1 : 0,
      'parent_unit_id': parentUnitId,
      'multiplier_to_parent': multiplierToParent,
      'multiplier_to_base': multiplierToBase,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
