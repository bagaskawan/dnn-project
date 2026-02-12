import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/services/api_service.dart';

class AddStockModal extends StatefulWidget {
  final Map<String, dynamic> product;

  const AddStockModal({super.key, required this.product});

  @override
  State<AddStockModal> createState() => _AddStockModalState();
}

class _AddStockModalState extends State<AddStockModal> {
  final ApiService _apiService = ApiService();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _buyPriceController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _availableSuppliers = [];

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  Future<void> _fetchSuppliers() async {
    final contacts = await _apiService.getContacts(type: 'SUPPLIER');
    setState(() {
      _availableSuppliers = contacts.map((e) => e.toJson()).toList();
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _supplierController.dispose();
    _phoneController.dispose();
    _buyPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Tambah Stok',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              widget.product['name'] ?? '',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Qty Input
            _buildTextField(
              'Jumlah Stok Masuk',
              _qtyController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandSeparatorInputFormatter()],
              suffix: widget.product['unit'] ?? 'pcs',
              hint: '10',
            ),
            const SizedBox(height: 16),

            // Supplier Autocomplete
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supplier',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Autocomplete<Map<String, dynamic>>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<Map<String, dynamic>>.empty();
                    }
                    return _availableSuppliers.where((
                      Map<String, dynamic> option,
                    ) {
                      return option['name'].toString().toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    });
                  },
                  displayStringForOption: (Map<String, dynamic> option) =>
                      option['name'],
                  onSelected: (Map<String, dynamic> selection) {
                    _supplierController.text = selection['name'];
                    _phoneController.text = selection['phone'] ?? '';
                    // Disable phone editing if existing supplier? No, let them edit.
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    // Sync controller
                    // We need to listen to controller changes to update _supplierController
                    // But textEditingController IS the controller for the field.
                    // We'll just use it. But we need to extract value on save.
                    // Actually, simpler to assign _supplierController = textEditingController?
                    // No, Autocomplete manages it.
                    // We'll use a listener to sync or just access textEditingController.text in save.
                    // But we can't access it easily from outside build.
                    // Standard way: keep reference to local controller inside builder?
                    // Better: Pass _supplierController to fieldViewBuilder? No, it provides one.
                    // Workaround: Copy text on change to our controller.
                    textEditingController.addListener(() {
                      _supplierController.text = textEditingController.text;
                    });

                    // Set initial value if needed? (Empty initially)
                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari atau ketik nama supplier baru',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width:
                              MediaQuery.of(context).size.width -
                              48, // Match parent width
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(
                                  option['name'],
                                  style: GoogleFonts.montserrat(),
                                ),
                                subtitle: option['phone'] != null
                                    ? Text(
                                        option['phone'],
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                                onTap: () {
                                  onSelected(option);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Phone Input
            _buildTextField(
              'No. HP Supplier',
              _phoneController,
              keyboardType: TextInputType.phone,
              hint: '08xxxx',
            ),
            const SizedBox(height: 16),

            // Buy Price Input
            _buildTextField(
              'Total Harga Beli',
              _buyPriceController,
              keyboardType: TextInputType.number,
              prefix: 'Rp ',
              inputFormatters: [ThousandSeparatorInputFormatter()],
              hint: '100.000',
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveStock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Simpan Stok',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefix,
    String? suffix,
    String? hint,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            prefixText: prefix,
            suffixText: suffix,
            hintText: hint,
            prefixStyle: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            hintStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Future<void> _showError(String message) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Perhatian',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: GoogleFonts.montserrat()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.montserrat(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveStock() async {
    // Validate Qty
    if (_qtyController.text.isEmpty) {
      await _showError('Jumlah stok wajib diisi!');
      return;
    }

    // Validate Supplier
    if (_supplierController.text.isEmpty) {
      await _showError('Nama supplier wajib diisi!');
      return;
    }

    // Remove separators
    final buyPriceText = _buyPriceController.text.replaceAll('.', '');

    // Validate Total Price
    if (buyPriceText.isEmpty) {
      await _showError('Total harga beli wajib diisi!');
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'qty': double.tryParse(_qtyController.text.replaceAll('.', '')) ?? 0,
      'supplier_name': _supplierController.text,
      'supplier_phone': _phoneController.text.isEmpty
          ? null
          : _phoneController.text,
      'total_buy_price': double.tryParse(buyPriceText),
    };

    final result = await _apiService.addProductStock(
      widget.product['id'],
      data,
    );

    setState(() => _isLoading = false);

    if (result != null && result['success'] == true) {
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate refresh needed
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menambahkan stok',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Helper for thousand separator (Reusable)
class ThousandSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (newText.isEmpty) return const TextEditingValue(text: '');

    final numericValue = int.tryParse(newText) ?? 0;
    final formatted = numericValue.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
