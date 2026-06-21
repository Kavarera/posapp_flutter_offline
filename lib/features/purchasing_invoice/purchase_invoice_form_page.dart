import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/features/purchasing_invoice/purchase_invoice_controller.dart';
import 'package:posapp_w6zxit6s/core/models/supplier.dart';
import 'package:posapp_w6zxit6s/core/models/product.dart';
import 'package:posapp_w6zxit6s/core/models/purchase_invoice.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class PurchaseInvoiceFormPage extends StatefulWidget {
  final PurchaseInvoice? invoiceToComplete;

  const PurchaseInvoiceFormPage({super.key, this.invoiceToComplete});

  @override
  State<PurchaseInvoiceFormPage> createState() =>
      _PurchaseInvoiceFormPageState();
}

class _PurchaseInvoiceFormPageState extends State<PurchaseInvoiceFormPage> {
  final PurchaseInvoiceController _controller =
      Get.find<PurchaseInvoiceController>();

  final _supplierInvController = TextEditingController();
  final _totalNominalController = TextEditingController();
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool get _isCompleteMode => widget.invoiceToComplete != null;

  String _generatedInvoiceId = '';
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  String _paymentMethod = 'Tunai';

  List<Supplier> _suppliers = [];
  Supplier? _selectedSupplier;

  List<Product> _supplierProducts = [];
  List<String> _tempFilePaths = [];

  // Temporary list of details
  final List<_InvoiceDetailRow> _details = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _suppliers = await _controller.fetchSuppliers();

    if (_isCompleteMode) {
      _generatedInvoiceId = widget.invoiceToComplete!.invoiceNumber;
      _supplierInvController.text =
          widget.invoiceToComplete!.supplierInvoiceNumber ?? '';
      _totalNominalController.text = widget.invoiceToComplete!.totalNominal
          .toInt()
          .toString();
      _paymentMethod = widget.invoiceToComplete!.paymentMethod;
      try {
        _invoiceDate = DateTime.parse(widget.invoiceToComplete!.invoiceDate);
      } catch (_) {}
      try {
        if (widget.invoiceToComplete!.dueDate != null) {
          _dueDate = DateTime.parse(widget.invoiceToComplete!.dueDate!);
        }
      } catch (_) {}

      try {
        _selectedSupplier = _suppliers.firstWhere(
          (s) => s.id == widget.invoiceToComplete!.supplierId,
        );
        await _onSupplierChanged(_selectedSupplier);
      } catch (_) {}
    } else {
      _generatedInvoiceId = await _controller.generateInvoiceNumber();
    }

    setState(() {});
  }

  void _resetForm() {
    setState(() {
      _supplierInvController.clear();
      _selectedSupplier = null;
      _supplierProducts.clear();
      _details.clear();
      _tempFilePaths.clear();
      _paymentMethod = 'Tunai';
      _invoiceDate = DateTime.now();
      _dueDate = null;
    });
    _loadInitialData();
  }

  Future<void> _onSupplierChanged(Supplier? supplier) async {
    setState(() {
      _selectedSupplier = supplier;
      _supplierProducts.clear();
      _details.clear();
    });
    if (supplier != null) {
      _supplierProducts = await _controller.fetchProductsBySupplier(
        supplier.id!,
      );
      setState(() {});
    }
  }

  void _addDetailRow() {
    setState(() {
      _details.add(_InvoiceDetailRow());
    });
  }

  void _removeDetailRow(int index) {
    setState(() {
      _details.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isDue) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDue ? (_dueDate ?? DateTime.now()) : _invoiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDue) {
          _dueDate = picked;
        } else {
          _invoiceDate = picked;
        }
      });
    }
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );

    if (result != null) {
      List<String> paths = result.paths.whereType<String>().toList();
      setState(() {
        _tempFilePaths.addAll(paths);
      });
    }
  }

  double get _itemsTotal {
    double total = 0;
    for (var d in _details) {
      total += d.totalPrice;
    }
    return total;
  }

  Future<void> _saveInvoice() async {
    if (_selectedSupplier == null) {
      SnackbarHelper.show('Validasi', 'Supplier wajib dipilih', isError: true);
      return;
    }

    double inputNominal =
        double.tryParse(
          _totalNominalController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    if (inputNominal <= 0) {
      SnackbarHelper.show(
        'Validasi',
        'Total Nominal harus lebih dari 0',
        isError: true,
      );
      return;
    }

    if (_isCompleteMode && _details.isEmpty) {
      SnackbarHelper.show(
        'Validasi',
        'Rincian barang tidak boleh kosong untuk melengkapi invoice',
        isError: true,
      );
      return;
    }

    if (_details.isNotEmpty) {
      if ((_itemsTotal - inputNominal).abs() > 1) {
        // allow 1 rupiah difference for rounding
        SnackbarHelper.show(
          'Validasi',
          'Total rincian barang (${formatter.format(_itemsTotal)}) tidak sama dengan Total Nominal Invoice (${formatter.format(inputNominal)}). Silakan revisi rincian atau total nominal.',
          isError: true,
        );
        return;
      }
      for (var d in _details) {
        if (d.selectedProduct == null ||
            d.selectedUnitId == null ||
            d.qty <= 0 ||
            d.unitPrice <= 0) {
          SnackbarHelper.show(
            'Validasi',
            'Lengkapi semua rincian barang dengan benar (Qty dan Harga Beli harus > 0)',
            isError: true,
          );
          return;
        }
      }
    }

    setState(() => _isSaving = true);

    List<PurchaseInvoiceDetail> detailsToSave = _details.map((d) {
      return PurchaseInvoiceDetail(
        invoiceId: 0, // will be set in controller
        productId: d.selectedProduct!.id!,
        unitId: d.selectedUnitId!,
        qty: d.qty,
        unitPrice: d.unitPrice,
        totalPrice: d.totalPrice,
        baseUnitPrice: d.unitPrice / d.ratio,
      );
    }).toList();

    PurchaseInvoice newInvoice = PurchaseInvoice(
      id: _isCompleteMode ? widget.invoiceToComplete!.id : null,
      invoiceNumber: _generatedInvoiceId,
      supplierInvoiceNumber: _supplierInvController.text.trim(),
      supplierId: _selectedSupplier!.id!,
      invoiceDate: _invoiceDate.toIso8601String(),
      dueDate: _dueDate?.toIso8601String(),
      paymentMethod: _paymentMethod,
      totalNominal: inputNominal,
      paidAmount: _isCompleteMode ? widget.invoiceToComplete!.paidAmount : 0,
      status: _isCompleteMode
          ? widget.invoiceToComplete!.status
          : 'Belum Lunas',
      createdAt: _isCompleteMode
          ? widget.invoiceToComplete!.createdAt
          : DateTime.now().toIso8601String(),
    );

    bool success;
    if (_isCompleteMode) {
      success = await _controller.completeInvoice(
        newInvoice,
        inputNominal,
        detailsToSave,
      );
    } else {
      success = await _controller.saveInvoice(
        newInvoice,
        detailsToSave,
        _tempFilePaths,
      );
    }

    setState(() => _isSaving = false);
    if (success) {
      if (_isCompleteMode) {
        Get.back();
      } else {
        _resetForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isCompleteMode
              ? 'Lengkapi Invoice Pembelian'
              : 'Buat Invoice Pembelian',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT PANE: Header
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Informasi Faktur',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildModernTextField(
                      controller: TextEditingController(
                        text: _generatedInvoiceId,
                      ),
                      label: 'ID Sistem Internal',
                      readOnly: true,
                      icon: Icons.tag,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<Supplier>(
                      value: _selectedSupplier,
                      decoration: _modernInputDecoration(
                        'Supplier *',
                        Icons.local_shipping,
                      ),
                      items: _suppliers
                          .map(
                            (s) =>
                                DropdownMenuItem(value: s, child: Text(s.name)),
                          )
                          .toList(),
                      onChanged: _isCompleteMode ? null : _onSupplierChanged,
                      dropdownColor: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    _buildModernTextField(
                      controller: _supplierInvController,
                      label: 'Nomor Invoice Supplier',
                      icon: Icons.receipt,
                      readOnly: _isCompleteMode,
                    ),
                    const SizedBox(height: 20),
                    _buildModernTextField(
                      controller: _totalNominalController,
                      label: 'Total Nominal Invoice *',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _isCompleteMode
                                ? null
                                : () => _selectDate(context, false),
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: _modernInputDecoration(
                                'Tanggal Invoice *',
                                Icons.calendar_today,
                              ),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(_invoiceDate),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _isCompleteMode
                                ? null
                                : () => _selectDate(context, true),
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: _modernInputDecoration(
                                'Jatuh Tempo',
                                Icons.event,
                              ),
                              child: Text(
                                _dueDate != null
                                    ? DateFormat(
                                        'dd MMM yyyy',
                                      ).format(_dueDate!)
                                    : 'Pilih Tanggal',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: _modernInputDecoration(
                        'Metode Pembayaran *',
                        Icons.payment,
                      ),
                      items: ['Tunai', 'Transfer', 'Hutang']
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                      dropdownColor: Colors.white,
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.attach_file,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Dokumen Lampiran',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(
                        Icons.upload_file,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        'Unggah Berkas',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_tempFilePaths.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.background),
                        ),
                        child: Column(
                          children: _tempFilePaths
                              .map(
                                (path) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.insert_drive_file,
                                        color: AppColors.accent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          p.basename(path),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => setState(
                                          () => _tempFilePaths.remove(path),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: AppColors.error,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // RIGHT PANE: Details & Summary
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 24.0,
                bottom: 24.0,
                right: 24.0,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.list_alt,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Rincian Barang',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: _selectedSupplier == null
                                      ? null
                                      : _addDetailRow,
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Tambah Barang',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: _selectedSupplier == null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 64,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Pilih Supplier terlebih dahulu\nuntuk menambahkan barang',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : _details.isEmpty
                                ? Center(
                                    child: Text(
                                      'Belum ada barang yang ditambahkan.',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _details.length,
                                    itemBuilder: (context, index) {
                                      return _buildDetailCard(
                                        _details[index],
                                        index,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // TOTAL & BUTTON CARD
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Nominal',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatter.format(_itemsTotal),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveInvoice,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.save,
                                    color: AppColors.primary,
                                  ),
                            label: Text(
                              _isSaving ? 'Menyimpan...' : 'Simpan Invoice',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _modernInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: TextStyle(
        fontWeight: readOnly ? FontWeight.bold : FontWeight.normal,
        color: readOnly ? Colors.grey.shade700 : AppColors.textPrimary,
      ),
      decoration: _modernInputDecoration(label, icon).copyWith(
        fillColor: readOnly ? Colors.grey.shade200 : Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDetailCard(_InvoiceDetailRow row, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item #${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              InkWell(
                onTap: () => _removeDetailRow(index),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<Product>(
                  value: row.selectedProduct,
                  decoration: _modernInputDecoration(
                    'Pilih Barang *',
                    Icons.inventory_2,
                  ),
                  dropdownColor: Colors.white,
                  items: _supplierProducts
                      .map(
                        (p) => DropdownMenuItem(value: p, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (val) async {
                    if (val != null) {
                      var units = await _controller.fetchUnitsForProduct(
                        val.id!,
                      );
                      setState(() {
                        row.selectedProduct = val;
                        row.availableUnits = units;
                        row.selectedUnitId = val.unitId;
                        row.ratio = units.firstWhere(
                          (u) => u['unit'].id == val.unitId,
                        )['multiplier'];
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  value: row.selectedUnitId,
                  decoration: _modernInputDecoration(
                    'Satuan *',
                    Icons.straighten,
                  ),
                  dropdownColor: Colors.white,
                  items: row.availableUnits.map((u) {
                    return DropdownMenuItem<int>(
                      value: u['unit'].id,
                      child: Text(u['unit'].name),
                    );
                  }).toList(),
                  onChanged: row.availableUnits.isEmpty
                      ? null
                      : (val) {
                          setState(() {
                            row.selectedUnitId = val;
                            row.ratio = row.availableUnits.firstWhere(
                              (u) => u['unit'].id == val,
                            )['multiplier'];
                          });
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: row.qty == 0 ? '' : row.qty.toString(),
                  decoration: _modernInputDecoration('Qty *', Icons.numbers),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    setState(() {
                      row.qty = int.tryParse(val) ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: row.unitPrice == 0
                      ? ''
                      : row.unitPrice.toString(),
                  decoration: _modernInputDecoration(
                    'Harga Beli / Satuan *',
                    Icons.payments,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    setState(() {
                      row.unitPrice = double.tryParse(val) ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Summary Blocks
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.background),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Harga/Satuan Utama',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatter.format(
                                row.unitPrice /
                                    (row.ratio == 0 ? 1 : row.ratio),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Subtotal',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatter.format(row.totalPrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceDetailRow {
  Product? selectedProduct;
  List<Map<String, dynamic>> availableUnits = [];
  int? selectedUnitId;
  int ratio = 1;
  int qty = 0;
  double unitPrice = 0;

  double get totalPrice => qty * unitPrice;
}
