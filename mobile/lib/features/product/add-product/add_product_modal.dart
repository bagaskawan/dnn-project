import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_service.dart';

class AddProductModal extends StatefulWidget {
  const AddProductModal({super.key});

  @override
  State<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final ApiService _apiService = ApiService();

  String _selectedUnit = 'Pcs';
  final List<String> _unitOptions = [
    'Pcs',
    'Kg',
    'Liter',
    'Botol',
    'Box',
    'Dus',
  ];

  List<ContactItem> _suppliers = [];
  String? _selectedSupplierId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  Future<void> _fetchSuppliers() async {
    final suppliers = await _apiService.getContacts(type: 'SUPPLIER');
    if (mounted) {
      setState(() {
        _suppliers = suppliers;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row with Cancel/Save
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Tambah Produk',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            Divider(color: Colors.grey.shade200),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Produk
                    _buildLabel('Nama Produk'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Contoh: Beras Premium Rojolele',
                    ),
                    const SizedBox(height: 16),

                    // Harga Produk Row
                    _buildLabel('Harga Produk'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _priceController,
                      hint: '0',
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      prefix: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          'Rp',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Stok Awal
                    _buildLabel('Stok Produk'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _stockController,
                      hint: 'Masukkan jumlah stok saat ini',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [DecimalInputFormatter()],
                    ),
                    const SizedBox(height: 16),
                    // Satuan Dasar
                    _buildLabel('Satuan Dasar'),
                    const SizedBox(height: 8),
                    _buildDropdown(),
                    const SizedBox(height: 16),
                    // Data Supplier
                    _buildLabel('Data Supplier'),
                    const SizedBox(height: 8),
                    _buildSupplierDropdown(),
                  ],
                ),
              ),
            ),

            // Bottom Floating Action Button (Alternative to Top Save)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.textPrimary, // Dark Button as in design
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
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
                          'Simpan Produk',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool showInfo = false}) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (showInfo) ...[
          const Spacer(),
          Icon(Icons.info_outline, size: 18, color: Colors.grey.shade400),
        ],
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? prefix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          30,
        ), // Rounded pill shape as in design
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefix != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 20, top: 14, bottom: 14),
                  child: prefix,
                )
              : null,
          hintStyle: GoogleFonts.montserrat(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: prefix != null
              ? const EdgeInsets.symmetric(
                  vertical: 14,
                ) // Adjust if prefix exists
              : const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUnit,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
          items: _unitOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedUnit = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSupplierDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSupplierId,
          hint: Text(
            'Pilih Supplier',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
          items: _suppliers.map((supplier) {
            return DropdownMenuItem<String>(
              value: supplier.id,
              child: Text(
                supplier.name,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedSupplierId = newValue;
            });
          },
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    // Validate Name
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama produk wajib diisi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Construct Product Data
    final name = _nameController.text.trim();
    // Parse stock (handle decimal)
    String stockString = _stockController.text.replaceAll(',', '.');
    final stock = double.tryParse(stockString) ?? 0.0;

    // Parse currency (strip dots)
    final priceString = _priceController.text.replaceAll('.', '');
    final price = int.tryParse(priceString) ?? 0;

    final initial = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.substring(0, 1).toUpperCase();

    final data = {
      'name': name,
      'price': price,
      'stock': stock,
      'unit': _selectedUnit.toLowerCase(),
      'initial': initial,
      'average_cost': 0,
      if (_selectedSupplierId != null) 'supplier_id': _selectedSupplierId,
    };

    final result = await _apiService.createProduct(data);

    setState(() => _isLoading = false);

    if (result != null) {
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil disimpan'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan produk'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Allow digits and at most one '.' or ','
    final regExp = RegExp(r'^\d*([.,]?\d*)?$');

    // Explicitly check that we don't have mixed separators or multiple
    // The regex ^\d*([.,]?\d*)?$ ensures at most one separator.
    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String cleanText = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    int value = int.parse(cleanText);

    // Manual thousands separator using regex
    String newText = value.toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    Function mathFunc = (Match match) => '${match[1]}.';

    String formatted = newText.replaceAllMapped(
      reg,
      mathFunc as String Function(Match),
    );

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
