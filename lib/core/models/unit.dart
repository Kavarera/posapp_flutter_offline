class Unit {
  final int? id;
  final String name;

  Unit({this.id, required this.name});

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(id: json['id'] as int?, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'name': name};
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
