import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';
import '../../models/procurement_draft.dart';
import '../../shared/widgets/main_shell.dart';

class BuyScanOcrPage extends StatefulWidget {
  final File initialImage;
  const BuyScanOcrPage({super.key, required this.initialImage});

  @override
  State<BuyScanOcrPage> createState() => _BuyScanOcrPageState();
}

class _BuyScanOcrPageState extends State<BuyScanOcrPage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  ProcurementDraft? _currentDraft;
  String? _transactionCode;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // --- Feature: Product search state (item name search) ---
  List<String> _productSuggestions = [];
  bool _isSearchingProducts = false;

  // --- Animated dots for loading state ---
  late AnimationController _dotsController;
  late Animation<int> _dotsAnimation;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _dotsAnimation = IntTween(begin: 0, end: 3).animate(_dotsController);
    _processImage();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  // --- Feature: Search products from backend by name ---
  Future<void> _searchProducts(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _productSuggestions = []);
      return;
    }
    setState(() => _isSearchingProducts = true);
    try {
      final results = await _apiService.searchProducts(query);
      // api_service returns List<Map<String,dynamic>>, extract product names
      setState(() {
        _productSuggestions = results
            .map((p) => (p['product_name'] ?? p['name'] ?? '').toString())
            .where((name) => name.isNotEmpty)
            .toList();
        _isSearchingProducts = false;
      });
    } catch (_) {
      setState(() => _isSearchingProducts = false);
    }
  }

  // --- Feature: Show full-screen image zoom popup ---
  void _showImageZoom() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 6.0,
                  child: Image.file(widget.initialImage, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final draft = await _apiService.parseImage(widget.initialImage, null);
      setState(() {
        _isLoading = false;
        if (draft != null && draft.items.isNotEmpty) {
          _currentDraft = draft;
          _transactionCode =
              "INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
        } else {
          _hasError = true;
          _errorMessage =
              draft?.followUpQuestion ??
              'Gagal menganalisis gambar. Silakan coba lagi.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  double get _totalPrice {
    if (_currentDraft == null) return 0;
    double total = 0;
    for (var item in _currentDraft!.items) {
      total += item.totalPrice;
    }
    return total;
  }

  void _showEditItemSheet(int index, ExtractedItem item) {
    final nameController = TextEditingController(text: item.productName);
    final qtyController = TextEditingController(
      text: item.qty.toStringAsFixed(0),
    );
    final unitController = TextEditingController(text: item.unit);
    final priceController = TextEditingController(
      text: item.totalPrice.toStringAsFixed(0),
    );
    final variantController = TextEditingController(text: item.variant ?? "");
    final noteController = TextEditingController(text: item.notes ?? "");
    String selectedProductName = item.productName;

    final bool hasVariant = item.variant != null && item.variant!.isNotEmpty;
    final bool hasNotes = item.notes != null && item.notes!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(
                          "Edit Barang",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- Item Name with Search ---
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: "Nama Barang",
                            labelStyle: GoogleFonts.montserrat(fontSize: 12),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: _isSearchingProducts
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.search, size: 18),
                          ),
                          onChanged: (val) {
                            selectedProductName = val;
                            _searchProducts(val).then((_) {
                              setSheetState(() {});
                            });
                          },
                        ),

                        // --- Search Suggestions ---
                        if (_productSuggestions.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: _productSuggestions.map((suggestion) {
                                final isExact =
                                    suggestion.toLowerCase() ==
                                    nameController.text.toLowerCase();
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    isExact
                                        ? Icons.check_circle
                                        : Icons.inventory_2_outlined,
                                    size: 18,
                                    color: isExact
                                        ? Colors.green
                                        : AppColors.primary,
                                  ),
                                  title: Text(
                                    suggestion,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: isExact
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isExact
                                        ? 'Ada di database — stok akan ditambah'
                                        : 'Ada di database',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      color: isExact
                                          ? Colors.green.shade600
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                  onTap: () {
                                    nameController.text = suggestion;
                                    selectedProductName = suggestion;
                                    setSheetState(
                                      () => _productSuggestions = [],
                                    );
                                    setState(() => _productSuggestions = []);
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],

                        // Hint: if no suggestion matched = produk baru
                        if (_productSuggestions.isEmpty &&
                            nameController.text.isNotEmpty &&
                            !_isSearchingProducts) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.fiber_new,
                                size: 14,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Produk baru — akan disimpan ke database',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: qtyController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Jumlah",
                                  labelStyle: GoogleFonts.montserrat(
                                    fontSize: 12,
                                  ),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: unitController,
                                decoration: InputDecoration(
                                  labelText: "Satuan",
                                  labelStyle: GoogleFonts.montserrat(
                                    fontSize: 12,
                                  ),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _CurrencyInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            labelText: "Total Harga (Rp)",
                            labelStyle: GoogleFonts.montserrat(fontSize: 12),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        if (hasVariant) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: variantController,
                            decoration: InputDecoration(
                              labelText: "Variant (Ukuran/Tipe)",
                              labelStyle: GoogleFonts.montserrat(fontSize: 12),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                        if (hasNotes) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: noteController,
                            decoration: InputDecoration(
                              labelText: "Catatan",
                              labelStyle: GoogleFonts.montserrat(fontSize: 12),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              final newItem = ExtractedItem(
                                productName: selectedProductName.trim().isEmpty
                                    ? item.productName
                                    : selectedProductName.trim(),
                                variant: hasVariant
                                    ? variantController.text
                                    : item.variant,
                                qty:
                                    double.tryParse(qtyController.text) ??
                                    item.qty,
                                unit: unitController.text,
                                totalPrice:
                                    double.tryParse(
                                      priceController.text.replaceAll('.', ''),
                                    ) ??
                                    item.totalPrice,
                                notes: hasNotes
                                    ? noteController.text
                                    : item.notes,
                              );
                              setState(() {
                                if (_currentDraft != null) {
                                  _currentDraft!.items[index] = newItem;
                                  _productSuggestions = [];
                                }
                              });
                              Navigator.pop(sheetCtx);
                            },
                            child: Text(
                              "Simpan Perubahan",
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editSupplierName() {
    final nameController = TextEditingController(
      text: _currentDraft?.supplierName ?? '',
    );
    final phoneController = TextEditingController(
      text: _currentDraft?.supplierPhone ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    "Edit Supplier",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: "Nama Supplier",
                      labelStyle: GoogleFonts.montserrat(fontSize: 12),
                      isDense: true,
                      prefixIcon: const Icon(Icons.store_outlined, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "No. HP / WhatsApp",
                      labelStyle: GoogleFonts.montserrat(fontSize: 12),
                      isDense: true,
                      prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        setState(() {
                          _currentDraft = ProcurementDraft(
                            action: _currentDraft!.action,
                            supplierName: nameController.text.trim(),
                            supplierPhone: phoneController.text.trim().isEmpty
                                ? _currentDraft!.supplierPhone
                                : phoneController.text.trim(),
                            supplierAddress: _currentDraft!.supplierAddress,
                            transactionDate: _currentDraft!.transactionDate,
                            receiptNumber: _currentDraft!.receiptNumber,
                            items: _currentDraft!.items,
                            subtotal: _currentDraft!.subtotal,
                            discount: _currentDraft!.discount,
                            total: _currentDraft!.total,
                            paymentMethod: _currentDraft!.paymentMethod,
                            confidenceScore: _currentDraft!.confidenceScore,
                          );
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Simpan",
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showConfirmationModal() {
    if (_currentDraft == null || _currentDraft!.items.isEmpty) return;

    // Validation: Check if supplier name is present
    if (_currentDraft?.supplierName == null ||
        _currentDraft!.supplierName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Harap isi nama supplier terlebih dahulu!",
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    double totalPrice = _totalPrice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                "Konfirmasi Pembelian",
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        _currentDraft!.supplierName ?? "Supplier",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "${DateTime.now().toString().split(' ')[0].replaceAll('-', '/')} - ${_transactionCode ?? ''}",
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const Divider(height: 24),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _currentDraft!.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _currentDraft!.items[index];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.displayName,
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "${item.qty.toStringAsFixed(0)} ${item.unit} x ${_formatCurrency(item.unitPrice ?? (item.totalPrice / item.qty))}",
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "Rp ${_formatCurrency(item.totalPrice)}",
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total"),
                          Text(
                            "Rp ${_formatCurrency(totalPrice)}",
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Batal",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _commitTransaction();
                      },
                      child: Text(
                        "Simpan",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _commitTransaction() async {
    if (_currentDraft == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                "Sedang menyimpan transaksi",
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final response = await _apiService.commitTransaction(_currentDraft!);
      if (mounted) Navigator.pop(context);

      if (response.success) {
        if (mounted) _showSuccessDialog(response);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message,
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: $e",
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showSuccessDialog(CommitTransactionResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Transaksi Berhasil!",
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              response.message,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            if (response.invoiceNumber != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "No: ${response.invoiceNumber}",
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
            if (response.newProductsCreated != null &&
                response.newProductsCreated! > 0) ...[
              const SizedBox(height: 8),
              Text(
                "🆕 ${response.newProductsCreated} produk baru ditambahkan",
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainShell()),
                  (route) => false,
                );
              },
              child: Text(
                "Selesai",
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Hasil Scan OCR',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _hasError
          ? _buildErrorState()
          : _buildResultContent(),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Show captured image thumbnail - full width, cropped
        Container(
          width: double.infinity,
          height: 240,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(widget.initialImage, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _dotsAnimation,
          builder: (context, _) {
            final dots = '.' * _dotsAnimation.value;
            final spaces = '   '.substring(0, (3 - _dotsAnimation.value) * 1);
            return Text(
              "Menganalisis gambar$dots$spaces",
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          "Mohon tunggu, sistem sedang membaca nota/struk",
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 20),
            Text(
              "Gagal Menganalisis",
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _processImage,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                "Coba Lagi",
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent() {
    final draft = _currentDraft!;

    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image preview
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: _showImageZoom,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox.expand(
                            child: Image.file(
                              widget.initialImage,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Supplier info card
                _buildSupplierCard(draft),
                const SizedBox(height: 20),

                // Items header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Daftar Barang",
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "${draft.items.length} item",
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Item cards
                ...List.generate(draft.items.length, (index) {
                  return _buildItemCard(index, draft.items[index]);
                }),

                // Discount if available
                if (draft.discount != null && draft.discount! > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Diskon",
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade600,
                        ),
                      ),
                      Text(
                        "- Rp ${_formatCurrency(draft.discount!)}",
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 80), // Space for bottom bar
              ],
            ),
          ),
        ),

        // Bottom bar with total and save button
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildSupplierCard(ProcurementDraft draft) {
    return GestureDetector(
      onTap: _editSupplierName,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Supplier",
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    draft.supplierName ?? "Tap untuk isi nama supplier",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: draft.supplierName != null
                          ? AppColors.textPrimary
                          : Colors.grey.shade400,
                    ),
                  ),
                  if (draft.supplierPhone != null &&
                      draft.supplierPhone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          draft.supplierPhone!,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (draft.receiptNumber != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      "No. ${draft.receiptNumber}",
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(int index, ExtractedItem item) {
    return GestureDetector(
      onTap: () => _showEditItemSheet(index, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (item.unitPrice ?? 0) > 0
                        ? "${item.qty.toStringAsFixed(0)} ${item.unit} x ${_formatCurrency(item.unitPrice ?? 0)}"
                        : "${item.qty.toStringAsFixed(0)} ${item.unit}",
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (item.notes != null && item.notes!.isNotEmpty)
                    Text(
                      item.notes!,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Rp ${_formatCurrency(item.totalPrice)}",
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Total",
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    "Rp ${_formatCurrency(_currentDraft?.total ?? _totalPrice)}",
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _showConfirmationModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Simpan",
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
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

    String rawText = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (rawText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = double.parse(rawText);

    String newText = value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
