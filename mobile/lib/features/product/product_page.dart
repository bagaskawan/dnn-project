import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import 'detail-product/product_detail_page.dart';
import 'add-product/add_product_modal.dart';

/// Full ProductPage with bottom nav (for standalone use)
class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: ProductContent());
  }
}

/// ProductContent for use inside MainShell
class ProductContent extends StatefulWidget {
  const ProductContent({super.key});

  @override
  State<ProductContent> createState() => _ProductContentState();
}

class _ProductContentState extends State<ProductContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Sample product data
  final List<Map<String, dynamic>> _products = [
    {
      'name': 'Beras Premium 5kg',
      'sku': 'BRS-001',
      'price': 75000,
      'stock': 50,
      'unit': 'pcs',
      'initial': 'BP',
    },
    {
      'name': 'Gula Pasir 1kg',
      'sku': 'GLA-002',
      'price': 15000,
      'stock': 3,
      'unit': 'pcs',
      'initial': 'GP',
    },
    {
      'name': 'Minyak Goreng 2L',
      'sku': 'MYK-003',
      'price': 32000,
      'stock': 0,
      'unit': 'botol',
      'initial': 'MG',
    },
    {
      'name': 'Kopi Sachet',
      'sku': 'KPI-004',
      'price': 2500,
      'stock': 120,
      'unit': 'pcs',
      'initial': 'KS',
    },
    {
      'name': 'Teh Celup',
      'sku': 'TEH-005',
      'price': 5000,
      'stock': 5,
      'unit': 'box',
      'initial': 'TC',
    },
    {
      'name': 'Sabun Mandi',
      'sku': 'SBN-006',
      'price': 8000,
      'stock': 25,
      'unit': 'pcs',
      'initial': 'SM',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredProducts {
    List<Map<String, dynamic>> filtered = _products;

    // Filter by tab (0: Menipis, 1: Semua, 2: Habis)
    if (_tabController.index == 0) {
      filtered = filtered
          .where((p) => p['stock'] > 0 && p['stock'] <= 5)
          .toList();
    } else if (_tabController.index == 2) {
      filtered = filtered.where((p) => p['stock'] == 0).toList();
    }

    // Filter by search
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((p) {
        final name = p['name'].toString().toLowerCase();
        final sku = p['sku'].toString().toLowerCase();
        return name.contains(query) || sku.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    _buildSearchAndAction(),
                    Expanded(child: _buildProductList()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Center(
        child: Text(
          'Gudang Barang',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndAction() {
    return Column(
      children: [
        // Search Bar with Add Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau SKU ...',
                      hintStyle: GoogleFonts.montserrat(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Add Button
              GestureDetector(
                onTap: () async {
                  final result = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddProductModal(),
                  );

                  if (result != null && result is Map<String, dynamic>) {
                    setState(() {
                      _products.insert(0, result);
                    });
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Filter Tabs (Menipis, Semua, Habis)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / 3;
                return Stack(
                  children: [
                    // Sliding indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      left: _tabController.index * tabWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: tabWidth,
                        decoration: BoxDecoration(
                          color: _getTabColor(_tabController.index),
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),
                    // Tab labels
                    Row(
                      children: [
                        _buildTabLabel(0, 'Menipis'),
                        _buildTabLabel(1, 'Semua'),
                        _buildTabLabel(2, 'Habis'),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Color _getTabColor(int index) {
    switch (index) {
      case 0: // Menipis
        return Colors.orange;
      case 1: // Semua
        return AppColors.primary;
      case 2: // Habis
        return AppColors.boxThird;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildTabLabel(int index, String label) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tabController.index = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada produk',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductItem(products[index]);
      },
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    final stock = product['stock'] as int;
    final isLowStock = stock > 0 && stock <= 5;
    final isOutOfStock = stock == 0;

    Color stockColor = AppColors.textPrimary;
    Color bgColor = AppColors.primary;
    if (isOutOfStock) {
      stockColor = AppColors.boxThird;
      bgColor = AppColors.boxThird;
    } else if (isLowStock) {
      stockColor = Colors.orange;
      bgColor = Colors.orange;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Product Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  product['initial'],
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: bgColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${product['sku']}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            // Stock Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: stockColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${product['stock']} ${product['unit']}',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: stockColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
