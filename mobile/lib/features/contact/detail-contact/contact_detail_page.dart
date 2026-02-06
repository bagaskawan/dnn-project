import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_service.dart';
import 'widgets/edit_contact_modal.dart';
import 'widgets/transaction_detail_modal.dart';

class ContactDetailPage extends StatefulWidget {
  final Map<String, dynamic> contact;

  const ContactDetailPage({super.key, required this.contact});

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage> {
  late Map<String, dynamic> _contact;
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<TransactionListItem> _transactions = [];
  Map<String, dynamic> _stats = {'count': 0, 'total_amount': 0.0};

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    final contactId = _contact['id'];

    try {
      final results = await Future.wait([
        _apiService.getTransactions(contactId: contactId, limit: 50),
        _apiService.getContactStats(contactId),
      ]);

      if (mounted) {
        setState(() {
          _transactions = results[0] as List<TransactionListItem>;
          if (results[1] != null) {
            _stats = results[1] as Map<String, dynamic>;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching contact detail data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPelanggan = _contact['type'] == 'pelanggan';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            // Content with different background
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: Column(
                    children: [
                      // Profile Info (No Card)
                      // Profile Info (No Card)
                      _isLoading
                          ? _buildContactInfoSkeleton()
                          : _buildProfileInfo(context, isPelanggan),
                      const SizedBox(height: 24),
                      // Stats Cards
                      _isLoading ? _buildStatsSkeleton() : _buildStatsCards(),
                      const SizedBox(height: 28),
                      // Transaction History
                      _buildTransactionHistory(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 24, 24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Detail Kontak',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, bool isPelanggan) {
    final name = _contact['name'] ?? 'Unknown';
    final phone = _contact['phone'] ?? '-';
    final address = _contact['address'] ?? '-';

    return Column(
      children: [
        // Tag (above name, smaller)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isPelanggan
                ? AppColors.boxThird.withOpacity(0.1)
                : AppColors.boxSecondBack.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isPelanggan ? 'PELANGGAN' : 'SUPPLIER',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isPelanggan ? AppColors.boxThird : AppColors.boxSecondBack,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 18),
        // Name
        // Name with Edit Button
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showEditContactModal(context),
              child: const Icon(
                Icons.edit_outlined,
                size: 20,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Address
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                address,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Phone number with copy button
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 6),
            Text(
              phone,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            if (phone != '-') ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _copyToClipboard(context, phone),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),

        // Action Buttons (like tab buttons with separator)
        _buildActionButtons(phone),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Nomor berhasil disalin',
          style: GoogleFonts.montserrat(fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildActionButtons(String phone) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _launchCall(phone),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Call',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 20, color: Colors.grey.shade300),
          GestureDetector(
            onTap: () => _launchWhatsApp(phone),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: AppColors.boxSecondBack,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'WhatsApp',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.boxSecondBack,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final count = _stats['count'] ?? 0;
    final totalAmount = _stats['total_amount'] ?? 0;

    // Format total amount to short string (e.g. 4.5jt) logic could be complex,
    // but here we just use the formatter or simple abbreviation for now.
    // For simplicity let's use full format or simple 'jt' logic if needed.
    // Let's use standard formatting.
    String amountStr = 'Rp ${_formatNumber(totalAmount.toInt())}';

    // If > 1 million, maybe make it shorter? e.g. 4.5jt
    if (totalAmount >= 1000000) {
      double inMillions = totalAmount / 1000000;
      amountStr = 'Rp ${inMillions.toStringAsFixed(1)}jt';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('${count}x', 'Transaksi')),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(child: _buildStatItem(amountStr, 'Total Nominal')),
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
            fontSize: 18,
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

  Widget _buildTransactionHistory() {
    if (_isLoading) {
      return _buildSkeletonTransactionHistory();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Transaksi',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Belum ada transaksi',
                style: GoogleFonts.montserrat(color: Colors.grey),
              ),
            ),
          )
        else
          ...List.generate(_transactions.length, (index) {
            return Column(
              children: [
                const SizedBox(height: 8),
                _buildTransactionItem(_transactions[index]),
                const SizedBox(height: 8),
                if (index < _transactions.length - 1)
                  Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 8),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionListItem tx) {
    // Parse date string
    // Format: "2026-01-20 10:23:00" (approx)
    DateTime date;
    try {
      date = DateTime.parse(
        tx.transactionDate,
      ); // format might vary, transactionDate is string here
    } catch (e) {
      date = DateTime.now();
    }

    final dateStr =
        '${date.day} ${_getMonthName(date.month)} ${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    // Determining transaction name.
    // TransactionListItem has invoice_number but logic for name like "Pembelian Stok Ayam"
    // isn't explicitly in the item unless we derive it or use invoice number.
    // The previous mock used descriptive names.
    // For now, let's use "Transaksi #${tx.invoiceNumber} - ${tx.type}"
    // Or if `type` is OUT -> Penjualan, IN -> Pembelian

    String txName = tx.type == 'OUT' ? 'Penjualan' : 'Pembelian';
    txName += ' #${tx.invoiceNumber}';

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => TransactionDetailModal(transactionId: tx.id),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.transparent, // Ensure hit test works
        child: Row(
          children: [
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txName,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            // Amount only (no status)
            Text(
              'Rp ${_formatNumber(tx.totalAmount.toInt())}',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.boxSecondBack, // Green color
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSkeleton() {
    return Column(
      children: [
        // Badge skeleton
        Container(
          width: 80,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 16),
        // Name skeleton
        Container(
          width: 200,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        // Address skeleton
        Container(
          width: 250,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 150,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 24),
        // Buttons skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 120,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 24,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 24,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Skeleton
        Container(
          width: 150,
          height: 20,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        ...List.generate(5, (index) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name skeleton
                          Container(
                            width: 150,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Date skeleton
                          Container(
                            width: 100,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Amount skeleton
                    Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (index < 4) Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 8),
            ],
          );
        }),
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
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  Future<void> _launchCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    try {
      if (!await launchUrl(url)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching call: $e');
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    // Basic sanitization: remove non-digits
    var cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    // If starts with 0, replace with 62 (Indonesia specific, common in this context)
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }

    final Uri url = Uri.parse('https://wa.me/$cleanPhone');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  void _showEditContactModal(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditContactModal(contact: _contact),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _contact = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kontak berhasil diperbarui',
            style: GoogleFonts.montserrat(fontSize: 13),
          ),
          backgroundColor: AppColors.boxSecondBack,
        ),
      );
    }
  }
}
