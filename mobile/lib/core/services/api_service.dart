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
}
