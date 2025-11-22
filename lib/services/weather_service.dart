// lib/services/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Model dữ liệu thời tiết
class WeatherData {
  final double temperature;        // Nhiệt độ (°C)
  final String condition;          // Tình trạng thời tiết (Sunny, Cloudy, Rain, etc.)
  final String description;        // Mô tả chi tiết
  final double humidity;           // Độ ẩm (%)
  final double windSpeed;          // Tốc độ gió (km/h)
  final String icon;               // Icon code từ API
  final DateTime timestamp;        // Thời gian lấy dữ liệu

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
    required this.timestamp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['main']['temp'].toDouble(),
      condition: json['weather'][0]['main'],
      description: json['weather'][0]['description'],
      humidity: json['main']['humidity'].toDouble(),
      windSpeed: json['wind']['speed'].toDouble(),
      icon: json['weather'][0]['icon'],
      timestamp: DateTime.now(),
    );
  }

  /// Lấy icon URL từ OpenWeatherMap
  String getIconUrl() {
    return 'https://openweathermap.org/img/wn/$icon@2x.png';
  }

  /// Lấy icon emoji dựa trên condition
  String getEmoji() {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌡️';
    }
  }
}

/// Service lấy thông tin thời tiết (Feature 9: Weather API)
class WeatherService {
  // TODO: Thay YOUR_API_KEY bằng API key thật từ OpenWeatherMap
  // Đăng ký miễn phí tại: https://openweathermap.org/api
  static const String _apiKey = 'YOUR_API_KEY';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Lấy thời tiết theo tọa độ (lat, lng)
  Future<WeatherData?> getWeatherByCoordinates(double lat, double lng) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lng&appid=$_apiKey&units=metric&lang=vi',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        print('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return null;
    }
  }

  /// Lấy thời tiết theo tên thành phố
  Future<WeatherData?> getWeatherByCity(String cityName) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric&lang=vi',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        print('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return null;
    }
  }

  /// Lấy dự báo thời tiết 5 ngày (3 giờ/lần)
  Future<List<WeatherData>?> getForecast(double lat, double lng) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$lat&lon=$lng&appid=$_apiKey&units=metric&lang=vi',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['list'];

        return list.map((item) => WeatherData.fromJson(item)).toList();
      } else {
        print('Forecast API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching forecast: $e');
      return null;
    }
  }

  /// Lấy thời tiết MOCK (dùng khi chưa có API key)
  Future<WeatherData> getMockWeather(double lat, double lng) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Tạo dữ liệu giả dựa trên vị trí
    if (lat > 20 && lng < 110) {
      // Vietnam region
      return WeatherData(
        temperature: 28.5,
        condition: 'Sunny',
        description: 'Trời nắng, nhiều mây',
        humidity: 75,
        windSpeed: 15.5,
        icon: '01d',
        timestamp: DateTime.now(),
      );
    } else if (lat > 40) {
      // Northern region
      return WeatherData(
        temperature: 15.2,
        condition: 'Clouds',
        description: 'Nhiều mây',
        humidity: 60,
        windSpeed: 20.3,
        icon: '03d',
        timestamp: DateTime.now(),
      );
    } else {
      // Default
      return WeatherData(
        temperature: 22.0,
        condition: 'Clear',
        description: 'Trời quang đãng',
        humidity: 50,
        windSpeed: 10.0,
        icon: '01d',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Kiểm tra thời tiết có thích hợp để đi hiking không
  bool isGoodForHiking(WeatherData weather) {
    // Điều kiện lý tưởng:
    // - Nhiệt độ: 15-30°C
    // - Không mưa/bão
    // - Gió không quá mạnh (< 30 km/h)

    bool goodTemp = weather.temperature >= 15 && weather.temperature <= 30;
    bool goodCondition = !['rain', 'thunderstorm', 'snow'].contains(
      weather.condition.toLowerCase(),
    );
    bool goodWind = weather.windSpeed < 30;

    return goodTemp && goodCondition && goodWind;
  }

  /// Lấy khuyến nghị dựa trên thời tiết
  String getHikingRecommendation(WeatherData weather) {
    if (weather.condition.toLowerCase().contains('rain')) {
      return '🌧️ Không nên đi hiking. Đường có thể trơn trượt và nguy hiểm.';
    }

    if (weather.condition.toLowerCase().contains('thunderstorm')) {
      return '⛈️ Rất nguy hiểm! Không nên đi hiking trong cơn bão.';
    }

    if (weather.temperature > 35) {
      return '🔥 Quá nóng! Cân nhắc đi vào buổi sáng sớm hoặc chiều tối.';
    }

    if (weather.temperature < 5) {
      return '❄️ Quá lạnh! Chuẩn bị quần áo ấm và đồ bảo hộ.';
    }

    if (weather.windSpeed > 30) {
      return '💨 Gió mạnh! Cẩn thận khi đi trên vùng cao.';
    }

    if (isGoodForHiking(weather)) {
      return '✅ Thời tiết tuyệt vời để đi hiking!';
    }

    return '⚠️ Thời tiết chấp nhận được. Chuẩn bị kỹ trước khi đi.';
  }

  /// Format nhiệt độ
  String formatTemperature(double temp) {
    return '${temp.toStringAsFixed(1)}°C';
  }

  /// Format tốc độ gió
  String formatWindSpeed(double speed) {
    return '${speed.toStringAsFixed(1)} km/h';
  }

  /// Format độ ẩm
  String formatHumidity(double humidity) {
    return '${humidity.toStringAsFixed(0)}%';
  }
}

