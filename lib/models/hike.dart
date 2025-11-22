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
    };
  }

  // Tạo đối tượng Hike từ Map đọc từ SQLite
  factory Hike.fromMap(Map<String, dynamic> map) {
    return Hike(
      id: map['id'] as int?,
      name: map['name'] as String,
      location: map['location'] as String,
      date: map['date'] as String,
      length: map['length'] as double,
      difficulty: map['difficulty'] as String,
      description: map['description'] as String?,
      // Chuyển int thành bool
      isComplete: (map['isComplete'] as int) == 1,
      isRemarkable: (map['isRemarkable'] as int) == 1,
      // observations sẽ được thêm vào sau khi lấy từ database
      observations: [],
    );
  }
}