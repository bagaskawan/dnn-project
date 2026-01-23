class ExtractedItem {
  final String productName;
  final double qty;
  final String unit;
  final double totalPrice;
  final String? notes;

  ExtractedItem({
    required this.productName,
    required this.qty,
    required this.unit,
    required this.totalPrice,
    this.notes,
  });

  factory ExtractedItem.fromJson(Map<String, dynamic> json) {
    return ExtractedItem(
      productName: json['product_name'] ?? 'Unknown Product',
      qty: (json['qty'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'pcs',
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'product_name': productName,
    'qty': qty,
    'unit': unit,
    'total_price': totalPrice,
    'notes': notes,
  };
}

class ProcurementDraft {
  final String? action; // "new", "append", "update", "delete", "chat"
  final String? supplierName;
  final String transactionDate;
  final List<ExtractedItem> items;
  final String? followUpQuestion; // AI asks if data is missing
  final List<String>? suggestedActions; // Action buttons to show
  final double confidenceScore;

  ProcurementDraft({
    this.action,
    this.supplierName,
    required this.transactionDate,
    required this.items,
    this.followUpQuestion,
    this.suggestedActions,
    required this.confidenceScore,
  });

  factory ProcurementDraft.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    List<ExtractedItem> itemsList = list
        .map((i) => ExtractedItem.fromJson(i))
        .toList();

    var actionsList = json['suggested_actions'] as List?;
    List<String>? suggestedActionsList = actionsList
        ?.map((a) => a.toString())
        .toList();

    return ProcurementDraft(
      action: json['action'] ?? 'new',
      supplierName: json['supplier_name'],
      transactionDate: json['transaction_date'] ?? DateTime.now().toString(),
      items: itemsList,
      followUpQuestion: json['follow_up_question'],
      suggestedActions: suggestedActionsList,
      confidenceScore: (json['confidence_score'] ?? 0).toDouble(),
    );
  }

  // Convert to JSON for sending to backend as context
  Map<String, dynamic> toJson() => {
    'action': action,
    'supplier_name': supplierName,
    'transaction_date': transactionDate,
    'items': items.map((i) => i.toJson()).toList(),
    'follow_up_question': followUpQuestion,
    'confidence_score': confidenceScore,
  };

  // Helper to merge items from another draft (for append action)
  ProcurementDraft copyWithAppendedItems(ProcurementDraft other) {
    return ProcurementDraft(
      action: 'new',
      supplierName: other.supplierName ?? supplierName,
      transactionDate: transactionDate,
      items: [...items, ...other.items],
      followUpQuestion: other.followUpQuestion,
      confidenceScore: other.confidenceScore,
    );
  }

  // Helper to update fields from another draft (for update action)
  ProcurementDraft copyWithUpdatedFields(ProcurementDraft other) {
    return ProcurementDraft(
      action: 'new',
      supplierName: other.supplierName ?? supplierName,
      transactionDate: other.transactionDate,
      items: other.items.isNotEmpty ? other.items : items,
      followUpQuestion: other.followUpQuestion,
      suggestedActions: other.suggestedActions,
      confidenceScore: other.confidenceScore,
    );
  }

  // Helper to remove items (for delete action)
  ProcurementDraft copyWithDeletedItems(ProcurementDraft other) {
    if (other.items.isEmpty) return this;

    final itemToDelete = other.items.first;
    final updatedItems = items.where((item) {
      // Keep item if it DOES NOT match the item to delete
      // Match by name, qty, and price to be specific
      final isMatch =
          item.productName.toLowerCase() ==
              itemToDelete.productName.toLowerCase() &&
          item.qty == itemToDelete.qty &&
          item.totalPrice == itemToDelete.totalPrice;
      return !isMatch;
    }).toList();

    return ProcurementDraft(
      action: 'new',
      supplierName: other.supplierName ?? supplierName,
      transactionDate: transactionDate,
      items: updatedItems,
      followUpQuestion: other.followUpQuestion,
      confidenceScore: other.confidenceScore,
    );
  }

  // Calculate total price of all items
  double get totalPrice => items.fold(0, (sum, item) => sum + item.totalPrice);
}
