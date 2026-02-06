import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/api_service.dart';

class AddContactModal extends StatefulWidget {
  const AddContactModal({super.key});

  @override
  State<AddContactModal> createState() => _AddContactModalState();
}

class _AddContactModalState extends State<AddContactModal> {
  String _selectedType = 'pelanggan'; // 'pelanggan' or 'supplier'
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoading = false;
  final _apiService = ApiService();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle Bar (Optional, keeps it draggable looking)
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
          const SizedBox(height: 24),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'Tambah Kontak Baru',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Nama Lengkap'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Masukkan nama lengkap',
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Tipe Kontak'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeOption(
                          label: 'Pelanggan',
                          value: 'pelanggan',
                          color: AppColors.boxThird,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeOption(
                          label: 'Supplier',
                          value: 'supplier',
                          color: AppColors.boxSecondBack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Nomor Telepon / WhatsApp'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _phoneController,
                    hint: 'Masukkan nomor telepon',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      PhoneInputFormatter(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Alamat Lengkap'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _addressController,
                    hint: 'Masukkan alamat lengkap',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Catatan Tambahan (opsional)'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _noteController,
                    hint: 'Tambahkan catatan...',
                    maxLines: 3,
                  ),
                  const SizedBox(
                    height: 100,
                  ), // Space for scrolling under floating button
                ],
              ),
            ),
          ),
          // Floating Button Area
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
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
                    ? Text(
                        'Menyimpan ...',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Simpan Kontak',
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
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
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

  Widget _buildTypeOption({
    required String label,
    required String value,
    required Color color,
  }) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = value;
        });
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? color : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama kontak wajib diisi')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Map 'pelanggan'/'supplier' to 'CUSTOMER'/'SUPPLIER'
    final type = _selectedType == 'pelanggan' ? 'CUSTOMER' : 'SUPPLIER';

    final payload = {
      'name': _nameController.text.trim(),
      'type': type,
      'phone': _phoneController.text
          .trim(), // Send formatted or clean? Usually backend wants clean, but let's send what user sees for now or clean it.
      'address': _addressController.text.trim(),
      'notes': _noteController.text.trim(),
    };

    // Clean phone number for backend if necessary, or keep format
    // For now, sending as is, database is varchar.

    print("Submitting Contact: $payload");

    final result = await _apiService.createContact(payload);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (result != null) {
        Navigator.pop(context, result); // Return the new contact object
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kontak berhasil disimpan'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan kontak'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;

    // Remove all non-digits to get raw numbers
    String cleanText = newText.replaceAll(RegExp(r'\D'), '');

    // Allow empty
    if (cleanText.isEmpty) {
      return newValue;
    }

    // 1. Force start with '0'
    // If the user types a non-zero as the first digit, prepend '0'.
    if (!cleanText.startsWith('0')) {
      cleanText = '0$cleanText';
    }

    // 2. Add dashes every 4 digits
    final buffer = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write('-');
      }
      buffer.write(cleanText[i]);
    }

    final formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
