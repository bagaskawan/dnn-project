import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  // Sample conversion rules
  static final List<Map<String, dynamic>> _conversionRules = [
    {'unit': 'Bal', 'qty': 20, 'base': 'Pcs'},
    {'unit': 'Dus', 'qty': 40, 'base': 'Pcs'},
    {'unit': 'Karton', 'qty': 100, 'base': 'Pcs'},
  ];

  // Sample stock ledger
  static final List<Map<String, dynamic>> _stockLedger = [
    {
      'date': DateTime(2026, 1, 20, 10, 30),
      'type': 'IN',
      'qty': 50,
      'balance': 120,
      'note': 'Pembelian dari Supplier A',
    },
    {
      'date': DateTime(2026, 1, 19, 14, 15),
      'type': 'OUT',
      'qty': 10,
      'balance': 70,
      'note': 'Penjualan ke Toko Makmur',
    },
    {
      'date': DateTime(2026, 1, 18, 9, 0),
      'type': 'IN',
      'qty': 30,
      'balance': 80,
      'note': 'Pembelian dari Supplier B',
    },
    {
      'date': DateTime(2026, 1, 15, 11, 20),
      'type': 'OUT',
      'qty': 25,
      'balance': 50,
      'note': 'Penjualan ke Warung Sejahtera',
    },
    {
      'date': DateTime(2026, 1, 20, 10, 30),
      'type': 'IN',
      'qty': 50,
      'balance': 120,
      'note': 'Pembelian dari Supplier A',
    },
    {
      'date': DateTime(2026, 1, 19, 14, 15),
      'type': 'OUT',
      'qty': 10,
      'balance': 70,
      'note': 'Penjualan ke Toko Makmur',
    },
    {
      'date': DateTime(2026, 1, 18, 9, 0),
      'type': 'IN',
      'qty': 30,
      'balance': 80,
      'note': 'Pembelian dari Supplier B',
    },
    {
      'date': DateTime(2026, 1, 15, 11, 20),
      'type': 'OUT',
      'qty': 25,
      'balance': 50,
      'note': 'Penjualan ke Warung Sejahtera',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
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
                  icon: const Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.black,
                  ),
                  onPressed: () => _showConversionRulesModal(context),
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
                    const SizedBox(height: 28),
                    _buildSectionTitle('Informasi Dasar'),
                    const SizedBox(height: 12),
                    _buildBasicInfo(),
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
    );
  }

  Widget _buildProfileInfo() {
    final name = product['name'] ?? 'Unknown';
    final sku = product['sku'] ?? '-';

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
    final stock = product['stock'] ?? 0;
    final unit = product['unit'] ?? 'pcs';
    const sold = 1250; // Mock data

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('$stock $unit', 'Total Stok')),
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
    final price = product['price'] ?? 0;
    final avgCost = product['avg_cost'] ?? 55000; // Mock average cost
    final profit = price - avgCost;
    final unit = product['unit'] ?? 'pcs';

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
          _buildInfoRow('Harga Modal', 'Rp ${_formatNumber(avgCost)}'),
          Divider(color: Colors.grey.shade200, height: 24),
          _buildInfoRow('Laba', 'Rp ${_formatNumber(profit)}'),
          Divider(color: Colors.grey.shade200, height: 24),
          _buildInfoRow('Satuan Dasar', unit),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
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
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      itemCount: _stockLedger.length,
      itemBuilder: (context, index) {
        final entry = _stockLedger[index];
        return Column(
          children: [
            const SizedBox(height: 12),
            _buildLedgerItem(entry),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildLedgerItem(Map<String, dynamic> entry) {
    final isIn = entry['type'] == 'IN';
    final date = entry['date'] as DateTime;
    final color = isIn ? AppColors.boxSecondBack : AppColors.boxThird;

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
                entry['note'] ?? '',
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
                '${date.day} ${_getMonthName(date.month)} ${date.year}',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        // Qty & Balance
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIn ? '+' : '-'}${entry['qty']}',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Sisa: ${entry['balance']}',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
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
