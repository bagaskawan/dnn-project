import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_service.dart';

class SaleFormPage extends StatefulWidget {
  const SaleFormPage({super.key});

  @override
  State<SaleFormPage> createState() => _SaleFormPageState();
}

class _SaleFormPageState extends State<SaleFormPage> {
  final List<Map<String, dynamic>> _items = [];
  final ApiService _apiService = ApiService();

  // Customer autocomplete state
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final FocusNode _customerFocusNode = FocusNode();
  List<ContactItem> _allCustomers = [];
  List<ContactItem> _filteredCustomers = [];
  ContactItem? _selectedCustomerContact;
  bool _isNewCustomer = false;
  bool _showSuggestions = false;

  double get _total =>
      _items.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _customerFocusNode.addListener(() {
      if (!_customerFocusNode.hasFocus) {
        // Delay to allow tap on suggestion item
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showSuggestions = false);
        });
      }
    });
  }

  Future<void> _fetchCustomers() async {
    final customers = await _apiService.getContacts(type: 'CUSTOMER');
    if (mounted) {
      setState(() {
        _allCustomers = customers;
      });
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerFocusNode.dispose();
    super.dispose();
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = [];
        _showSuggestions = false;
        _isNewCustomer = false;
        _selectedCustomerContact = null;
      } else {
        _filteredCustomers = _allCustomers
            .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
        _showSuggestions = true;
        // If no exact match found, it's a new customer
        final exactMatch = _allCustomers.any(
          (c) => c.name.toLowerCase() == query.toLowerCase(),
        );
        if (!exactMatch) {
          _isNewCustomer = true;
          _selectedCustomerContact = null;
        }
      }
    });
  }

  void _onCustomerSelected(ContactItem customer) {
    setState(() {
      _customerNameController.text = customer.name;
      _selectedCustomerContact = customer;
      _isNewCustomer = false;
      _showSuggestions = false;
      _customerPhoneController.text = customer.phone ?? '';
    });
    _customerFocusNode.unfocus();
  }

  Future<void> _showProductSearch() async {
    final existingIds = _items.map((e) => e['id'].toString()).toList();
    final result = await showSearch(
      context: context,
      delegate: ProductSearchDelegate(
        apiService: _apiService,
        existingIds: existingIds,
      ),
    );

    if (result != null) {
      setState(() {
        // Check if item already exists
        final existingIndex = _items.indexWhere(
          (item) => item['id'] == result['id'],
        );

        if (existingIndex >= 0) {
          _items[existingIndex]['quantity']++;
        } else {
          _items.add({
            'id': result['id'],
            'name': result['name'] ?? 'Produk',
            'stock':
                result['stock'] ??
                0, // Need to implement get product detail to get real stock if search doesn't return it
            'unit': result['unit'] ?? 'pcs',
            'quantity': 1,
            'price': _parsePrice(
              result['latest_selling_price'] ?? result['price'],
            ),
          });
        }
      });
    }
  }

  double _parsePrice(dynamic price) {
    if (price is int) return price.toDouble();
    if (price is double) return price;
    if (price is String) return double.tryParse(price) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Form Barang',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerInput(),
                  const SizedBox(height: 24),
                  if (_items.isEmpty)
                    Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Belum ada barang dipilih",
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._items.asMap().entries.map((entry) {
                      return _buildDismissibleItem(entry.key, entry.value);
                    }),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 100,
        ), // Height of bottom bar + margin
        child: FloatingActionButton(
          onPressed: _showProductSearch,
          backgroundColor: AppColors.primary,
          elevation: 4,
          tooltip: 'Tambah Barang',
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCustomerInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                // Customer Name Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _customerNameController,
                    focusNode: _customerFocusNode,
                    onChanged: _filterCustomers,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari atau ketik nama pelanggan baru',
                      hintStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Colors.grey.shade400,
                        size: 22,
                      ),
                      suffixIcon: _customerNameController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey.shade400,
                                size: 18,
                              ),
                              onPressed: () {
                                _customerNameController.clear();
                                _filterCustomers('');
                                _customerFocusNode.requestFocus();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                // Phone Input (always visible)
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _customerPhoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'No. HP Pelanggan (opsional)',
                      hintStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: Colors.grey.shade400,
                        size: 22,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Suggestions Dropdown (Overlay)
            if (_showSuggestions && _filteredCustomers.isNotEmpty)
              Positioned(
                top: 56, // Height of the search input + small margin
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _filteredCustomers.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              customer.initial,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            customer.name,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: customer.phone != null
                              ? Text(
                                  customer.phone!,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                )
                              : null,
                          onTap: () => _onCustomerSelected(customer),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDismissibleItem(int index, Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('item_${item['id']}_$index'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 28,
          ),
        ),
        onDismissed: (direction) {
          setState(() {
            _items.removeAt(index);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item['name']} dihapus'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: _buildItemCard(index, item),
      ),
    );
  }

  Widget _buildItemCard(int index, Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Name and Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unit: ${item['unit']}',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Rp ${_formatNumber((item['price'] * item['quantity']).toInt())}',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Controls Row: Unit and Quantity
          Row(
            children: [
              // Unit Display (Simplification: Just text for now, assuming unit from DB)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['unit'],
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              // Quantity Controls
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove,
                      onTap: () {
                        if (item['quantity'] > 1) {
                          setState(() {
                            _items[index]['quantity']--;
                          });
                        }
                      },
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 40),
                      alignment: Alignment.center,
                      child: Text(
                        '${item['quantity']}',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.add,
                      onTap: () {
                        setState(() {
                          _items[index]['quantity']++;
                        });
                      },
                      isPrimary: true,
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

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isPrimary ? Colors.white : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rp ${_formatNumber(_total.toInt())}',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Save Button
          Expanded(
            child: GestureDetector(
              onTap: _saveForm,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Simpan',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveForm() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih barang dulu!')));
      return;
    }

    final customerName = _customerNameController.text.trim();

    // If new customer with a name, create the contact first
    if (_isNewCustomer && customerName.isNotEmpty) {
      final contactData = {
        'name': customerName,
        'type': 'CUSTOMER',
        if (_customerPhoneController.text.trim().isNotEmpty)
          'phone': _customerPhoneController.text.trim(),
      };
      await _apiService.createContact(contactData);
    }

    final itemSummary = _items
        .map((item) => '${item['name']} x${item['quantity']} ${item['unit']}')
        .join(', ');

    final saleData = {
      'customer': customerName.isNotEmpty ? customerName : 'Pelanggan Umum',
      'items': List<Map<String, dynamic>>.from(_items),
      'total': _total,
      'summary': itemSummary,
    };

    if (mounted) Navigator.pop(context, saleData);
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}

class ProductSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  final ApiService apiService;
  final List<String> existingIds;

  ProductSearchDelegate({required this.apiService, required this.existingIds});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  String _formatStock(dynamic stockVal) {
    if (stockVal == null) return '0';
    double stock = 0.0;
    if (stockVal is int) {
      stock = stockVal.toDouble();
    } else if (stockVal is double) {
      stock = stockVal;
    } else {
      stock = double.tryParse(stockVal.toString()) ?? 0.0;
    }

    if (stock == stock.toInt()) {
      return stock.toInt().toString();
    } else {
      return stock.toString().replaceAll('.', ',');
    }
  }

  String _formatPrice(dynamic priceVal) {
    if (priceVal == null) return "0";
    double price = 0.0;
    if (priceVal is num) {
      price = priceVal.toDouble();
    } else {
      price = double.tryParse(priceVal.toString()) ?? 0.0;
    }

    return price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  Widget _buildSearchResults() {
    // Return all products when query is empty, assuming backend handles empty query by returning default items
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: apiService.searchProducts(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonLoading();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Produk tidak ditemukan"));
        }

        final results = snapshot.data!
            .where((product) => !existingIds.contains(product['id']))
            .toList();

        if (results.isEmpty) {
          return const Center(child: Text("Produk tidak ditemukan"));
        }

        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: Colors.grey.shade200),
          itemBuilder: (context, index) {
            final product = results[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: Text(
                product['name'] ?? 'Produk',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                "Stok: ${_formatStock(product['stock'])} ${product['unit'] ?? ''}",
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              trailing: Text(
                "Rp ${_formatPrice(product['latest_selling_price'])}",
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              onTap: () {
                close(context, product);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.separated(
      itemCount: 8,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          title: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 16,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          subtitle: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 12,
              width: 80,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          trailing: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 16,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      },
    );
  }
}
