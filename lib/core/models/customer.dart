class Customer {
  final int? id;
  final String name;
  final String? address;
  final String? phone;
  final String status;
  final double receivableBalance;
  final String? createdAt;

  Customer({
    this.id,
    required this.name,
    this.address,
    this.phone,
    this.status = 'Aktif',
    this.receivableBalance = 0,
    this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int?,
      name: json['name'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'Aktif',
      receivableBalance: (json['receivable_balance'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'address': address,
      'phone': phone,
      'status': status,
      'receivable_balance': receivableBalance,
      'created_at': createdAt,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
