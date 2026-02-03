import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';
import '../../models/procurement_draft.dart';
import 'dart:async'; // For debounce

class BuyPage extends StatefulWidget {
  const BuyPage({super.key});

  @override
  State<BuyPage> createState() => _BuyPageState();
}

class _BuyPageState extends State<BuyPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker(); // Keep one instance
  final ApiService _apiService = ApiService();

  // Store current draft for accumulating items
  ProcurementDraft? _currentDraft;
  String? _transactionCode; // To store random invoice code

  // Static variables to persist draft across navigation
  static ProcurementDraft? _savedDraft;
  static List<Map<String, dynamic>>? _savedChatItems;
  static String? _savedTransactionCode;

  // Animation Controller for Pinned Draft Card
  late AnimationController _draftCardAnimationController;
  late Animation<double> _draftCardAnimation;

  // Autocomplete State
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Initialize Animation Controller
    _draftCardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Smooth transition duration
    );
    _draftCardAnimation = CurvedAnimation(
      parent: _draftCardAnimationController,
      curve: Curves.fastOutSlowIn,
    );

    // Listen to text changes for Autocomplete
    _messageController.addListener(_onSearchChanged);

    // Check for saved session and show resume modal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_savedDraft != null && _savedDraft!.items.isNotEmpty) {
        _showResumeSessionModal();
      }
    });
  }

  @override
  void dispose() {
    // Save current session before leaving
    if (_currentDraft != null && _currentDraft!.items.isNotEmpty) {
      _savedDraft = _currentDraft;
      _savedChatItems = List.from(_chatItems);
      _savedTransactionCode = _transactionCode;
    }

    _messageController.removeListener(_onSearchChanged);
    _debounce?.cancel();
    _draftCardAnimationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchProducts();
    });
  }

  Future<void> _searchProducts() async {
    final query = _messageController.text;
    // Simple logic: Trigger only if last word is being typed and length > 1
    // But for "Smart Command" usually we check the whole or last part.
    // Let's try simple: Search matched against whole text OR last word.

    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    // Ambil kata terakhir untuk autocomplete nama barang
    final lastWord = query.trim().split(' ').last;

    // Optimization: Don't search if it looks like a quantity (starts with digit)
    // RegExp(r'^[0-9]') matches if string starts with a number.
    if (lastWord.length < 2 || RegExp(r'^[0-9]').hasMatch(lastWord)) {
      setState(() => _suggestions = []);
      return;
    }

    final results = await _apiService.searchProducts(lastWord);
    setState(() {
      _suggestions = results;
    });
  }

  void _applySuggestion(Map<String, dynamic> product) {
    final text = _messageController.text;
    final words = text.trim().split(' ');
    if (words.isNotEmpty) {
      words.removeLast(); // Remove partial word
    }
    words.add(product['name']); // Add full product name

    final newText = "${words.join(' ')} "; // Add space for next input (qty)
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      ),
    );

    setState(() => _suggestions = []);
  }

  // Initial Chat Items
  final List<Map<String, dynamic>> _chatItems = [
    {"type": "system_note", "text": "Halo! 👋 Mau input barang apa hari ini?"},
  ];

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

  void _sendMessage({String? customText}) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    print("[APP_DEBUG] Sent User Message: $text");

    // Handle special keywords "simpan" and "edit"
    final lowerText = text.toLowerCase();
    if (_currentDraft != null && _currentDraft!.items.isNotEmpty) {
      if (lowerText == 'simpan' || lowerText == 'save') {
        _messageController.clear();
        _showConfirmationModal();
        return;
      }
      if (lowerText == 'edit' || lowerText == 'ubah') {
        _messageController.clear();
        _showEditListBottomSheet();
        return;
      }
    } else if (lowerText == 'simpan' ||
        lowerText == 'edit' ||
        lowerText == 'save' ||
        lowerText == 'ubah') {
      // No draft yet - inform user
      setState(() {
        _chatItems.add({"type": "user_pill", "text": text});
        _chatItems.add({
          "type": "system_text",
          "text":
              "Belum ada data untuk di-${lowerText == 'simpan' || lowerText == 'save' ? 'simpan' : 'edit'} Kak. Silakan input produk terlebih dahulu ya! 📝",
        });
      });
      _messageController.clear();
      _scrollToBottom();
      return;
    }

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
      _currentDraft, // Logika baru: Kirim object draft, bukan history list
    );

    print("[APP_DEBUG] Received AI Response draft: ${draft?.toJson()}");

    _handleApiResponse(draft);
  }

  void _handleApiResponse(ProcurementDraft? newDraft) {
    setState(() {
      _chatItems.removeWhere((item) => item['type'] == 'typing');
      // Also remove loading message from image processing
      _chatItems.removeWhere(
        (item) =>
            item['type'] == 'system_text' &&
            (item['text'] as String).contains('menganalisis gambar'),
      );

      if (newDraft != null) {
        // --- 1. STATE MANAGEMENT: IMMUTABLE MERGE STRATEGY ---

        if (_currentDraft == null || newDraft.action == 'new') {
          // KASUS 1: Draft Baru -> Replace Total
          _currentDraft = newDraft;
          _transactionCode ??=
              "INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
          _chatItems.removeWhere(
            (item) => item['type'] == 'system_note',
          ); // Hapus intro
        } else if (newDraft.action == 'chat') {
          // KASUS 2: Chat / Klarifikasi -> Jangan ubah data draft, cuma nanya
          // Biarkan _currentDraft apa adanya (mempertahankan state sebelumnya)
        } else if (newDraft.action == 'merge_confirm') {
          // KASUS 3: Merge Confirmation -> Simpan mergeCandidate untuk button handler
          // Preserve existing items, add mergeCandidate info
          _currentDraft = ProcurementDraft(
            action: 'merge_confirm',
            supplierName: _currentDraft!.supplierName,
            transactionDate: _currentDraft!.transactionDate,
            items: _currentDraft!.items, // Keep existing items
            followUpQuestion: newDraft.followUpQuestion,
            suggestedActions: newDraft.suggestedActions,
            confidenceScore: newDraft.confidenceScore,
            mergeCandidate: newDraft.mergeCandidate, // Store for button click
            pendingItems: newDraft.pendingItems,
          );
        } else if (newDraft.action == 'clarify') {
          // KASUS 4: Clarify -> Sama seperti chat, tanya klarifikasi
          // Biarkan _currentDraft apa adanya
        } else if (newDraft.action == 'update') {
          // KASUS 5: Update (Supplier Change) -> Hanya update field, JANGAN merge items
          // Items tetap dari _currentDraft yang sudah ada
          _currentDraft = ProcurementDraft(
            action: 'update',
            supplierName: newDraft.supplierName ?? _currentDraft!.supplierName,
            transactionDate: _currentDraft!.transactionDate,
            items: _currentDraft!
                .items, // KEEP existing items, don't add from response!
            followUpQuestion: newDraft.followUpQuestion,
            suggestedActions: newDraft.suggestedActions,
            confidenceScore: newDraft.confidenceScore,
          );
        } else if (newDraft.action == 'append') {
          // KASUS 6: Append -> Gabungkan items baru ke items lama
          List<ExtractedItem> mergedItems = List.from(_currentDraft!.items);
          mergedItems.addAll(newDraft.items);

          _currentDraft = ProcurementDraft(
            action: 'update',
            supplierName: newDraft.supplierName ?? _currentDraft!.supplierName,
            transactionDate: _currentDraft!.transactionDate,
            items: mergedItems,
            followUpQuestion: newDraft.followUpQuestion,
            suggestedActions: newDraft.suggestedActions,
            confidenceScore: newDraft.confidenceScore,
          );
        } else if (newDraft.action == 'delete') {
          // KASUS 7: Delete -> Gunakan items dari response (sudah dihapus oleh backend)
          _currentDraft = ProcurementDraft(
            action: 'update',
            supplierName: newDraft.supplierName ?? _currentDraft!.supplierName,
            transactionDate: _currentDraft!.transactionDate,
            items:
                newDraft.items, // Use items from backend (item already removed)
            followUpQuestion: newDraft.followUpQuestion,
            suggestedActions: newDraft.suggestedActions,
            confidenceScore: newDraft.confidenceScore,
          );
        }

        // --- 2. UI TRIGGER: ANIMASI KARTU ---
        // Munculkan kartu jika ada Supplier ATAU ada Item
        bool hasData =
            _currentDraft != null &&
            ((_currentDraft!.supplierName != null &&
                    _currentDraft!.supplierName!.isNotEmpty) ||
                _currentDraft!.items.isNotEmpty);

        if (hasData &&
            _draftCardAnimationController.status != AnimationStatus.completed) {
          _draftCardAnimationController.forward();
        }

        // --- 3. UI FEEDBACK: CHAT BUBBLES ---

        // A. Bubble Pertanyaan AI
        if (newDraft.followUpQuestion != null &&
            newDraft.followUpQuestion!.isNotEmpty) {
          _chatItems.add({
            "type": "system_text",
            "text": newDraft.followUpQuestion!,
          });
        }

        // B. Tombol Aksi (Suggested Actions)
        // Filter out Edit/Simpan jika draft sudah punya items (button ada di draft card)
        List<String> actions = newDraft.suggestedActions ?? [];

        // Remove Edit & Simpan from action buttons (sudah ada di draft card)
        if (_currentDraft != null && _currentDraft!.items.isNotEmpty) {
          actions = actions
              .where(
                (action) =>
                    action.toLowerCase() != 'edit' &&
                    action.toLowerCase() != 'simpan' &&
                    action.toLowerCase() != 'save',
              )
              .toList();
        } else {
          // Logic tambahan untuk flow tanpa draft
          if (hasData &&
              !actions.contains("Simpan") &&
              !actions.contains(
                "Jadikan Supplier: ${_messageController.text}",
              )) {
            if (newDraft.action != 'chat') {
              actions.add("Simpan");
            }
          }
        }

        if (actions.isNotEmpty) {
          _chatItems.add({"type": "action_buttons", "actions": actions});
        }

        // --- 4. AUTO RE-PROCESS PENDING ITEMS ---
        // If backend returns pendingItemsToReprocess, automatically re-send them
        if (newDraft.pendingItemsToReprocess != null &&
            newDraft.pendingItemsToReprocess!.isNotEmpty) {
          // Convert pending items to text format and re-send
          _reprocessPendingItems(newDraft.pendingItemsToReprocess!);
        }
      } else {
        _chatItems.add({
          "type": "system_text",
          "text": "Maaf, terjadi kesalahan koneksi.",
        });
      }
    });
    _scrollToBottom();
  }

  void _reprocessPendingItems(List<Map<String, dynamic>> pendingItems) {
    // Convert pending items back to text format for re-processing
    // This will trigger duplicate check again
    for (var item in pendingItems) {
      String productName = item['product_name'] ?? '';
      String variant = item['variant'] ?? '';
      double qty = (item['qty'] ?? 0).toDouble();
      String unit = item['unit'] ?? 'pcs';
      double price = (item['total_price'] ?? 0).toDouble();
      String notes = item['notes'] ?? '';

      // Build text representation
      String itemText = productName;
      if (variant.isNotEmpty) {
        itemText += ' $variant';
      }
      if (notes.isNotEmpty) {
        itemText += ' $notes';
      }
      itemText += ' ${qty.toStringAsFixed(0)}$unit ${price.toStringAsFixed(0)}';

      // Re-send as new input (will be checked for duplicates)
      Future.delayed(Duration(milliseconds: 500), () {
        _sendMessage(customText: itemText);
      });
    }
  }

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
                      _processImage(File(image.path));
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
                      _processImage(File(image.path));
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

  void _processImage(File imageFile) async {
    setState(() {
      _chatItems.removeWhere((item) => item['type'] == 'action_buttons');
      _chatItems.add({"type": "user_image", "imagePath": imageFile.path});
      // Custom loading message for image analysis
      _chatItems.add({
        "type": "system_text",
        "text": "⏳ Mohon tunggu ya Kak, sistem sedang menganalisis gambar...",
      });
      _chatItems.add({"type": "typing"});
    });
    _scrollToBottom();

    final draft = await _apiService.parseImage(imageFile, _currentDraft);
    _handleApiResponse(draft);
  }

  void _showEditListBottomSheet() {
    if (_currentDraft == null || _currentDraft!.items.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  "Pilih Barang untuk Diedit",
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _currentDraft!.items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _currentDraft!.items[index];
                      // Build subtitle with qty, unit, price, and optionally notes
                      String subtitle =
                          "${item.qty.toStringAsFixed(0)} ${item.unit} • Rp ${_formatCurrency(item.totalPrice)}";
                      if (item.notes != null && item.notes!.isNotEmpty) {
                        subtitle += "\n${item.notes}";
                      }

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.displayName, // Shows "Nangka (Besar)" instead of "Nangka"
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          subtitle,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        isThreeLine:
                            item.notes != null && item.notes!.isNotEmpty,
                        trailing: Center(
                          widthFactor: 1,
                          child: Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context); // Close list modal
                          _showEditFormBottomSheet(index, item); // Open form
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditFormBottomSheet(int itemIndex, ExtractedItem item) {
    final qtyController = TextEditingController(
      text: item.qty.toStringAsFixed(0),
    );
    final unitController = TextEditingController(text: item.unit);
    final priceController = TextEditingController(
      text: item.totalPrice.toStringAsFixed(0),
    );
    final variantController = TextEditingController(text: item.variant ?? "");
    final noteController = TextEditingController(text: item.notes ?? "");

    // Determine which optional fields to show
    final bool hasVariant = item.variant != null && item.variant!.isNotEmpty;
    final bool hasNotes = item.notes != null && item.notes!.isNotEmpty;

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
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Back button row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Close edit form
                          _showEditListBottomSheet(); // Reopen list
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.arrow_back_ios,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Edit ${item.displayName}",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Jumlah",
                            labelStyle: GoogleFonts.montserrat(fontSize: 12),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: unitController,
                          decoration: InputDecoration(
                            labelText: "Satuan",
                            labelStyle: GoogleFonts.montserrat(fontSize: 12),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _CurrencyInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: "Total Harga (Rp)",
                      labelStyle: GoogleFonts.montserrat(fontSize: 12),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Variant field (only if item has variant)
                  if (hasVariant) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: variantController,
                      decoration: InputDecoration(
                        labelText: "Variant (Ukuran/Tipe)",
                        labelStyle: GoogleFonts.montserrat(fontSize: 12),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                  // Notes field (only if item has notes)
                  if (hasNotes) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: "Catatan",
                        labelStyle: GoogleFonts.montserrat(fontSize: 12),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        // 1. Update logic - use controller values if field was shown
                        final newItem = ExtractedItem(
                          productName: item.productName,
                          variant: hasVariant
                              ? variantController.text
                              : item.variant,
                          qty: double.tryParse(qtyController.text) ?? item.qty,
                          unit: unitController.text,
                          totalPrice:
                              double.tryParse(
                                priceController.text.replaceAll('.', ''),
                              ) ??
                              item.totalPrice,
                          notes: hasNotes ? noteController.text : item.notes,
                        );

                        setState(() {
                          if (_currentDraft != null) {
                            _currentDraft!.items[itemIndex] = newItem;
                            // Pinned Draft Card will rebuild automatically with setState
                          }
                        });

                        Navigator.pop(context);
                        _scrollToBottom();
                      },
                      child: Text(
                        "Simpan Perubahan",
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showConfirmationModal() {
    if (_currentDraft == null || _currentDraft!.items.isEmpty) return;

    double totalPrice = 0;
    for (var item in _currentDraft!.items) {
      totalPrice += item.totalPrice;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                "Konfirmasi Pembelian",
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              // Reuse similar layout to Pinned Card for consistency
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        _currentDraft!.supplierName ?? "Supplier",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "${DateTime.now().toString().split(' ')[0].replaceAll('-', '/')} - ${_transactionCode ?? ''}",
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const Divider(height: 24),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _currentDraft!.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _currentDraft!.items[index];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.displayName,
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "${item.qty.toStringAsFixed(0)} ${item.unit} x ${_formatCurrency(item.unitPrice ?? (item.totalPrice / item.qty))}",
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "Rp ${_formatCurrency(item.totalPrice)}",
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total"),
                          Text(
                            "Rp ${_formatCurrency(totalPrice)}",
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Batal",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _commitTransaction();
                      },
                      child: Text(
                        "Simpan",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _commitTransaction() async {
    if (_currentDraft == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                "Menyimpan transaksi...",
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final response = await _apiService.commitTransaction(_currentDraft!);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.success) {
        // Show success dialog
        if (mounted) {
          _showSuccessDialog(response);
        }
      } else {
        // Show error snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message,
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog on error
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: $e",
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showSuccessDialog(CommitTransactionResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Transaksi Berhasil!",
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              response.message,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            if (response.invoiceNumber != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "No: ${response.invoiceNumber}",
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
            if (response.newProductsCreated != null &&
                response.newProductsCreated! > 0) ...[
              const SizedBox(height: 8),
              Text(
                "🆕 ${response.newProductsCreated} produk baru ditambahkan",
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Reset state and go back
                setState(() {
                  _currentDraft = null;
                  _chatItems.clear();
                  // Reset to initial welcome message
                  _chatItems.add({
                    "type": "system_note",
                    "text": "Halo! 👋 Mau input barang apa hari ini?",
                  });
                  _transactionCode = null;
                  // Also clear saved state
                  _savedDraft = null;
                  _savedChatItems = null;
                  _savedTransactionCode = null;
                });
                // Hide draft card animation
                _draftCardAnimationController.reverse();
              },
              child: Text(
                "Selesai",
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResumeSessionModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.history, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              "Sesi Sebelumnya",
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ditemukan draft pengadaan yang belum disimpan:",
              style: GoogleFonts.montserrat(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _savedDraft?.supplierName ?? "Supplier belum diset",
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_savedDraft?.items.length ?? 0} produk",
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Apakah ingin melanjutkan proses sebelumnya atau buat baru?",
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Buat Baru button
          TextButton(
            onPressed: () {
              // Clear saved session
              _savedDraft = null;
              _savedChatItems = null;
              _savedTransactionCode = null;
              Navigator.pop(context);
            },
            child: Text(
              "Buat Baru",
              style: GoogleFonts.montserrat(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Lanjutkan button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // Restore saved session
              setState(() {
                _currentDraft = _savedDraft;
                _transactionCode = _savedTransactionCode;
                if (_savedChatItems != null) {
                  _chatItems.clear();
                  _chatItems.addAll(_savedChatItems!);
                }
                // Show draft card animation
                if (_currentDraft != null) {
                  _draftCardAnimationController.forward();
                }
              });
              // Clear saved after restore
              _savedDraft = null;
              _savedChatItems = null;
              _savedTransactionCode = null;
              Navigator.pop(context);
            },
            child: Text(
              "Lanjutkan",
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
        child: Stack(
          children: [
            Column(
              children: [
                // --- 1. PINNED DRAFT CARD (Top Section) ---
                // Wrap with SizeTransition for smooth appearance
                SizeTransition(
                  sizeFactor: _draftCardAnimation,
                  axisAlignment: -1.0, // Expand from top
                  child:
                      (_currentDraft != null &&
                          ((_currentDraft!.supplierName != null &&
                                  _currentDraft!.supplierName!.isNotEmpty) ||
                              _currentDraft!.items.isNotEmpty))
                      ? _buildPinnedDraftCard(_currentDraft!)
                      : const SizedBox.shrink(),
                ),

                // --- 2. CHAT AREA (Bottom Section) ---
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
                        case 'info_card':
                          return _buildInfoCard(item);
                        case 'system_note':
                          return _buildSystemNote(item['text']);
                        case 'system_text':
                          return _buildSystemText(item['text']);
                        case 'user_pill':
                          return _buildUserPill(item['text']);
                        case 'user_image':
                          return _buildUserImage(item['imagePath']);
                        case 'typing':
                          return _buildTypingIndicator();
                        // case 'draft_card': -> REMOVED from chat bubble
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
                // Input Area tetap di bawah
                _buildInputArea(),
              ],
            ),

            // --- AUTOCOMPLETE OVERLAY ---
            if (_suggestions.isNotEmpty)
              Positioned(
                bottom: 80, // Height of Input Area approx
                left: 24,
                right: 24,
                child: _buildSuggestionsList(),
              ),
          ],
        ),
      ),
    );
  }

  // --- NEW PINNED WIDGET ---
  Widget _buildPinnedDraftCard(ProcurementDraft draft) {
    double totalPrice = 0;
    for (var item in draft.items) {
      totalPrice += item.totalPrice;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      margin: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Text(
            draft.supplierName ?? "Siapa nama supplier?",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          // Show phone number if available (from receipt scanning)
          if (draft.supplierPhone != null && draft.supplierPhone!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    draft.supplierPhone!,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            "${DateTime.now().toString().split(' ')[0].replaceAll('-', '/')} - ${draft.receiptNumber ?? _transactionCode ?? 'INV-0000'}",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 12),

          // Scrollable Items List
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: draft.items.map((item) {
                  return Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.displayName,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (item.unitPrice ?? 0) > 0
                                      ? "${item.qty.toStringAsFixed(0)} ${item.unit} x ${_formatCurrency(item.unitPrice ?? 0)}"
                                      : "${item.qty.toStringAsFixed(0)} ${item.unit}",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (item.notes != null &&
                                    item.notes!.isNotEmpty)
                                  Text(
                                    item.notes!,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            "Rp ${_formatCurrency(item.totalPrice)}",
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 10),

          // Show discount if available (from receipt scanning)
          if (draft.discount != null && draft.discount! > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Diskon",
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade600,
                    ),
                  ),
                  Text(
                    "- Rp ${_formatCurrency(draft.discount!)}",
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total",
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                "Rp ${_formatCurrency(draft.total ?? totalPrice)}",
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          // Edit & Simpan Buttons in Draft Card
          const SizedBox(height: 16),
          Row(
            children: [
              // Edit Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showEditListBottomSheet(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    "Edit",
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Simpan Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showConfirmationModal(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    "Simpan",
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS (DESIGN PRESERVED) ---

  Widget _buildInfoCard(Map<String, dynamic> item) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
              bottomLeft: Radius.zero,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item['title'],
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['description'],
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
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
          final isEdit = action.toLowerCase() == 'edit';
          final label = isEdit ? 'Edit' : action;

          return GestureDetector(
            onTap: () {
              if (isEdit) {
                _showEditListBottomSheet();
              } else if (action.toLowerCase() == 'simpan') {
                // Validation: Check if supplier name is present
                if (_currentDraft?.supplierName == null ||
                    _currentDraft!.supplierName!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Harap isi nama supplier terlebih dahulu!",
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      backgroundColor: Colors.red.shade400,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } else {
                  _showConfirmationModal();
                }
              } else {
                _sendMessage(customText: label);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                action,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.mintGreen,
            borderRadius: BorderRadius.only(
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
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserImage(String imagePath) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => _showImageZoomModal(imagePath),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.60,
            maxHeight: 200,
          ),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(0),
            ),
            child: Stack(
              children: [
                Image.file(File(imagePath), fit: BoxFit.cover),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Tap untuk zoom',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImageZoomModal(String imagePath) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(0),
          child: Stack(
            children: [
              // Zoomable Image
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(File(imagePath), fit: BoxFit.contain),
                ),
              ),
              // Close Button
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dot(AppColors.primary.withOpacity(0.4)),
            const SizedBox(width: 4),
            _dot(AppColors.primary.withOpacity(0.7)),
            const SizedBox(width: 4),
            _dot(AppColors.primary),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 0, 16),
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
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        onSubmitted: (value) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showImagePickerOptions,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.grey.shade400,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
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
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(),
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

  Widget _buildSystemNote(String text) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ),
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

  Widget _buildSuggestionsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _suggestions[index];
          return ListTile(
            dense: true,
            title: Text(
              item['name'],
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              "Satuan: ${item['unit']}",
              style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey),
            ),
            onTap: () => _applySuggestion(item),
          );
        },
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hanya ambil digit
    String rawText = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (rawText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = double.parse(rawText);

    // Simple manual formatting to avoid Intl dependency if sticking to regex
    String newText = value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
