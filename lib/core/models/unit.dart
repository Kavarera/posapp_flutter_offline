class Unit {
  final int? id;
  final String name;
  final bool hasDerived;
  final int? derivedUnitId;
  final int? multiplierToDerived;

  // Joined properties for UI/Logic
  final String? derivedUnitName;

  Unit({
    this.id,
    required this.name,
    this.hasDerived = false,
    this.derivedUnitId,
    this.multiplierToDerived,
    this.derivedUnitName,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] as int?,
      name: json['name'] as String,
      hasDerived: (json['has_derived'] as int? ?? 0) == 1,
      derivedUnitId: json['derived_unit_id'] as int?,
      multiplierToDerived: json['multiplier_to_derived'] as int?,
      derivedUnitName: json['derived_unit_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'has_derived': hasDerived ? 1 : 0,
      'derived_unit_id': derivedUnitId,
      'multiplier_to_derived': multiplierToDerived,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
