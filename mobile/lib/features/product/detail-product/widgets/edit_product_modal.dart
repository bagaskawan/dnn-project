import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/services/api_service.dart';

class EditProductModal extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductModal({super.key, required this.product});

  @override
  State<EditProductModal> createState() => _EditProductModalState();
}

class _EditProductModalState extends State<EditProductModal> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _avgCostController;
  late TextEditingController _stockController;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product['name'] ?? '');

    // Format price with thousand separator
    final price =
        widget.product['latest_selling_price'] ?? widget.product['price'] ?? 0;
    final priceInt = price is num ? price.toInt() : 0;
    _priceController = TextEditingController(text: _formatThousand(priceInt));

    // Format average cost
    final avgCost =
        widget.product['average_cost'] ?? widget.product['cost_per_pcs'] ?? 0;
    final avgCostInt = avgCost is num ? avgCost.toInt() : 0;
    _avgCostController = TextEditingController(
      text: _formatThousand(avgCostInt),
    );

    // Format stock without decimal if it's a whole number
    final stock =
        widget.product['current_stock'] ?? widget.product['stock'] ?? 0;
    _stockController = TextEditingController(
      text: stock is num && stock == stock.toInt()
          ? stock.toInt().toString()
          : stock.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _avgCostController.dispose();
    _stockController.dispose();
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
            Text(
              'Edit Produk',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField('Nama Produk', _nameController),
            const SizedBox(height: 16),
            _buildTextField(
              'Harga Jual',
              _priceController,
              keyboardType: TextInputType.number,
              prefix: 'Rp ',
              inputFormatters: [ThousandSeparatorInputFormatter()],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Harga Modal (per Satuan)',
              _avgCostController,
              keyboardType: TextInputType.number,
              prefix: 'Rp ',
              inputFormatters: [ThousandSeparatorInputFormatter()],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Total Stok',
              _stockController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
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
                        'Simpan',
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

  Future<void> _saveProduct() async {
    setState(() => _isLoading = true);

    // Remove thousand separators before parsing
    final priceText = _priceController.text.replaceAll('.', '');
    final avgCostText = _avgCostController.text.replaceAll('.', '');

    final updatedData = {
      'name': _nameController.text,
      'latest_selling_price': double.tryParse(priceText) ?? 0,
      'average_cost': double.tryParse(avgCostText) ?? 0,
      'current_stock': double.tryParse(_stockController.text) ?? 0,
    };

    final result = await _apiService.updateProduct(
      widget.product['id'],
      updatedData,
    );

    setState(() => _isLoading = false);

    if (result != null) {
      if (mounted) {
        // Return updated data
        Navigator.pop(context, {
          ...widget.product,
          'name': updatedData['name'],
          'latest_selling_price': updatedData['latest_selling_price'],
          'average_cost': updatedData['average_cost'],
          'current_stock': updatedData['current_stock'],
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memperbarui produk',
              style: GoogleFonts.montserrat(fontSize: 13),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefix,
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
            prefixStyle: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
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

  String _formatThousand(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

/// Custom input formatter for thousand separator (1.000.000)
class ThousandSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove any non-digit characters
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (newText.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Format with thousand separators
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
