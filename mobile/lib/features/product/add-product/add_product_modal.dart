import 'dart:async';
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
  // Controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _supplierNameController = TextEditingController();
  final _phoneController = TextEditingController();

  final ApiService _apiService = ApiService();

  // Unit dropdown
  String _selectedUnit = 'Pcs';
  final List<String> _unitOptions = [
    'Pcs',
    'Kg',
    'Liter',
    'Botol',
    'Box',
    'Dus',
  ];

  bool _isLoading = false;

  // Product search state
  List<Map<String, dynamic>> _productSuggestions = [];
  bool _isSearchingProduct = false;
  Map<String, dynamic>? _selectedProduct;
  Timer? _productDebounce;

  // Supplier search state
  List<ContactItem> _supplierSuggestions = [];
  bool _isSearchingSupplier = false;
  ContactItem? _selectedSupplier;
  Timer? _supplierDebounce;

  // Overlay for suggestions (renders above everything)
  OverlayEntry? _overlayEntry;
  final LayerLink _productLayerLink = LayerLink();
  final LayerLink _supplierLayerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onProductNameChanged);
    _supplierNameController.addListener(_onSupplierNameChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _nameController.removeListener(_onProductNameChanged);
    _supplierNameController.removeListener(_onSupplierNameChanged);
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _supplierNameController.dispose();
    _phoneController.dispose();
    _productDebounce?.cancel();
    _supplierDebounce?.cancel();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // --- Product Search Logic ---
  void _onProductNameChanged() {
    final query = _nameController.text.trim();
    _productDebounce?.cancel();

    // Don't search if user just selected an item
    if (_selectedProduct != null) {
      final selectedName =
          _selectedProduct!['display_name'] ?? _selectedProduct!['name'];
      if (query == selectedName) return; // Same as selected, skip
      // User edited text after selecting, clear selection
      setState(() {
        _selectedProduct = null;
        _selectedUnit = 'Pcs'; // Reset satuan ke default
      });
    }

    if (query.length < 2) {
      setState(() {
        _productSuggestions = [];
      });
      _removeOverlay();
      return;
    }

    _productDebounce = Timer(const Duration(milliseconds: 1500), () {
      _searchProducts(query);
    });
  }

  Future<void> _searchProducts(String query) async {
    setState(() => _isSearchingProduct = true);

    try {
      final results = await _apiService.searchProducts(query);
      if (mounted) {
        setState(() {
          _productSuggestions = results;
          _isSearchingProduct = false;
        });
        if (results.isNotEmpty) {
          _showSuggestionsOverlay(
            layerLink: _productLayerLink,
            suggestions: results.map((p) {
              final displayName = p['display_name'] ?? p['name'];
              final stock = p['stock'] ?? 0;
              final unit = p['unit'] ?? '';
              return _SuggestionItem(
                title: displayName,
                subtitle: 'Stok: $stock $unit',
                onTap: () => _selectProduct(p),
              );
            }).toList(),
          );
        } else {
          _removeOverlay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearchingProduct = false);
      }
    }
  }

  void _selectProduct(Map<String, dynamic> product) {
    _removeOverlay();
    _productDebounce?.cancel();
    // Remove listener to prevent re-triggering search when setting text
    _nameController.removeListener(_onProductNameChanged);
    setState(() {
      _selectedProduct = product;
      _nameController.text = product['display_name'] ?? product['name'];

      // Auto-fill price removed to avoid user confusion:
      // Since the input field now expects "Total Harga Beli", autofilling 
      // the price per unit (latest_selling_price) would be incorrect if user 
      // is adding stock more than 1. User should manually input total price.

      // Auto-fill unit if available
      final unit = product['unit'];
      if (unit != null) {
        String unitCap = unit.toString();
        unitCap = unitCap[0].toUpperCase() + unitCap.substring(1).toLowerCase();
        if (_unitOptions.contains(unitCap)) {
          _selectedUnit = unitCap;
        }
      }
    });
    _nameController.addListener(_onProductNameChanged);
  }

  // --- Supplier Search Logic ---
  void _onSupplierNameChanged() {
    final query = _supplierNameController.text.trim();
    _supplierDebounce?.cancel();

    // Don't search if user just selected an item
    if (_selectedSupplier != null) {
      if (query == _selectedSupplier!.name) return; // Same as selected, skip
      // User edited text after selecting, clear selection
      setState(() {
        _selectedSupplier = null;
        _phoneController.clear();
      });
    }

    if (query.length < 2) {
      setState(() {
        _supplierSuggestions = [];
      });
      _removeOverlay();
      return;
    }

    _supplierDebounce = Timer(const Duration(milliseconds: 1500), () {
      _searchSuppliers(query);
    });
  }

  Future<void> _searchSuppliers(String query) async {
    setState(() => _isSearchingSupplier = true);

    try {
      final results = await _apiService.searchContacts(query, type: 'SUPPLIER');
      if (mounted) {
        setState(() {
          _supplierSuggestions = results;
          _isSearchingSupplier = false;
        });
        if (results.isNotEmpty) {
          _showSuggestionsOverlay(
            layerLink: _supplierLayerLink,
            suggestions: results.map((s) {
              return _SuggestionItem(
                title: s.name,
                subtitle: s.phone ?? 'Belum ada nomor HP',
                onTap: () => _selectSupplier(s),
              );
            }).toList(),
          );
        } else {
          _removeOverlay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearchingSupplier = false);
      }
    }
  }

  void _selectSupplier(ContactItem supplier) {
    _removeOverlay();
    _supplierDebounce?.cancel();
    // Remove listener to prevent re-triggering search when setting text
    _supplierNameController.removeListener(_onSupplierNameChanged);
    setState(() {
      _selectedSupplier = supplier;
      _supplierNameController.text = supplier.name;

      // Auto-fill phone
      if (supplier.phone != null && supplier.phone!.isNotEmpty) {
        _phoneController.text = supplier.phone!;
      }
    });
    _supplierNameController.addListener(_onSupplierNameChanged);
  }

  // --- Overlay Management ---
  void _showSuggestionsOverlay({
    required LayerLink layerLink,
    required List<_SuggestionItem> suggestions,
  }) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeOverlay, // Dismiss on tap outside
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: layerLink,
              offset: const Offset(0, 52), // Below the text field
              showWhenUnlinked: false,
              child: Material(
                elevation: 4,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: layerLink.leaderSize?.width ?? 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final item = suggestions[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        title: Text(
                          item.title,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          item.subtitle,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        trailing: Icon(
                          Icons.north_west,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                        onTap: item.onTap,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
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

            // Header
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
                    // === SECTION: PRODUK ===

                    // Label
                    _buildSectionLabel(
                      'Informasi Produk',
                      Icons.inventory_2_outlined,
                    ),
                    const SizedBox(height: 12),

                    // 1. Nama Produk (with autocomplete)
                    _buildAutocompleteField(
                      controller: _nameController,
                      hint: 'Nama Produk (Contoh: Beras Premium)',
                      icon: Icons.inventory_2_outlined,
                      isSearching: _isSearchingProduct,
                      layerLink: _productLayerLink,
                      selectedLabel: _selectedProduct != null
                          ? 'Produk yang sudah ada'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // 2. Harga Produk
                    _buildPriceField(),
                    const SizedBox(height: 16),

                    // 3. Stok + Satuan Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildTextField(
                            controller: _stockController,
                            hint: 'Stok Awal',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            prefix: Icon(
                              Icons.numbers_outlined,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: _buildDropdown()),
                      ],
                    ),

                    // === Horizontal Divider ===
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Supplier',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                    ),

                    // === SECTION: SUPPLIER ===

                    // Label
                    _buildSectionLabel(
                      'Informasi Supplier',
                      Icons.store_outlined,
                    ),
                    const SizedBox(height: 12),

                    // 4. Nama Supplier (with autocomplete)
                    _buildAutocompleteField(
                      controller: _supplierNameController,
                      hint: 'Nama Supplier',
                      icon: Icons.store_outlined,
                      isSearching: _isSearchingSupplier,
                      layerLink: _supplierLayerLink,
                      selectedLabel: _selectedSupplier != null
                          ? 'Supplier yang sudah ada'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // 5. Nomor HP
                    _buildTextField(
                      controller: _phoneController,
                      hint: 'Nomor HP Supplier',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      prefix: Icon(
                        Icons.phone_outlined,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      enabled:
                          _selectedSupplier == null, // Disable if auto-filled
                    ),
                    if (_selectedSupplier != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          'Terisi otomatis dari data supplier',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Save Button
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
                    backgroundColor: AppColors.textPrimary,
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

  // --- Section Label Widget ---
  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textPrimary),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // --- Autocomplete Field Widget (uses LayerLink for overlay positioning) ---
  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isSearching,
    required LayerLink layerLink,
    String? selectedLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: layerLink,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedLabel != null
                    ? Colors.green.shade300
                    : Colors.grey.shade200,
              ),
            ),
            child: TextField(
              controller: controller,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
                suffixIcon: isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : selectedLabel != null
                    ? Icon(
                        Icons.check_circle,
                        color: Colors.green.shade400,
                        size: 20,
                      )
                    : null,
                hintStyle: GoogleFonts.montserrat(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),

        // Selected label
        if (selectedLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              selectedLabel,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: Colors.green.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  // --- Dedicated Price Field (Rp prefix always visible) ---
  Widget _buildPriceField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _priceController,
        keyboardType: TextInputType.number,
        inputFormatters: [CurrencyInputFormatter()],
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Total Harga Beli',
          prefixIcon: SizedBox(
            width: 44,
            child: Center(
              child: Text(
                'Rp',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 48,
          ),
          hintStyle: GoogleFonts.montserrat(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // --- Standard Text Field ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? prefix,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        enabled: enabled,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: enabled ? AppColors.textPrimary : Colors.grey.shade600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefix is Icon ? prefix : null,
          hintStyle: GoogleFonts.montserrat(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // --- Unit Dropdown ---
  Widget _buildDropdown() {
    final bool isLocked = _selectedProduct != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isLocked ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUnit,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isLocked ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          items: _unitOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isLocked ? Colors.grey.shade500 : AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: isLocked
              ? null  // Disable dropdown jika produk dari database
              : (newValue) {
                  setState(() {
                    _selectedUnit = newValue!;
                  });
                },
        ),
      ),
    );
  }

  // --- Save Product ---
  Future<void> _saveProduct() async {
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

    final name = _nameController.text.trim();
    final stockString = _stockController.text.replaceAll(',', '.');
    final stock = double.tryParse(stockString) ?? 0.0;

    final priceString = _priceController.text.replaceAll('.', '');
    final totalPrice = int.tryParse(priceString) ?? 0;

    int unitPrice = 0;
    if (stock > 0) {
      unitPrice = (totalPrice / stock).round();
    } else {
      unitPrice = totalPrice;
    }

    final data = {
      'name': name,
      'unit_price': unitPrice, // Mengirim harga satuan yang sudah dihitung (kurang presisi kalau pakai koma/pecahan)
      'total_price': totalPrice, // Mengirim TOTAL MURNI agar backend bisa mengkalkulasi ulang tanpa kehilangan presisi
      'initial_stock': stock,
      'base_unit': _selectedUnit.toLowerCase(),
    };

    // Include supplier info if provided
    final supplierName = _supplierNameController.text.trim();
    if (supplierName.isNotEmpty) {
      data['supplier_name'] = supplierName;
      final phone = _phoneController.text.trim();
      if (phone.isNotEmpty) {
        data['supplier_phone'] = phone;
      }
    }

    // 1. Amankan instance object sebelum terpotong blok async
    final messenger = ScaffoldMessenger.of(context);

    // 2. Panggil API yang sesuai
    dynamic result;
    String successMessage;

    if (_selectedProduct != null) {
      // === PRODUK SUDAH ADA → Tambah Stok ===
      final productId = _selectedProduct!['id'];
      final stockData = <String, dynamic>{
        'qty': stock,
        'total_buy_price': totalPrice,
        'supplier_name': _supplierNameController.text.trim(),
      };
      final phone = _phoneController.text.trim();
      if (phone.isNotEmpty) {
        stockData['supplier_phone'] = phone;
      }
      result = await _apiService.addProductStock(productId, stockData);
      successMessage = 'Stok berhasil ditambahkan';
    } else {
      // === PRODUK BARU → Buat Produk ===
      result = await _apiService.createProduct(data);
      successMessage = 'Produk berhasil disimpan';
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      // 3. Tutup modal secara langsung (ModalBottomsheet) sambil melempar flag 'true' untuk refresh data
      Navigator.pop(context, true);

      // 4. Tampilkan Pesan Sukses menggunakan messenger yang sudah dicapture
      messenger.showSnackBar(
        SnackBar(
          content: Text(successMessage),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.up,
          margin: EdgeInsets.only(
            bottom: 90,
            left: 24,
            right: 24,
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Gagal menyimpan produk'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.up,
          margin: EdgeInsets.only(
            bottom: 90,
            left: 24,
            right: 24,
          ),
        ),
      );
    }
  }
}

// --- Helper class for suggestion items ---
class _SuggestionItem {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _SuggestionItem({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

// --- Input Formatters ---

class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final regExp = RegExp(r'^\d*([.,]?\d*)?$');

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

    String newText = value.toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    Function mathFunc = (Match match) => '${match[0]}.';

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
