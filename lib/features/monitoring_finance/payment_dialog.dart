import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'finance_monitoring_controller.dart';

class PaymentDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  final String type; // 'payable' or 'receivable'

  const PaymentDialog({Key? key, required this.data, required this.type})
    : super(key: key);

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final FinanceMonitoringController _controller =
      Get.find<FinanceMonitoringController>();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  double amountPaid = 0.0;
  File? _selectedFile;
  bool _isLoading = false;

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  void _submit() async {
    if (amountPaid <= 0) {
      Get.snackbar(
        'Error',
        'Nominal harus lebih dari 0',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    double maxAmount = widget.data['sisa_tagihan'] as double;
    if (amountPaid > maxAmount) {
      Get.snackbar(
        'Error',
        'Nominal tidak boleh melebihi sisa tagihan.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (_selectedFile == null) {
      Get.snackbar(
        'Error',
        'Bukti pembayaran wajib diunggah.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);
    await _controller.processPayment(
      type: widget.type,
      id: widget.data['id'] as int,
      amount: amountPaid,
      attachment: _selectedFile!,
    );
    setState(() => _isLoading = false);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    double sisaTagihan = widget.data['sisa_tagihan'] as double;
    String refNumber = widget.type == 'payable'
        ? widget.data['invoice_number']
        : widget.data['transaction_number'];
    String name = widget.type == 'payable'
        ? widget.data['supplier_name']
        : widget.data['customer_name'];

    return AlertDialog(
      title: Text('Pelunasan: $refNumber'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pihak Terkait: $name',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Sisa Tagihan: ${_currencyFormat.format(sisaTagihan)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Nominal Bayar / Cicil',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  String cleanVal = val.replaceAll(RegExp(r'[^0-9]'), '');
                  amountPaid = double.tryParse(cleanVal) ?? 0.0;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Unggah Bukti'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedFile != null
                          ? _selectedFile!.path.split('\\').last
                          : 'Belum ada file',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _selectedFile != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
