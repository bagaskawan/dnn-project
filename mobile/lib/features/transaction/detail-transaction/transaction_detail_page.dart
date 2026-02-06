import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_service.dart';
import '../../home/home_view_model.dart';

class TransactionDetailPage extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  final ApiService _apiService = ApiService();
  List<TransactionItem> _items = [];
  bool _isLoadingItems = false;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    // If transaction already has items (from mock data), use them
    if (widget.transaction.items.isNotEmpty) {
      setState(() {
        _items = widget.transaction.items;
      });
      return;
    }

    // Otherwise fetch from API using transaction ID
    if (widget.transaction.id.isEmpty) return;

    setState(() {
      _isLoadingItems = true;
    });

    try {
      final detail = await _apiService.getTransactionDetail(
        widget.transaction.id,
      );
      if (detail != null) {
        setState(() {
          _items = detail.items
              .map(
                (apiItem) => TransactionItem(
                  name: apiItem.variant != null
                      ? '${apiItem.productName} (${apiItem.variant})'
                      : apiItem.productName,
                  quantity: apiItem.qty.toInt(),
                  unit: apiItem.unit,
                  price: apiItem.unitPrice.toInt(),
                ),
              )
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching transaction items: $e');
    } finally {
      setState(() {
        _isLoadingItems = false;
      });
    }
  }

  // Getter for easier access
  Transaction get transaction => widget.transaction;

  @override
  Widget build(BuildContext context) {
    final isPengadaan = transaction.type == TransactionType.pengadaan;
    // Status Colors
    final statusColor = isPengadaan
        ? AppColors.boxSecondBack
        : AppColors
              .boxThird; // Green for Pengadaan (Supplies In), Red for Penjualan (Sales Out) - Wait, previous logic was different?
    // User request: "Status Transaksi (IN/OUT) dengan warna berbeda (Hijau/Merah)." & Image shows "OUT Penjualan" in Red.
    // In TransactionPage: Pengadaan = south_west (In), Color = boxSecondBack (Green-ish). Penjualan = north_east (Out), Color = boxThird (Red-ish).
    // So: Pengadaan (IN) -> Green, Penjualan (OUT) -> Red.

    final statusText = isPengadaan ? "[ IN ] PENGADAAN" : "[ OUT ] PENJUALAN";
    final statusIcon = isPengadaan ? Icons.arrow_downward : Icons.arrow_upward;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Detail Transaksi',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Floating Receipt Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Receipt Header (Status & Meta)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: isPengadaan
                          ? Colors.green.shade50
                          : const Color(0xFFFEF2F2), // Custom tints
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 8),
                          Text(
                            statusText,
                            style: GoogleFonts.inter(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'TOTAL AMOUNT',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rp ${_formatNumber(transaction.amount.toInt())}',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1A1A1A), // Dark Charcoal
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '#${transaction.invoiceNumber}',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6B7280), // Soft Grey
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildDivider(),

                    // 2. Info Section & Badge
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PELANGGAN', // or KONTAK
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade400,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),

                              GestureDetector(
                                onTap: () => _showCustomerContactModal(context),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.storefront,
                                      size: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      transaction.name,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF1A1A1A),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.info_outline,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 3. Itemized List Section
                    // Only show title if there are items, but design implies always structure
                    if (_isLoadingItems) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Column(
                          children: List.generate(
                            3,
                            (index) => _buildItemSkeletonRow(),
                          ),
                        ),
                      ),
                    ] else if (_items.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: _items
                              .map((item) => _buildItem(item))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    _buildSolidDivider(),

                    // 4. Receipt Footer
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMenuButton(
                  icon: Icons.ios_share,
                  label: 'Share',
                  color: Colors.white,
                  iconColor: const Color(0xFF1A1A1A),
                  onTap: () {
                    // TODO: Implement share functionality
                  },
                ),
                const SizedBox(width: 40),
                _buildMenuButton(
                  icon: Icons.print_rounded,
                  label: 'Print PDF',
                  color: const Color(0xFFEF4444),
                  iconColor: Colors.white,
                  onTap: () {
                    // TODO: Implement print functionality
                  },
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(TransactionItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.quantity} ${item.unit} × Rp ${_formatNumber(item.price)}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (item.conversionNote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 12,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.conversionNote!,
                          style: GoogleFonts.inter(
                            color: Colors.red.shade400,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Text(
            "Rp " + _formatNumber(item.subtotal),
            style: GoogleFonts.inter(
              color: const Color(0xFF1A1A1A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 0,
      ), // Full width divider? Image shows inset.
      child: Row(
        children: List.generate(
          150 ~/ 5,
          (index) => Expanded(
            child: Container(
              color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade200,
              height: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolidDivider() {
    return const Divider(color: Color(0xFFF3F4F6), thickness: 1, height: 1);
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String _formatDate(DateTime date) {
    // Requires intl package, but user didn't ask to add it. I'll use simple formatting or assume user has it.
    // If intl not available, manual format.
    // User requested "24 Oct 2023" format in image.
    // Since I can't easily check for intl dependency right now without `pubspec`, I'll use basic manual map if needed or just `day month year`.
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showCustomerContactModal(BuildContext context) {
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
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.storefront,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.type == TransactionType.pengadaan
                              ? "Supplier Info"
                              : "Customer Info",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          transaction.name,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildContactItem(
                Icons.phone_rounded,
                "Nomor Telepon",
                transaction.customerPhone,
                Colors.green.shade600,
                bgColor: Colors.green.shade50,
              ),
              const SizedBox(height: 16),
              _buildContactItem(
                Icons.location_on_rounded,
                "Alamat",
                transaction.customerAddress,
                Colors.red.shade600,
                bgColor: Colors.red.shade50,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    "Tutup",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value,
    Color iconColor, {
    Color? bgColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildItemSkeletonRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 13,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
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
      ),
    );
  }
}
