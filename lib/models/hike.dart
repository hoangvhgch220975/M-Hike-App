// lib/models/hike.dart

import 'observation.dart';

class Hike {
  int? id; // ID trong cơ sở dữ liệu (có thể null khi tạo mới)
  String name;
  String location;
  String date; // Nên lưu dưới dạng String hoặc int (timestamp)
  double length;
  String difficulty;
  String? description;
  bool isComplete; // Dùng để lọc Feed/Plan
  bool isRemarkable; // Dùng để lọc Remarkable
  bool hasParking; // New: Có chỗ đỗ xe hay không (yes/no)
  int? estimatedDuration; // New: Số ngày dự kiến (duration in days) - nullable for backward compatibility
  double? latitude; // Latitude from map picker
  double? longitude; // Longitude from map picker
  bool isMapPicked; // Flag to indicate if location was picked from map
  bool isLengthFromMap; // Flag to indicate if length was calculated from map
  List<Observation> observations; // Danh sách observations liên quan

  Hike({
    this.id,
    required this.name,
    required this.location,
    required this.date,
    required this.length,
    required this.difficulty,
    this.description,
    this.isComplete = false,
    this.isRemarkable = false,
    this.hasParking = false,
    this.estimatedDuration, // Can be null for old records
    this.latitude,
    this.longitude,
    this.isMapPicked = false,
    this.isLengthFromMap = false,
    this.observations = const [], // Khởi tạo rỗng
  });

  // Chuyển đổi đối tượng Hike thành Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'date': date,
      'length': length,
      'difficulty': difficulty,
      'description': description,
      // Lưu bool dưới dạng int (1 cho true, 0 cho false) trong SQLite
      'isComplete': isComplete ? 1 : 0,
      'isRemarkable': isRemarkable ? 1 : 0,
      'hasParking': hasParking ? 1 : 0,
      'estimatedDuration': estimatedDuration ?? 1, // Default to 1 if null
      'latitude': latitude,
      'longitude': longitude,
      'isMapPicked': isMapPicked ? 1 : 0,
    };
  }

  // Tạo đối tượng Hike từ Map đọc từ SQLite
  factory Hike.fromMap(Map<String, dynamic> map) {
    // length in DB may be stored as int or real; handle both
    double parsedLength = 0.0;
    try {
      if (map['length'] is num) {
        parsedLength = (map['length'] as num).toDouble();
      } else if (map['length'] != null) {
        parsedLength = double.tryParse(map['length'].toString()) ?? 0.0;
      }
    } catch (_) {
      parsedLength = 0.0;
    }

    bool parseBool(dynamic v) {
      if (v == null) return false;
      if (v is int) return v == 1;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      return s == '1' || s == 'true' || s == 'yes';
    }

    // Parse estimatedDuration - return null if not present (for backward compatibility)
    int? parsedDuration;
    try {
      if (map.containsKey('estimatedDuration') && map['estimatedDuration'] != null) {
        parsedDuration = map['estimatedDuration'] is int
          ? map['estimatedDuration'] as int
          : int.tryParse(map['estimatedDuration'].toString());
      }
    } catch (_) {
      parsedDuration = null;
    }

    // Parse latitude/longitude - nullable for backward compatibility
    double? parsedLat;
    double? parsedLon;
    try {
      if (map.containsKey('latitude') && map['latitude'] != null) {
        parsedLat = map['latitude'] is double
            ? map['latitude'] as double
            : double.tryParse(map['latitude'].toString());
      }
      if (map.containsKey('longitude') && map['longitude'] != null) {
        parsedLon = map['longitude'] is double
            ? map['longitude'] as double
            : double.tryParse(map['longitude'].toString());
      }
    } catch (_) {
      parsedLat = null;
      parsedLon = null;
    }

    return Hike(
      id: map['id'] as int?,
      name: map['name'] as String,
      location: map['location'] as String,
      date: map['date'] as String,
      length: parsedLength,
      difficulty: map['difficulty'] as String,
      description: map['description'] as String?,
      // Chuyển int thành bool
      isComplete: parseBool(map['isComplete']),
      isRemarkable: parseBool(map['isRemarkable']),
      hasParking: parseBool(map['hasParking']),
      estimatedDuration: parsedDuration,
      latitude: parsedLat,
      longitude: parsedLon,
      isMapPicked: map.containsKey('isMapPicked') ? parseBool(map['isMapPicked']) : false,
      // observations sẽ được thêm vào sau khi lấy từ database
      observations: [],
    );
  }
}