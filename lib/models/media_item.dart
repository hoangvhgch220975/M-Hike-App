// lib/models/media_item.dart

class MediaItem {
  int? id;
  int observationId; // Khoá ngoại liên kết với Observation
  String path; // Đường dẫn đến tệp (local file path)
  String type; // 'image' hoặc 'video'

  MediaItem({
    this.id,
    required this.observationId,
    required this.path,
    required this.type,
  });

  // Chuyển đổi đối tượng MediaItem thành Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'observationId': observationId,
      'path': path,
      'type': type,
    };
  }

  // Tạo đối tượng MediaItem từ Map
  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] as int?,
      observationId: map['observationId'] as int,
      path: map['path'] as String,
      type: map['type'] as String,
    );
  }
}