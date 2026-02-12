import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_service.dart';
import 'widgets/edit_product_modal.dart';
import 'widgets/add_stock_modal.dart' hide ThousandSeparatorInputFormatter;

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ApiService _apiService = ApiService();
  late Map<String, dynamic> _product;
  List<ProductHistoryItem> _history = [];
  bool _isLoading = true;
  bool _isDetailLoading = true;
  bool _isRecalculating = false;

  // Sample conversion rules (Tetap mock karena belum ada endpoint khusus)
  static final List<Map<String, dynamic>> _conversionRules = [
    {'unit': 'Bal', 'qty': 20, 'base': 'Pcs'},
    {'unit': 'Dus', 'qty': 40, 'base': 'Pcs'},
    {'unit': 'Karton', 'qty': 100, 'base': 'Pcs'},
  ];

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _fetchHistory();
    _fetchProductDetail();
  }

  Future<void> _fetchProductDetail() async {
    final productId = widget.product['id'];
    if (productId != null) {
      final detail = await _apiService.getProductDetail(productId.toString());
      if (mounted) {
        setState(() {
          if (detail != null) {
            _product = {..._product, ...detail};
          }
          _isDetailLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isDetailLoading = false);
      }
    }
  }

  Future<void> _recalculateProduct() async {
    final productId = widget.product['id'];
    if (productId == null) return;

    setState(() => _isRecalculating = true);

    final result = await _apiService.recalculateProduct(productId.toString());

    if (result != null && result['success'] == true) {
      // Refresh product detail to get updated average_cost
      await _fetchProductDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Harga modal berhasil diperbarui',
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui harga modal'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isRecalculating = false);
    }
  }

  Future<void> _fetchHistory() async {
    final productId = widget.product['id'];
    if (productId != null) {
      final data = await _apiService.getProductHistory(productId.toString());
      if (mounted) {
        setState(() {
          _history = data;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        edgeOffset: 90, // Position indicator below AppBar
        onRefresh: () async {
          await Future.wait([_fetchProductDetail(), _fetchHistory()]);
        },
        child: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Pinned Header (Profile & Stats)
              SliverAppBar(
                backgroundColor: AppColors.background,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
                pinned: true,
                automaticallyImplyLeading: false,
                toolbarHeight: 56,
                title: Text(
                  'Detail Produk',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    onPressed: () => _showActionSheet(context),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(240),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              _buildProfileInfo(),
                              const SizedBox(height: 24),
                              _buildStatsCards(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              // Scrollable Basic Info (Disappears under header)
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // Recalculate Banner (shows only if needs_recalculation is true)
                      // Recalculate Banner (shows only if needs_recalculation is true)
                      if (!_isDetailLoading &&
                          (_product['needs_recalculation'] == true))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildRecalculateBanner(),
                        ),

                      // Set Price Banner (shows if price is 0 or null)
                      if (!_isDetailLoading &&
                          ((_product['latest_selling_price'] ?? 0) == 0 &&
                              (_product['price'] ?? 0) == 0))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildSetPriceBanner(),
                        ),
                      _buildSectionTitle('Informasi Dasar'),
                      const SizedBox(height: 12),
                      _isDetailLoading
                          ? _buildBasicInfoSkeleton()
                          : _buildBasicInfo(),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
              // Sticky "Riwayat Stok" Header
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  child: Container(
                    height: 48,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.centerLeft,
                    child: _buildSectionTitle('Riwayat Stok'),
                  ),
                ),
              ),
            ];
          },
          body: Container(color: Colors.white, child: _buildStockLedger()),
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    final name = _product['name'] ?? 'Unknown';
    final sku = _product['sku'] ?? '-';

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // SKU Tag (above name, smaller)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'SKU: $sku',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            name,
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    // Gunakan data real jika ada di map product, atau mock
    final stock = _product['current_stock'] ?? _product['stock'] ?? 0;
    final unit = _product['base_unit'] ?? _product['unit'] ?? 'pcs';
    final sold = 0; // TODO: Hitung total terjual dari history OUT jika perlu

    // Format stock: show as integer if no decimal, otherwise show with decimal
    String stockStr;
    if (stock is num) {
      stockStr = stock == stock.toInt()
          ? stock.toInt().toString()
          : stock.toString();
    } else {
      stockStr = stock.toString();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('$stockStr', 'Total Stok')),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(child: _buildStatItem('$sold', 'Terjual')),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {bool showEdit = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (showEdit)
          GestureDetector(
            onTap: () {
              // TODO: Edit conversion rules
            },
            child: Text(
              'Edit',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBasicInfo() {
    final price = _product['latest_selling_price'] ?? _product['price'] ?? 0;
    final avgCost = _product['average_cost'] ?? _product['avg_cost'] ?? 0;
    final costPerPcs = _product['cost_per_pcs'] ?? avgCost;
    final profit = (price is num ? price : 0) - (avgCost is num ? avgCost : 0);
    final unit = _product['base_unit'] ?? _product['unit'] ?? 'pcs';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow('Harga Jual Default', 'Rp ${_formatNumber(price)}'),
          Divider(color: Colors.grey.shade200, height: 24),
          _buildInfoRow(
            'Harga Modal (Rata-rata)',
            'Rp ${_formatNumber(avgCost)}',
          ),
          Divider(color: Colors.grey.shade200, height: 24),
          _buildInfoRow('Harga per Pcs', 'Rp ${_formatNumber(costPerPcs)}'),
          Divider(color: Colors.grey.shade200, height: 24),
          _buildInfoRow(
            'Est. Laba',
            'Rp ${_formatNumber(profit)}',
            valueColor: profit >= 0
                ? Colors.green.shade700
                : Colors.red.shade600,
          ),
          Divider(color: Colors.grey.shade200, height: 24),
          _buildInfoRow('Satuan Dasar', unit),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRowSkeleton(),
          Divider(color: Colors.grey.shade200, height: 24),
          _buildInfoRowSkeleton(),
          Divider(color: Colors.grey.shade200, height: 24),
          _buildInfoRowSkeleton(),
          Divider(color: Colors.grey.shade200, height: 24),
          _buildInfoRowSkeleton(),
        ],
      ),
    );
  }

  Widget _buildInfoRowSkeleton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 140,
          height: 13,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Container(
          width: 80,
          height: 13,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecalculateBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harga modal perlu diperbarui',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Data lama belum dinormalisasi ke harga per pcs',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: _isRecalculating ? null : _recalculateProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isRecalculating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Perbarui',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetPriceBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.blue.shade700,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harga jual belum diatur',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Atur harga jual default untuk produk ini',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: () => _showSetPriceModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Set Harga',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSetPriceModal(BuildContext context) {
    final TextEditingController priceController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
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
                  'Set Harga Jual Default',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Harga Jual',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandSeparatorInputFormatter()],
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixText: 'Rp ',
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final priceStr = priceController.text.replaceAll(
                              '.',
                              '',
                            );
                            final price = double.tryParse(priceStr) ?? 0;

                            if (price <= 0) {
                              return;
                            }

                            setStateModal(() => isSaving = true);

                            final updatedData = {
                              'name': _product['name'] ?? '',
                              'latest_selling_price': price,
                              'current_stock':
                                  (_product['current_stock'] ??
                                          _product['stock'] ??
                                          0)
                                      .toDouble(),
                            };
                            final result = await _apiService.updateProduct(
                              _product['id'],
                              updatedData,
                            );

                            if (result != null) {
                              setState(() {
                                _product = {..._product, ...result};
                                // Normalize keys for immediate UI update
                                if (result.containsKey('price')) {
                                  _product['latest_selling_price'] =
                                      result['price'];
                                }
                                if (result.containsKey('cost_per_pcs')) {
                                  _product['cost_per_pcs'] =
                                      result['cost_per_pcs'];
                                }
                                if (result.containsKey('average_cost')) {
                                  _product['average_cost'] =
                                      result['average_cost'];
                                }
                              });
                              // Re-fetch full product detail to get updated computed fields
                              await _fetchProductDetail();
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Harga jual berhasil diatur',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                      ),
                                    ),
                                    backgroundColor: AppColors.boxSecondBack,
                                  ),
                                );
                              }
                            } else {
                              setStateModal(() => isSaving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Gagal mengatur harga',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                      ),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
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
          );
        },
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Edit Produk',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Ubah nama, harga, dan stok',
                style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditProductModal(context);
              },
            ),
            ListTile(
              title: Text(
                'Tambah Stok',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Catat penambahan stok baru',
                style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAddStockModal(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStockModal(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddStockModal(product: _product),
    );

    if (result == true) {
      // Refresh data
      await Future.wait([_fetchProductDetail(), _fetchHistory()]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stok berhasil ditambahkan',
              style: GoogleFonts.montserrat(fontSize: 13),
            ),
            backgroundColor: AppColors.boxSecondBack,
          ),
        );
      }
    }
  }

  void _showEditProductModal(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProductModal(product: _product),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _product = {..._product, ...result};
        // Normalize keys for immediate UI update
        if (result.containsKey('price')) {
          _product['latest_selling_price'] = result['price'];
        }
        if (result.containsKey('cost_per_pcs')) {
          _product['cost_per_pcs'] = result['cost_per_pcs'];
        }
        if (result.containsKey('average_cost')) {
          _product['average_cost'] = result['average_cost'];
        }
      });
      // Re-fetch full product detail to get updated computed fields
      await _fetchProductDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Produk berhasil diperbarui',
              style: GoogleFonts.montserrat(fontSize: 13),
            ),
            backgroundColor: AppColors.boxSecondBack,
          ),
        );
      }
    }
  }

  void _showConversionRulesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Catatan (Konversi)',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: Edit conversion rules
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Edit',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...List.generate(_conversionRules.length, (index) {
              final rule = _conversionRules[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '1 ${rule['unit']} = ${rule['qty']} ${rule['base']}',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStockLedger() {
    if (_isLoading) {
      return _buildHistorySkeleton();
    }

    if (_history.isEmpty) {
      return Stack(
        children: [
          ListView(physics: const AlwaysScrollableScrollPhysics()),
          Center(
            child: Text(
              "Belum ada riwayat transaksi",
              style: GoogleFonts.montserrat(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final entry = _history[index];
        return Column(
          children: [
            const SizedBox(height: 12),
            _buildHistoryItem(entry),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildHistoryItem(ProductHistoryItem entry) {
    final isIn = entry.type == 'IN';
    final color = isIn ? AppColors.boxSecondBack : AppColors.boxThird;

    // Parse date safely
    DateTime date;
    try {
      date = DateTime.parse(entry.date);
    } catch (_) {
      date = DateTime.now();
    }

    // Determine subtitle based on IN (Supplier) or OUT (Customer)
    String contactLabel;
    if (isIn) {
      contactLabel = "Dari: ${entry.contactName ?? 'Uknown Supplier'}";
    } else {
      contactLabel = "Ke: ${entry.contactName ?? 'Unknown Customer'}";
    }

    return Row(
      children: [
        // Type Badge
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              isIn ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contactLabel,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${date.day} ${_getMonthName(date.month)} ${date.year} • ${entry.invoiceNumber ?? '-'}',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        // Qty & Price
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIn ? '+' : ''}${_formatNumber(entry.qtyChange.toInt())}',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (isIn && entry.priceAtMoment != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '@ Rp ${_formatNumber(entry.priceAtMoment!.toInt())}',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistorySkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Column(
          children: [
            const SizedBox(height: 12),
            _buildHistorySkeletonItem(),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildHistorySkeletonItem() {
    return Row(
      children: [
        // Type Badge skeleton
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        // Info skeleton
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact name skeleton
              Container(
                width: 150,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              // Date & invoice skeleton
              Container(
                width: 180,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        // Qty & Price skeleton
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 40,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 70,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(num number) {
    return number.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
