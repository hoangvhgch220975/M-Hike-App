// lib/models/observation.dart

import 'media_item.dart';

class Observation {
  int? id;
  int hikeId; // Khoá ngoại liên kết với Hike
  String caption;
  String content;
  String time; // Thời gian quan sát

  List<MediaItem> media; // Danh sách media (ảnh/video)

  Observation({
    this.id,
    required this.hikeId,
    required this.caption,
    required this.content,
    required this.time,
    this.media = const [], // Khởi tạo rỗng
  });

  // Chuyển đổi đối tượng Observation thành Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hikeId': hikeId,
      'caption': caption,
      'content': content,
      'time': time,
      // Lưu ý: media không được lưu trực tiếp ở đây, mà được lưu trong bảng riêng.
    };
  }

  // Tạo đối tượng Observation từ Map
  factory Observation.fromMap(Map<String, dynamic> map) {
    return Observation(
      id: map['id'] as int?,
      hikeId: map['hikeId'] as int,
      caption: map['caption'] as String,
      content: map['content'] as String,
      time: map['time'] as String,
      // media sẽ được thêm vào sau khi lấy từ DbHelper
      media: [],
    );
  }
}