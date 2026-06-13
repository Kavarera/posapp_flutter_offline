import 'dart:convert';

class PurchaseInvoice {
  final int? id;
  final String invoiceNumber;
  final String? supplierInvoiceNumber;
  final int supplierId;
  final String invoiceDate;
  final String? dueDate;
  final String paymentMethod;
  final double totalNominal;
  final List<String> documentPaths;
  final String createdAt;
  
  // Relations
  final List<PurchaseInvoiceDetail> details;

  PurchaseInvoice({
    this.id,
    required this.invoiceNumber,
    this.supplierInvoiceNumber,
    required this.supplierId,
    required this.invoiceDate,
    this.dueDate,
    required this.paymentMethod,
    this.totalNominal = 0,
    this.documentPaths = const [],
    required this.createdAt,
    this.details = const [],
  });

  factory PurchaseInvoice.fromJson(Map<String, dynamic> json) {
    List<String> docs = [];
    if (json['document_paths'] != null && json['document_paths'].toString().isNotEmpty) {
      try {
        docs = List<String>.from(jsonDecode(json['document_paths']));
      } catch (e) {
        docs = [];
      }
    }

    return PurchaseInvoice(
      id: json['id'] as int?,
      invoiceNumber: json['invoice_number'] as String,
      supplierInvoiceNumber: json['supplier_invoice_number'] as String?,
      supplierId: json['supplier_id'] as int,
      invoiceDate: json['invoice_date'] as String,
      dueDate: json['due_date'] as String?,
      paymentMethod: json['payment_method'] as String,
      totalNominal: (json['total_nominal'] as num?)?.toDouble() ?? 0,
      documentPaths: docs,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'invoice_number': invoiceNumber,
      'supplier_invoice_number': supplierInvoiceNumber,
      'supplier_id': supplierId,
      'invoice_date': invoiceDate,
      'due_date': dueDate,
      'payment_method': paymentMethod,
      'total_nominal': totalNominal,
      'document_paths': jsonEncode(documentPaths),
      'created_at': createdAt,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}

class PurchaseInvoiceDetail {
  final int? id;
  final int invoiceId;
  final int productId;
  final int unitId;
  final int qty;
  final double unitPrice;
  final double totalPrice;
  final double baseUnitPrice;

  PurchaseInvoiceDetail({
    this.id,
    required this.invoiceId,
    required this.productId,
    required this.unitId,
    required this.qty,
    required this.unitPrice,
    required this.totalPrice,
    required this.baseUnitPrice,
  });

  factory PurchaseInvoiceDetail.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoiceDetail(
      id: json['id'] as int?,
      invoiceId: json['invoice_id'] as int,
      productId: json['product_id'] as int,
      unitId: json['unit_id'] as int,
      qty: json['qty'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      baseUnitPrice: (json['base_unit_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'invoice_id': invoiceId,
      'product_id': productId,
      'unit_id': unitId,
      'qty': qty,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'base_unit_price': baseUnitPrice,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
