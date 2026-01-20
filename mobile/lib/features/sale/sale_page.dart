import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

class SalePage extends StatefulWidget {
  const SalePage({super.key});

  @override
  State<SalePage> createState() => _SalePageState();
}

class _SalePageState extends State<SalePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  // Using a dynamic list to represent different types of chat items
  final List<Map<String, dynamic>> _chatItems = [
    {
      "type": "info_card",
      "title": "Halo, Bos!",
      "description":
          "Siap mencatat cuan hari ini? Saya akan bantu rekap penjualanmu agar laporan keuangan tetap rapi dan akurat.",
      "note":
          "Setiap transaksi langsung terhitung di omzet harian. Jangan lupa cek stok!",
    },
    {
      "type": "system_text",
      "text":
          "Sore, Bagas! 👋\n\nSaya Alur, asisten penjualanmu. Barang apa yang baru saja terjual? Kopi, Gula, atau Sembako lainnya?",
    },
    {"type": "user_pill", "text": "Kopi Kapal Api 10 Renteng ☕"},
    {"type": "typing"},
  ];

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

  Widget _buildInfoCard(Map<String, dynamic> data) {
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
              const Text('👋', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                data['title'],
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data['description'],
            style: GoogleFonts.montserrat(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data['note'],
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemText(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(
          text: _messageController.text,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        );
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout(maxWidth: MediaQuery.of(context).size.width - 180);
        final lines = tp.computeLineMetrics().length;
        final isTall =
            _messageController.text.isNotEmpty &&
            (lines > 1 || _messageController.text.contains('\n'));

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: isTall
                      ? const EdgeInsets.fromLTRB(20, 12, 20, 12)
                      : const EdgeInsets.fromLTRB(20, 4, 8, 4),
                  decoration: BoxDecoration(
                    color: AppColors.chatBackground,
                    borderRadius: BorderRadius.circular(isTall ? 24 : 30),
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
                            hintText: 'Type your answer...',
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
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                _chatItems.removeWhere(
                                  (item) => item['type'] == 'typing',
                                );
                                _chatItems.add({
                                  "type": "user_pill",
                                  "text": value,
                                });
                                _messageController.clear();
                                Future.delayed(
                                  const Duration(milliseconds: 500),
                                  () {
                                    if (mounted) {
                                      setState(() {
                                        _chatItems.add({"type": "typing"});
                                      });
                                    }
                                  },
                                );
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Form Button
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
                  onPressed: () {
                    // TODO: Implement form logic
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Send Button
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      setState(() {
                        _chatItems.removeWhere(
                          (item) => item['type'] == 'typing',
                        );
                        _chatItems.add({
                          "type": "user_pill",
                          "text": _messageController.text,
                        });
                        _messageController.clear();
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            setState(() {
                              _chatItems.add({"type": "typing"});
                            });
                          }
                        });
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
