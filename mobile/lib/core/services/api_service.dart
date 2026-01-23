import 'dart:io';
import 'package:dio/dio.dart';
import '../../models/procurement_draft.dart';

class ApiService {
  // GANTI IP INI SESUAI DEVICE KAMU!
  // Android Emulator: 'http://10.0.2.2:8000'
  // iOS Simulator: 'http://127.0.0.1:8000'
  // HP Fisik: Cek IP Laptop (ipconfig/ifconfig), misal 'http://192.168.1.X:8000'
  static const String baseUrl = 'http://10.0.2.2:8000';

  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));

  // 1. Kirim Chat Teks dengan context draft saat ini
  Future<ProcurementDraft?> parseText(
    String text, {
    ProcurementDraft? currentDraft,
  }) async {
    try {
      final data = {
        'text': text,
        if (currentDraft != null) 'current_draft': currentDraft.toJson(),
      };

      final response = await _dio.post('/api/v1/parse/text', data: data);

      if (response.statusCode == 200) {
        return ProcurementDraft.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error Text API: $e");
      return null;
    }
  }

  // 2. Kirim Gambar Struk
  Future<ProcurementDraft?> parseImage(
    File imageFile, {
    ProcurementDraft? currentDraft,
  }) async {
    try {
      String fileName = imageFile.path.split('/').last;

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
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
