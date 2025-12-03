// lib/services/ai_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hike.dart';
import '../models/ai_suggestion.dart';
import '../models/weather_data.dart';
import '../db/app_db.dart';

/// Service để gọi AI backend (Python FastAPI)
class AIService {
  // URL của AI backend - Backend đang chạy tại localhost:8000
  // Đang dùng 10.0.2.2 cho Android Emulator (10.0.2.2 = localhost của máy host)

  static const String _baseUrl = 'http://10.0.2.2:8000'; // Android Emulator ✅

  // Thay đổi URL tùy theo thiết bị bạn đang test:
  // static const String _baseUrl = 'http://localhost:8000'; // iOS Simulator & Desktop
  // static const String _baseUrl = 'http://127.0.0.1:8000'; // Alternative localhost
  // static const String _baseUrl = 'http://192.168.1.100:8000'; // Real device (thay bằng IP máy tính của bạn)

  static const String _evaluateEndpoint = '/api/hike-ai/evaluate';

  /// Lấy AI suggestion cho một hike
  /// Nếu đã có trong database, trả về kết quả đã lưu
  /// Nếu chưa có, gọi API để tạo mới và lưu vào database
  static Future<AISuggestion?> getOrGenerateAISuggestion(Hike hike) async {
    if (hike.id == null) {
      throw Exception('Hike must have an ID');
    }

    // Kiểm tra xem đã có AI suggestion chưa
    final existingSuggestion = await AppDatabase.instance.getAISuggestionByHikeId(hike.id!);
    if (existingSuggestion != null) {
      return existingSuggestion;
    }

    // Nếu chưa có, gọi API để tạo mới
    return await generateAISuggestion(hike);
  }

  /// Gọi API để tạo AI suggestion mới
  static Future<AISuggestion?> generateAISuggestion(Hike hike) async {
    if (hike.id == null) {
      throw Exception('Hike must have an ID');
    }

    try {
      // Lấy weather data từ database
      final weatherMaps = await AppDatabase.instance.getWeatherForecastsByHike(hike.id!);
      final List<Map<String, dynamic>> weatherData = weatherMaps.map((map) {
        return {
          'temperature': map['temperature'],
          'condition': map['condition'],
          'description': map['description'],
          'humidity': map['humidity'],
          'windSpeed': map['windSpeed'],
          'icon': map['icon'],
          'forecastDate': map['forecastDate'],
        };
      }).toList();

      // Chuẩn bị request body
      final requestBody = {
        'id': hike.id,
        'name': hike.name,
        'location': hike.location,
        'date': hike.date,
        'length': hike.length,
        'difficulty': hike.difficulty,
        'description': hike.description ?? '',
        'hasParking': hike.hasParking,
        'estimatedDuration': hike.estimatedDuration ?? 1,
        'weather': weatherData,
      };

      // Gọi API
      final url = Uri.parse('$_baseUrl$_evaluateEndpoint');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - AI service took too long to respond');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final suggestion = AISuggestion.fromJson(responseData, hike.id!);

        // Lưu vào database
        final suggestionId = await AppDatabase.instance.insertAISuggestion(suggestion);
        return suggestion.copyWith(id: suggestionId);
      } else {
        throw Exception('Failed to generate AI suggestion: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error generating AI suggestion: $e');
      rethrow;
    }
  }

  /// Xóa AI suggestion và tạo lại (refresh)
  static Future<AISuggestion?> regenerateAISuggestion(Hike hike) async {
    if (hike.id == null) {
      throw Exception('Hike must have an ID');
    }

    // Xóa suggestion cũ
    await AppDatabase.instance.deleteAISuggestionByHikeId(hike.id!);

    // Tạo mới
    return await generateAISuggestion(hike);
  }

  /// Kiểm tra xem AI service có hoạt động không
  static Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$_baseUrl/health');
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('AI service health check failed: $e');
      return false;
    }
  }
}

