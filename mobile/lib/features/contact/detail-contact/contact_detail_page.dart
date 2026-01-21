import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';

class ContactDetailPage extends StatelessWidget {
  final Map<String, dynamic> contact;

  const ContactDetailPage({super.key, required this.contact});

  // Sample transactions for this contact
  static final List<Map<String, dynamic>> _transactions = [
    {
      'name': 'Pembelian Stok Ayam',
      'type': 'masuk',
      'amount': 2000000,
      'date': DateTime(2026, 1, 20, 10, 23),
      'status': 'PAID',
    },
    {
      'name': 'Penjualan Keripik',
      'type': 'keluar',
      'amount': 150000,
      'date': DateTime(2026, 1, 19, 14, 45),
      'status': 'PENDING',
    },
    {
      'name': 'Pembelian Stok Durian',
      'type': 'masuk',
      'amount': 500000,
      'date': DateTime(2026, 1, 12, 9, 0),
      'status': 'PAID',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isPelanggan = contact['type'] == 'pelanggan';

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
                      _buildProfileInfo(isPelanggan),
                      const SizedBox(height: 24),
                      // Stats Cards
                      _buildStatsCards(),
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

  Widget _buildProfileInfo(bool isPelanggan) {
    final name = contact['name'] ?? 'Unknown';
    final phone = contact['phone'] ?? '';

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
        const SizedBox(height: 8),
        // Name
        Text(
          name,
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        // Action Buttons (like tab buttons with separator)
        _buildActionButtons(phone),
      ],
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('12x', 'Transaksi')),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(child: _buildStatItem('Rp 4.5jt', 'Total Nominal')),
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
            Text(
              'See all',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    // Handle date as either DateTime or String
    String dateStr;
    if (tx['date'] is DateTime) {
      final date = tx['date'] as DateTime;
      dateStr =
          '${date.day} ${_getMonthName(date.month)} ${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      dateStr = tx['date']?.toString() ?? '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['name'],
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
            'Rp ${_formatNumber(tx['amount'])}',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.boxSecondBack, // Green color
            ),
          ),
        ],
      ),
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

  void _launchCall(String phone) {
    debugPrint('Calling: $phone');
  }

  void _launchWhatsApp(String phone) {
    debugPrint('WhatsApp: $phone');
  }
}
