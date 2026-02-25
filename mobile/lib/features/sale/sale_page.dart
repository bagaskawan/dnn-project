import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import 'form-sale/sale_form_page.dart';
import '../../core/services/api_service.dart';
import '../../models/sale_draft.dart';
import '../../models/procurement_draft.dart';

class SalePage extends StatefulWidget {
  const SalePage({super.key});

  @override
  State<SalePage> createState() => _SalePageState();
}

class _SalePageState extends State<SalePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();

  SaleDraft? _currentDraft;
  bool _isTyping = false;

  final List<Map<String, dynamic>> _chatItems = [
    {
      "type": "system_text",
      "text":
          "Halo, Bos! 👋\n\nSaya asisten penjualanmu. Mau catat transaksi apa hari ini? Contoh: \"Jual Kopi 5pcs\"",
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _chatItems.add({"type": "user_pill", "text": text});
      _isTyping = true;
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      // Call API
      final response = await _apiService.parseSaleText(text, _currentDraft);

      if (mounted) {
        setState(() {
          _isTyping = false;
          if (response != null) {
            _currentDraft = response;

            // Add Info Card if items exist
            if (_currentDraft!.items.isNotEmpty) {
              _chatItems.add({"type": "info_card", "draft": _currentDraft});
            }

            // Add AI Text Response
            if (_currentDraft!.followUpQuestion != null) {
              _chatItems.add({
                "type": "system_text",
                "text": _currentDraft!.followUpQuestion,
                "suggestions": _currentDraft!.suggestedActions,
              });
            }
          } else {
            _chatItems.add({
              "type": "system_text",
              "text": "Maaf bos, sistem lagi gangguan. Coba lagi ya!",
            });
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _chatItems.add({"type": "system_text", "text": "Error: $e"});
        });
      }
    }
  }

  Future<void> _handleSuggestion(String action) async {
    if (action == 'Simpan') {
      await _commitSale();
    } else if (action == 'Edit') {
      _openSaleForm(); // Use form for editing
    } else {
      _sendMessage(action);
    }
  }

  Future<void> _commitSale() async {
    if (_currentDraft == null) return;

    setState(() {
      _chatItems.add({"type": "user_pill", "text": "Simpan"});
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final result = await _apiService.commitSale(_currentDraft!);

      if (mounted) {
        setState(() {
          _isTyping = false;
          if (result != null && result['success'] == true) {
            _chatItems.add({
              "type": "system_text",
              "text":
                  "✅ Sip! Penjualan berhasil disimpan.\nNo. Invoice: ${result['invoice_number']}\n\nAda yang lain, Bos?",
            });
            _currentDraft = null; // Reset draft
          } else {
            _chatItems.add({
              "type": "system_text",
              "text":
                  "Gagal menyimpan: ${result?['message'] ?? 'Unknown error'}",
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _chatItems.add({
            "type": "system_text",
            "text": "Gagal menyimpan: $e",
          });
        });
      }
    }
    _scrollToBottom();
  }

  Future<void> _openSaleForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SaleFormPage()),
    );

    if (result != null && result is Map<String, dynamic>) {
      _handleFormResult(result);
    }
  }

  void _handleFormResult(Map<String, dynamic> result) {
    final items = (result['items'] as List).map((item) {
      return ExtractedItem(
        productName: item['name'],
        qty: (item['quantity'] as num).toDouble(),
        unit: item['unit'],
        unitPrice: (item['price'] as num).toDouble(),
        totalPrice:
            (item['price'] as num).toDouble() *
            (item['quantity'] as num).toDouble(),
        notes: 'Input from Form',
      );
    }).toList();

    final newDraft = SaleDraft(
      action: 'update',
      customerName: result['customer'] ?? 'Pelanggan Umum',
      items: items,
      total: (result['total'] as num).toDouble(),
      followUpQuestion:
          "Data dari form sudah masuk bos! Total Rp ${_formatNumber(result['total'])}. Mau disimpan?",
      suggestedActions: ['Simpan', 'Edit', 'Batal'],
    );

    setState(() {
      _currentDraft = newDraft;
      _chatItems.add({
        "type": "user_pill",
        "text": "📝 Update dari Form: ${result['summary']}",
      });
      _chatItems.add({"type": "info_card", "draft": _currentDraft});
      _chatItems.add({
        "type": "system_text",
        "text": newDraft.followUpQuestion!,
        "suggestions": newDraft.suggestedActions,
      });
    });
    _scrollToBottom();
  }

  String _formatNumber(num number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
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
          'Penjualan Barang',
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
                itemCount: _chatItems.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _chatItems.length) {
                    return _buildTypingIndicator();
                  }
                  final item = _chatItems[index];
                  switch (item['type']) {
                    case 'system_text':
                      return _buildSystemText(
                        item['text'],
                        item['suggestions'],
                      );
                    case 'user_pill':
                      return _buildUserPill(item['text']);
                    case 'info_card':
                      return _buildInfoCard(item['draft']);
                    default:
                      return const SizedBox();
                  }
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(SaleDraft draft) {
    double total = draft.total ?? 0;
    if (total == 0) {
      for (var item in draft.items) total += item.totalPrice;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Light Blue
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🛒', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.customerName,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    "${draft.items.length} Barang",
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          ...draft.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${item.productName} ${item.variant ?? ''} x${item.qty}",
                      style: GoogleFonts.montserrat(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    "Rp ${_formatNumber(item.totalPrice)}",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total",
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
              ),
              Text(
                "Rp ${_formatNumber(total)}",
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemText(String text, List<String>? suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (suggestions != null && suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions
                  .map(
                    (s) => ActionChip(
                      label: Text(
                        s,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: AppColors.primary,
                      onPressed: () => _handleSuggestion(s),
                    ),
                  )
                  .toList(),
            ),
          )
        else
          const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildUserPill(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.lavenderBlush,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(0),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
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
        height: 40,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
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
    // ... Reuse existing code ...
    // For brevity, I will copy the previous implementation logic but ensure controller binding
    // Since I am replacing the whole file content, I must rewrite it fully.
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.chatBackground,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: 5,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesanan...',
                        hintStyle: GoogleFonts.montserrat(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) => _sendMessage(value),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.description_outlined,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _openSaleForm,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }
}
