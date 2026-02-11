class ExtractedItem {
  final String productName;
  final String? variant; // Size/Type variant: "Besar", "Kecil", "Level 5"
  final double qty;
  final String unit;
  final double? unitPrice; // Price per unit (from receipt)
  final double totalPrice;
  final String? notes; // Attributes: "Manis", "Pedas Sedang"

  ExtractedItem({
    required this.productName,
    this.variant,
    required this.qty,
    required this.unit,
    this.unitPrice,
    required this.totalPrice,
    this.notes,
  });

  factory ExtractedItem.fromJson(Map<String, dynamic> json) {
    return ExtractedItem(
      productName: json['product_name'] ?? '',
      variant: json['variant'],
      qty: (json['qty'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      unitPrice: json['unit_price'] != null
          ? (json['unit_price']).toDouble()
          : null,
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'product_name': productName,
    'variant': variant,
    'qty': qty,
    'unit': unit,
    'unit_price': unitPrice,
    'total_price': totalPrice,
    'notes': notes,
  };

  /// Display name combining product + variant
  String get displayName {
    if (variant != null && variant!.isNotEmpty) {
      return '$productName ($variant)';
    }
    return productName;
  }
}

/// Merge candidate info for product deduplication confirmation
class MergeCandidate {
  final String? source; // "draft" or "db"
  final int? existingIndex; // Index in items list (if source is draft)
  final Map<String, dynamic> existingProduct;
  final Map<String, dynamic> newInput;
  final int similarity;

  MergeCandidate({
    this.source,
    this.existingIndex,
    required this.existingProduct,
    required this.newInput,
    required this.similarity,
  });

  factory MergeCandidate.fromJson(Map<String, dynamic> json) {
    return MergeCandidate(
      source: json['source'],
      existingIndex: json['existing_index'],
      existingProduct: Map<String, dynamic>.from(
        json['existing_product'] ?? {},
      ),
      newInput: Map<String, dynamic>.from(json['new_input'] ?? {}),
      similarity: json['similarity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'source': source,
    'existing_index': existingIndex,
    'existing_product': existingProduct,
    'new_input': newInput,
    'similarity': similarity,
  };

  String get existingDisplayName =>
      existingProduct['display_name'] ?? existingProduct['name'] ?? '';
  String get newInputDisplayName =>
      newInput['display_name'] ?? newInput['name'] ?? '';
}

class ProcurementDraft {
  final String?
  action; // "new", "append", "update", "delete", "chat", "clarify", "merge_confirm"
  final String? supplierName;
  final String? supplierPhone; // Phone/WA from receipt
  final String? supplierAddress; // Address from receipt
  final String transactionDate;
  final String? receiptNumber; // Invoice/receipt number
  final List<ExtractedItem> items;
  final double? subtotal; // Sum before discount
  final double? discount; // Discount amount
  final double? total; // Final total
  final String? paymentMethod; // Tunai/Transfer
  final String? followUpQuestion; // AI asks if data is missing
  final List<String>? suggestedActions; // Action buttons to show
  final double confidenceScore;
  // Merge confirmation fields
  final MergeCandidate? mergeCandidate;
  final List<Map<String, dynamic>>? pendingItems;
  final List<Map<String, dynamic>>?
  pendingItemsToReprocess; // Items to re-send after confirmation
  // Supplier confirmation field
  final Map<String, dynamic>? supplierCandidate; // {name, phone, similarity}

  ProcurementDraft({
    required this.action,
    this.supplierName,
    this.supplierPhone,
    this.supplierAddress,
    required this.transactionDate,
    this.receiptNumber,
    required this.items,
    this.subtotal,
    this.discount,
    this.total,
    this.paymentMethod,
    this.followUpQuestion,
    this.suggestedActions,
    required this.confidenceScore,
    this.mergeCandidate,
    this.pendingItems,
    this.pendingItemsToReprocess,
    this.supplierCandidate,
  });

  factory ProcurementDraft.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    List<ExtractedItem> itemsList = list
        .map((i) => ExtractedItem.fromJson(i))
        .toList();

    var actionsJson = json['suggested_actions'];
    List<String>? actionsList;
    if (actionsJson != null) {
      actionsList = List<String>.from(actionsJson);
    }

    // Parse merge candidate
    MergeCandidate? mergeCandidate;
    if (json['merge_candidate'] != null) {
      mergeCandidate = MergeCandidate.fromJson(json['merge_candidate']);
    }

    // Parse pending items
    List<Map<String, dynamic>>? pendingItems;
    if (json['pending_items'] != null) {
      pendingItems = List<Map<String, dynamic>>.from(json['pending_items']);
    }

    // Parse pending items to reprocess
    List<Map<String, dynamic>>? pendingItemsToReprocess;
    if (json['pending_items_to_reprocess'] != null) {
      pendingItemsToReprocess = List<Map<String, dynamic>>.from(
        json['pending_items_to_reprocess'],
      );
    }

    // Parse supplier candidate
    Map<String, dynamic>? supplierCandidate;
    if (json['supplier_candidate'] != null) {
      supplierCandidate = Map<String, dynamic>.from(json['supplier_candidate']);
    }

    return ProcurementDraft(
      action: json['action'] ?? 'chat',
      supplierName: json['supplier_name'],
      supplierPhone: json['supplier_phone'],
      supplierAddress: json['supplier_address'],
      transactionDate: json['transaction_date'] ?? DateTime.now().toString(),
      receiptNumber: json['receipt_number'],
      items: itemsList,
      subtotal: json['subtotal'] != null ? (json['subtotal']).toDouble() : null,
      discount: json['discount'] != null ? (json['discount']).toDouble() : null,
      total: json['total'] != null ? (json['total']).toDouble() : null,
      paymentMethod: json['payment_method'],
      followUpQuestion: json['follow_up_question'],
      suggestedActions: actionsList,
      confidenceScore: (json['confidence_score'] ?? 0).toDouble(),
      mergeCandidate: mergeCandidate,
      pendingItems: pendingItems,
      pendingItemsToReprocess: pendingItemsToReprocess,
      supplierCandidate: supplierCandidate,
    );
  }

  // Penting: Mengirim balik draft ke Backend agar AI punya memori
  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'supplier_name': supplierName,
      'supplier_phone': supplierPhone,
      'supplier_address': supplierAddress,
      'transaction_date': transactionDate,
      'receipt_number': receiptNumber,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'follow_up_question': followUpQuestion,
      'suggested_actions': suggestedActions,
      'confidence_score': confidenceScore,
      'merge_candidate': mergeCandidate?.toJson(),
      'pending_items': pendingItems,
      'pending_items_to_reprocess': pendingItemsToReprocess,
      'supplier_candidate': supplierCandidate,
    };
  }

  ProcurementDraft copyWithAppendedItems(ProcurementDraft newDraft) {
    return ProcurementDraft(
      action: newDraft.action,
      supplierName: newDraft.supplierName ?? this.supplierName,
      supplierPhone: newDraft.supplierPhone ?? this.supplierPhone,
      supplierAddress: newDraft.supplierAddress ?? this.supplierAddress,
      transactionDate: this.transactionDate,
      receiptNumber: newDraft.receiptNumber ?? this.receiptNumber,
      items: [...this.items, ...newDraft.items],
      subtotal: newDraft.subtotal ?? this.subtotal,
      discount: newDraft.discount ?? this.discount,
      total: newDraft.total ?? this.total,
      paymentMethod: newDraft.paymentMethod ?? this.paymentMethod,
      followUpQuestion: newDraft.followUpQuestion,
      suggestedActions: newDraft.suggestedActions,
      confidenceScore: newDraft.confidenceScore,
      mergeCandidate: newDraft.mergeCandidate,
      pendingItems: newDraft.pendingItems,
      pendingItemsToReprocess: newDraft.pendingItemsToReprocess,
      supplierCandidate: newDraft.supplierCandidate,
    );
  }

  ProcurementDraft copyWithUpdatedFields(ProcurementDraft newDraft) {
    return ProcurementDraft(
      action: newDraft.action,
      supplierName: newDraft.supplierName ?? this.supplierName,
      supplierPhone: newDraft.supplierPhone ?? this.supplierPhone,
      supplierAddress: newDraft.supplierAddress ?? this.supplierAddress,
      transactionDate: newDraft.transactionDate,
      receiptNumber: newDraft.receiptNumber ?? this.receiptNumber,
      items: newDraft.items.isNotEmpty ? newDraft.items : this.items,
      subtotal: newDraft.subtotal ?? this.subtotal,
      discount: newDraft.discount ?? this.discount,
      total: newDraft.total ?? this.total,
      paymentMethod: newDraft.paymentMethod ?? this.paymentMethod,
      followUpQuestion: newDraft.followUpQuestion,
      suggestedActions: newDraft.suggestedActions,
      confidenceScore: newDraft.confidenceScore,
      mergeCandidate: newDraft.mergeCandidate,
      pendingItems: newDraft.pendingItems,
      pendingItemsToReprocess: newDraft.pendingItemsToReprocess,
      supplierCandidate: newDraft.supplierCandidate,
    );
  }
}
