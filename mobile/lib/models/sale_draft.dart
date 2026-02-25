import 'procurement_draft.dart';

class SaleDraft {
  final String action;
  final String customerName;
  final List<ExtractedItem> items;
  final double? total;
  final String? followUpQuestion;
  final List<String> suggestedActions;

  SaleDraft({
    required this.action,
    required this.customerName,
    required this.items,
    this.total,
    this.followUpQuestion,
    this.suggestedActions = const [],
  });

  factory SaleDraft.fromJson(Map<String, dynamic> json) {
    return SaleDraft(
      action: json['action'] ?? 'new',
      customerName: json['customer_name'] ?? 'Pelanggan Umum',
      items:
          (json['items'] as List?)
              ?.map((item) => ExtractedItem.fromJson(item))
              .toList() ??
          [],
      total: json['total'] != null ? (json['total'] as num).toDouble() : null,
      followUpQuestion: json['follow_up_question'],
      suggestedActions:
          (json['suggested_actions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'customer_name': customerName,
      'items': items.map((e) => e.toJson()).toList(),
      'total': total,
      'follow_up_question': followUpQuestion,
      'suggested_actions': suggestedActions,
    };
  }
}
