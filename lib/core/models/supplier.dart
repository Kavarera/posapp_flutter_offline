class Supplier {
  final int? id;
  final String name;
  final String? contact;
  final String? npwp;
  final String? bankAccount;
  final String? address;

  Supplier({
    this.id,
    required this.name,
    this.contact,
    this.npwp,
    this.bankAccount,
    this.address,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as int?,
      name: json['name'] as String,
      contact: json['contact'] as String?,
      npwp: json['npwp'] as String?,
      bankAccount: json['bank_account'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'contact': contact,
      'npwp': npwp,
      'bank_account': bankAccount,
      'address': address,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
