import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';
import '../../models/procurement_draft.dart';

class BuyPage extends StatefulWidget {
  const BuyPage({super.key});

  @override
  State<BuyPage> createState() => _BuyPageState();
}

class _BuyPageState extends State<BuyPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final ApiService _apiService = ApiService();

  // Store current draft for accumulating items
  ProcurementDraft? _currentDraft;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      // Remove old action buttons when user sends new message
      _chatItems.removeWhere((item) => item['type'] == 'action_buttons');
      _chatItems.add({"type": "user_pill", "text": text});
      _chatItems.add({"type": "typing"});
      _messageController.clear();
    });
    _scrollToBottom();

    // Pass current draft as context for follow-up responses
    final draft = await _apiService.parseText(
      text,
      currentDraft: _currentDraft,
    );
    _handleApiResponse(draft);
  }

  void _handleApiResponse(ProcurementDraft? draft) {
    setState(() {
      _chatItems.removeWhere((item) => item['type'] == 'typing');

      if (draft != null) {
        // 1. Update _currentDraft logic
        if (draft.action == 'chat') {
          // No data update for chat action
        } else if (draft.action == 'update' && _currentDraft != null) {
          _currentDraft = _currentDraft!.copyWithUpdatedFields(draft);
        } else if (draft.action == 'append' && _currentDraft != null) {
          _currentDraft = _currentDraft!.copyWithAppendedItems(draft);
        } else if (draft.action == 'delete' && _currentDraft != null) {
          _currentDraft = _currentDraft!.copyWithDeletedItems(draft);
        } else {
          // New transaction or fallback
          _currentDraft = draft;
        }

        // 2. Only show draft card for data-changing actions (NOT for chat/clarification)
        if (_currentDraft != null && draft.action != 'chat') {
          // Keep old draft_card as history (User Request)
          // Add updated draft_card at the end
          _chatItems.add({'type': 'draft_card', 'data': _currentDraft});
        }

        // 3. Show follow-up question
        if (draft.followUpQuestion != null &&
            draft.followUpQuestion!.isNotEmpty) {
          _chatItems.add({
            "type": "system_text",
            "text": draft.followUpQuestion!,
          });

          // 4. Show action buttons if suggested
          if (draft.suggestedActions != null &&
              draft.suggestedActions!.isNotEmpty) {
            _chatItems.add({
              "type": "action_buttons",
              "actions": draft.suggestedActions!,
            });
          }
        }
      } else {
        _chatItems.add({
          "type": "system_text",
          "text": "Maaf, saya gagal memproses pesanan tersebut. Bisa diulangi?",
        });
      }
    });
    _scrollToBottom();
  }

  final List<Map<String, dynamic>> _chatItems = [
    {"type": "date_header", "text": "Hari Ini"},
    {
      "type": "info_card",
      "title": "Selamat datang!",
      "description":
          "Sebelum mulai, aku ingin bantu kamu untuk proses pengadaan barang. Aku akan memproses pesananmu secepat mungkin.",
      "note":
          "Tenang, stok kami selalu update dan harga bersaing untuk mitra setia.",
    },
  ];

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Ambil Foto',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null) {
                      setState(() {
                        _chatItems.add({
                          "type": "user_pill",
                          "text": "[Mengirim Foto Struk...]",
                        });
                        _chatItems.add({"type": "typing"});
                      });
                      _scrollToBottom();
                      final draft = await _apiService.parseImage(
                        File(image.path),
                      );
                      _handleApiResponse(draft);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Pilih dari Galeri',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() {
                        _chatItems.add({
                          "type": "user_pill",
                          "text": "[Mengirim Foto Struk...]",
                        });
                        _chatItems.add({"type": "typing"});
                      });
                      _scrollToBottom();
                      final draft = await _apiService.parseImage(
                        File(image.path),
                      );
                      _handleApiResponse(draft);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
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
          'Pengadaan Barang',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                itemCount: _chatItems.length,
                itemBuilder: (context, index) {
                  final item = _chatItems[index];
                  switch (item['type']) {
                    case 'system_text':
                      return _buildSystemText(item['text']);
                    case 'user_pill':
                      return _buildUserPill(item['text']);
                    case 'typing':
                      return _buildTypingIndicator();
                    case 'draft_card':
                      return _buildDraftCard(item['data'] as ProcurementDraft);
                    case 'date_header':
                      return _buildDateHeader(item['text']);
                    case 'action_buttons':
                      return _buildActionButtons(
                        item['actions'] as List<String>,
                      );
                    default:
                      return const SizedBox();
                  }
                },
              ),
            ),
            // Action buttons are now rendered inline in the chat list
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(List<String> actions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions.map((action) {
          return GestureDetector(
            onTap: () {
              // Send the action label as user message
              _messageController.text = action;
              _sendMessage();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: Text(
                action,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSystemText(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserPill(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.mintGreen,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(0),
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 60,
        height: 36,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dot(AppColors.dark.withOpacity(0.4)),
            const SizedBox(width: 4),
            _dot(AppColors.dark.withOpacity(0.7)),
            const SizedBox(width: 4),
            _dot(AppColors.dark),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesanan...',
                        hintStyle: GoogleFonts.montserrat(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      onSubmitted: (value) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                    onPressed: _showImagePickerOptions,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String text) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildDraftCard(ProcurementDraft draft) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // Supplier & Date
            _buildCompactRow("Supplier", draft.supplierName ?? "-"),
            const SizedBox(height: 4),
            _buildCompactRow("Tanggal", draft.transactionDate.split('T')[0]),

            if (draft.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              // Items list (compact)
              ...draft.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "${item.productName} (${item.qty.toStringAsFixed(0)} ${item.unit})",
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        "Rp ${_formatCurrency(item.totalPrice)}",
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

              // Total
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total",
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    "Rp ${_formatCurrency(draft.totalPrice)}",
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}
