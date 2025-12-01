// lib/models/weather_data.dart

/// Model dữ liệu thời tiết
class WeatherData {
  int? id; // ID trong database (null khi chưa lưu)
  int? hikeId; // Foreign key đến bảng hikes
  final double temperature;        // Nhiệt độ (°C)
  final String condition;          // Tình trạng thời tiết (Sunny, Cloudy, Rain, etc.)
  final String description;        // Mô tả chi tiết
  final double humidity;           // Độ ẩm (%)
  final double windSpeed;          // Tốc độ gió (km/h)
  final String icon;               // Icon code từ API
  final DateTime timestamp;        // Thời gian lấy dữ liệu
  final String forecastDate;       // Ngày dự báo (YYYY-MM-DD format)

  WeatherData({
    this.id,
    this.hikeId,
    required this.temperature,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
    required this.timestamp,
    required this.forecastDate,
  });

  /// Tạo WeatherData từ JSON API
  /// Create WeatherData from API JSON
  factory WeatherData.fromJson(
    Map<String, dynamic> json, {
    DateTime? hikeDate, // Hike plan date (from date field in hikes table)
  }) {
    // Handle both current weather and forecast API responses
    final main = json['main'];
    final weather = json['weather'][0];
    final wind = json['wind'];

    // For forecast API, use dt_txt; for current weather, use current timestamp
    String forecastDate;

    if (json.containsKey('dt_txt')) {
      // Forecast API format: "2024-01-15 12:00:00"
      forecastDate = json['dt_txt'].toString().split(' ')[0];
    } else {
      // Current weather API - use today's date
      forecastDate = DateTime.now().toIso8601String().split('T')[0];
    }

    // timestamp = hike plan date (same for all forecasts of a hike)
    // forecastDate = individual forecast date (different for each day)
    final DateTime timestamp = hikeDate ?? DateTime.now();

    return WeatherData(
      temperature: main['temp'].toDouble(),
      condition: weather['main'],
      description: weather['description'],
      humidity: main['humidity'].toDouble(),
      windSpeed: wind['speed'].toDouble(),
      icon: weather['icon'],
      timestamp: timestamp, // Use hike plan date as timestamp
      forecastDate: forecastDate, // Keep individual forecast date
    );
  }

  /// Chuyển đối tượng WeatherData thành Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hikeId': hikeId,
      'temperature': temperature,
      'condition': condition,
      'description': description,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'icon': icon,
      'timestamp': timestamp.toIso8601String(),
      'forecastDate': forecastDate,
    };
  }

  /// Tạo đối tượng WeatherData từ Map đọc từ SQLite
  factory WeatherData.fromMap(Map<String, dynamic> map) {
    return WeatherData(
      id: map['id'] as int?,
      hikeId: map['hikeId'] as int?,
      temperature: (map['temperature'] as num).toDouble(),
      condition: map['condition'] as String,
      description: map['description'] as String,
      humidity: (map['humidity'] as num).toDouble(),
      windSpeed: (map['windSpeed'] as num).toDouble(),
      icon: map['icon'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      forecastDate: map['forecastDate'] as String,
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

  /// Copy with method for creating modified copies
  WeatherData copyWith({
    int? id,
    int? hikeId,
    double? temperature,
    String? condition,
    String? description,
    double? humidity,
    double? windSpeed,
    String? icon,
    DateTime? timestamp,
    String? forecastDate,
  }) {
    return WeatherData(
      id: id ?? this.id,
      hikeId: hikeId ?? this.hikeId,
      temperature: temperature ?? this.temperature,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      icon: icon ?? this.icon,
      timestamp: timestamp ?? this.timestamp,
      forecastDate: forecastDate ?? this.forecastDate,
    );
  }
}

