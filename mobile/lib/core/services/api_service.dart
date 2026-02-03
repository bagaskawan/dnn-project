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
