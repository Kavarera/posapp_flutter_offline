class Customer {
  final int? id;
  final String name;
  final String? address;
  final String? phone;
  final String status;
  final double receivableBalance;

  Customer({
    this.id,
    required this.name,
    this.address,
    this.phone,
    this.status = 'Aktif',
    this.receivableBalance = 0,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int?,
      name: json['name'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'Aktif',
      receivableBalance: (json['receivable_balance'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'address': address,
      'phone': phone,
      'status': status,
      'receivable_balance': receivableBalance,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
