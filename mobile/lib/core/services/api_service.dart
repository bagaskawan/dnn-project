import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/procurement_draft.dart';

class ApiService {
  // Ganti dengan IP Laptop kamu seperti sebelumnya
  static const String baseUrl = 'http://10.0.2.2:8000';

  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));

  // 1. Kirim Chat Teks dengan Context Draft
  Future<ProcurementDraft?> parseText(
    String message,
    ProcurementDraft? currentDraft,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/parse/text',
        data: {
          'new_message': message,
          'current_draft': currentDraft?.toJson(), // Kirim state terakhir
        },
      );

      if (response.statusCode == 200) {
        return ProcurementDraft.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error Text API: $e");
      return null;
    }
  }

  // 2. Kirim Gambar dengan Context Draft
  Future<ProcurementDraft?> parseImage(
    File imageFile,
    ProcurementDraft? currentDraft,
  ) async {
    try {
      String fileName = imageFile.path.split('/').last;

      // Kirim draft sebagai JSON String karena Multipart tidak bisa nested JSON
      String? draftJsonStr;
      if (currentDraft != null) {
        draftJsonStr = jsonEncode(currentDraft.toJson());
      }

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        if (draftJsonStr != null) "current_draft_str": draftJsonStr,
      });

      final response = await _dio.post('/api/v1/parse/image', data: formData);

      if (response.statusCode == 200) {
        return ProcurementDraft.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error Image API: $e");
      return null;
    }
  }

  // 3. Search Products (Autocomplete)
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final response = await _dio.get(
        '/api/v1/products/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      print("Error Search API: $e");
      return [];
    }
  }

  // 4. Commit Transaction to Database
  Future<CommitTransactionResponse> commitTransaction(
    ProcurementDraft draft, {
    String? evidenceUrl,
  }) async {
    try {
      // Calculate total if not provided
      double total = draft.total ?? 0;
      if (total == 0) {
        for (var item in draft.items) {
          total += item.totalPrice;
        }
        if (draft.discount != null && draft.discount! > 0) {
          total -= draft.discount!;
        }
      }

      final response = await _dio.post(
        '/api/v1/transactions/commit',
        data: {
          'supplier_name': draft.supplierName ?? '',
          'supplier_phone': draft.supplierPhone,
          'supplier_address': draft.supplierAddress,
          'transaction_date': draft.transactionDate,
          'receipt_number': draft.receiptNumber,
          'items': draft.items.map((e) => e.toJson()).toList(),
          'discount': draft.discount,
          'total': total,
          'payment_method': draft.paymentMethod,
          'input_source': 'OCR',
          'evidence_url': evidenceUrl,
        },
      );

      if (response.statusCode == 200) {
        return CommitTransactionResponse.fromJson(response.data);
      }
      return CommitTransactionResponse(
        success: false,
        message: 'Server returned status ${response.statusCode}',
      );
    } catch (e) {
      print("Error Commit Transaction API: $e");
      return CommitTransactionResponse(
        success: false,
        message: 'Gagal menyimpan: $e',
      );
    }
  }

  // 5. Get Transactions List (for Home Page)
  Future<List<TransactionListItem>> getTransactions({
    int limit = 20,
    int offset = 0,
    String? contactId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit, 'offset': offset};
      if (contactId != null) {
        queryParams['contact_id'] = contactId;
      }
      final response = await _dio.get(
        '/api/v1/transactions',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => TransactionListItem.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error Get Transactions API: $e");
      return [];
    }
  }

  // 6. Get Transaction Detail (for Detail Page)
  Future<TransactionDetailResponse?> getTransactionDetail(
    String transactionId,
  ) async {
    try {
      final response = await _dio.get('/api/v1/transactions/$transactionId');

      if (response.statusCode == 200) {
        return TransactionDetailResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error Get Transaction Detail API: $e");
      return null;
    }
  }

  // 7. Get Contacts List (for Contact Page)
  Future<List<ContactItem>> getContacts({
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit, 'offset': offset};
      if (type != null) {
        queryParams['type'] = type;
      }

      final response = await _dio.get(
        '/api/v1/contacts',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => ContactItem.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error Get Contacts API: $e");
      return [];
    }
  }

  // 8. Create Contact
  Future<ContactItem?> createContact(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/v1/contacts', data: data);

      if (response.statusCode == 200) {
        return ContactItem.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error Create Contact API: $e");
      return null;
    }
  }

  // 9. Update Contact
  Future<ContactItem?> updateContact(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/api/v1/contacts/$id', data: data);

      if (response.statusCode == 200) {
        return ContactItem.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error Update Contact API: $e");
      return null;
    }
  }

  // 10. Get Contact Stats
  Future<Map<String, dynamic>?> getContactStats(String contactId) async {
    try {
      final response = await _dio.get('/api/v1/contacts/$contactId/stats');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Error Get Contact Stats API: $e");
      return null;
    }
  }
}

/// Response model for commit transaction
class CommitTransactionResponse {
  final bool success;
  final String? transactionId;
  final String? invoiceNumber;
  final int? itemsProcessed;
  final int? newProductsCreated;
  final String message;

  CommitTransactionResponse({
    required this.success,
    this.transactionId,
    this.invoiceNumber,
    this.itemsProcessed,
    this.newProductsCreated,
    required this.message,
  });

  factory CommitTransactionResponse.fromJson(Map<String, dynamic> json) {
    return CommitTransactionResponse(
      success: json['success'] ?? false,
      transactionId: json['transaction_id'],
      invoiceNumber: json['invoice_number'],
      itemsProcessed: json['items_processed'],
      newProductsCreated: json['new_products_created'],
      message: json['message'] ?? '',
    );
  }
}

/// Response model for transaction list item
class TransactionListItem {
  final String id;
  final String type; // "IN" or "OUT"
  final String transactionDate;
  final double totalAmount;
  final String? invoiceNumber;
  final String? paymentMethod;
  final String contactName;
  final String? contactPhone;
  final String? contactAddress;
  final String createdAt;

  TransactionListItem({
    required this.id,
    required this.type,
    required this.transactionDate,
    required this.totalAmount,
    this.invoiceNumber,
    this.paymentMethod,
    required this.contactName,
    this.contactPhone,
    this.contactAddress,
    required this.createdAt,
  });

  factory TransactionListItem.fromJson(Map<String, dynamic> json) {
    return TransactionListItem(
      id: json['id'] ?? '',
      type: json['type'] ?? 'IN',
      transactionDate: json['transaction_date'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      invoiceNumber: json['invoice_number'],
      paymentMethod: json['payment_method'],
      contactName: json['contact_name'] ?? 'Unknown',
      contactPhone: json['contact_phone'],
      contactAddress: json['contact_address'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

/// Response model for transaction item detail
class TransactionItemResponse {
  final String id;
  final String productName;
  final String? variant;
  final double qty;
  final String unit;
  final double unitPrice;
  final double subtotal;
  final String? notes;

  TransactionItemResponse({
    required this.id,
    required this.productName,
    this.variant,
    required this.qty,
    required this.unit,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
  });

  factory TransactionItemResponse.fromJson(Map<String, dynamic> json) {
    return TransactionItemResponse(
      id: json['id'] ?? '',
      productName: json['product_name'] ?? 'Unknown',
      variant: json['variant'],
      qty: (json['qty'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'pcs',
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      notes: json['notes'],
    );
  }
}

/// Full transaction detail response
class TransactionDetailResponse {
  final String id;
  final String type;
  final String transactionDate;
  final double totalAmount;
  final String? invoiceNumber;
  final String? paymentMethod;
  final String contactName;
  final String? contactPhone;
  final String? contactAddress;
  final String createdAt;
  final List<TransactionItemResponse> items;

  TransactionDetailResponse({
    required this.id,
    required this.type,
    required this.transactionDate,
    required this.totalAmount,
    this.invoiceNumber,
    this.paymentMethod,
    required this.contactName,
    this.contactPhone,
    this.contactAddress,
    required this.createdAt,
    required this.items,
  });

  factory TransactionDetailResponse.fromJson(Map<String, dynamic> json) {
    return TransactionDetailResponse(
      id: json['id'] ?? '',
      type: json['type'] ?? 'IN',
      transactionDate: json['transaction_date'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      invoiceNumber: json['invoice_number'],
      paymentMethod: json['payment_method'],
      contactName: json['contact_name'] ?? 'Unknown',
      contactPhone: json['contact_phone'],
      contactAddress: json['contact_address'],
      createdAt: json['created_at'] ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => TransactionItemResponse.fromJson(e))
          .toList(),
    );
  }
}

/// Response model for contact list item
class ContactItem {
  final String id;
  final String name;
  final String type; // "CUSTOMER" or "SUPPLIER"
  final String? phone;
  final String? address;
  final String? notes;
  final String createdAt;

  ContactItem({
    required this.id,
    required this.name,
    required this.type,
    this.phone,
    this.address,
    this.notes,
    required this.createdAt,
  });

  factory ContactItem.fromJson(Map<String, dynamic> json) {
    return ContactItem(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      type: json['type'] ?? 'CUSTOMER',
      phone: json['phone'],
      address: json['address'],
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
    );
  }

  /// Get initial letters from name (for avatar display)
  String get initial {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0].substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'NA';
  }
}
