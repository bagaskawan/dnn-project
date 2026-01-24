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
      productName: json['product_name'] ?? '',
      qty: (json['qty'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
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
    required this.action,
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

    var actionsJson = json['suggested_actions'];
    List<String>? actionsList;
    if (actionsJson != null) {
      actionsList = List<String>.from(actionsJson);
    }

    return ProcurementDraft(
      action: json['action'] ?? 'chat',
      supplierName: json['supplier_name'],
      transactionDate: json['transaction_date'] ?? DateTime.now().toString(),
      items: itemsList,
      followUpQuestion: json['follow_up_question'],
      suggestedActions: actionsList,
      confidenceScore: (json['confidence_score'] ?? 0).toDouble(),
    );
  }

  // Penting: Mengirim balik draft ke Backend agar AI punya memori
  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'supplier_name': supplierName,
      'transaction_date': transactionDate,
      'items': items.map((e) => e.toJson()).toList(),
      'follow_up_question': followUpQuestion,
      'suggested_actions': suggestedActions,
      'confidence_score': confidenceScore,
    };
  }
}
