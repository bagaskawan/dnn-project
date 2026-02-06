import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/services/api_service.dart';

class EditContactModal extends StatefulWidget {
  final Map<String, dynamic> contact;

  const EditContactModal({super.key, required this.contact});

  @override
  State<EditContactModal> createState() => _EditContactModalState();
}

class _EditContactModalState extends State<EditContactModal> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact['name']);
    _phoneController = TextEditingController(text: widget.contact['phone']);
    _addressController = TextEditingController(text: widget.contact['address']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
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
              'Edit Kontak',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField('Nama', _nameController),
            const SizedBox(height: 16),
            _buildTextField(
              'Nomor Telepon',
              _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField('Alamat', _addressController, maxLines: 3),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
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
      ),
    );
  }

  Future<void> _saveContact() async {
    setState(() => _isLoading = true);

    final updatedData = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
      'notes': widget.contact['notes'] ?? '', // Preserve notes
    };

    final result = await _apiService.updateContact(
      widget.contact['id'],
      updatedData,
    );

    setState(() => _isLoading = false);

    if (result != null) {
      if (mounted) {
        // Return updated data in the format expected by ContactDetailPage
        Navigator.pop(context, {
          'id': result.id,
          'name': result.name,
          'type': widget.contact['type'], // Preserve type
          'phone': result.phone ?? '-',
          'address': result.address ?? '-',
          'notes': result.notes ?? '',
          // Re-calculate initial if needed or let ContactItem do it (but ContactDetailPage uses map)
          // For simple display, let's look at how ContactDetailPage derived initial?
          // It seems it doesn't use initial in detail page, only contact page list uses it.
          // Detail page header doesn't show avatar initial.
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memperbarui kontak',
              style: GoogleFonts.montserrat(fontSize: 13),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
