// lib/services/media_service.dart

import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Service xử lý tất cả thao tác liên quan đến Media (Images, Videos)
class MediaService {
  final ImagePicker _picker = ImagePicker();

  // ============= IMAGE OPERATIONS =============

  /// Chụp ảnh bằng Camera (Feature 8)
  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? xFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return xFile?.path;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  /// Chọn 1 ảnh từ Gallery
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return xFile?.path;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Chọn nhiều ảnh từ Gallery (Feature 9: Multi Images)
  Future<List<String>> pickMultiImage({int? maxImages}) async {
    try {
      final List<XFile> xFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      // Giới hạn số lượng ảnh nếu cần
      List<XFile> selectedFiles = maxImages != null && xFiles.length > maxImages
          ? xFiles.sublist(0, maxImages)
          : xFiles;

      return selectedFiles.map((x) => x.path).toList();
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  // ============= VIDEO OPERATIONS =============

  /// Chọn Video từ Gallery
  Future<String?> pickVideoFromGallery() async {
    try {
      final XFile? xFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5), // Giới hạn 5 phút
      );
      return xFile?.path;
    } catch (e) {
      print('Error picking video from gallery: $e');
      return null;
    }
  }

  /// Quay Video bằng Camera
  Future<String?> recordVideoFromCamera() async {
    try {
      final XFile? xFile = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      return xFile?.path;
    } catch (e) {
      print('Error recording video: $e');
      return null;
    }
  }

  /// Chọn nhiều Video từ Gallery
  Future<List<String>> pickMultiVideo({int? maxVideos}) async {
    try {
      // Note: pickMultiVideo không có sẵn trong ImagePicker
      // Phải gọi pickVideo nhiều lần hoặc dùng file_picker package
      // Đây là workaround đơn giản
      List<String> videoPaths = [];

      int limit = maxVideos ?? 5;
      for (int i = 0; i < limit; i++) {
        final path = await pickVideoFromGallery();
        if (path != null) {
          videoPaths.add(path);
        } else {
          break; // User hủy việc chọn
        }
      }

      return videoPaths;
    } catch (e) {
      print('Error picking multiple videos: $e');
      return [];
    }
  }

  // ============= FILE VALIDATION =============

  /// Kiểm tra file có tồn tại không
  bool isFileExists(String path) {
    return File(path).existsSync();
  }

  /// Lấy kích thước file (bytes)
  int getFileSize(String path) {
    try {
      return File(path).lengthSync();
    } catch (e) {
      print('Error getting file size: $e');
      return 0;
    }
  }

  /// Lấy kích thước file (MB)
  double getFileSizeMB(String path) {
    int bytes = getFileSize(path);
    return bytes / (1024 * 1024);
  }

  /// Validate ảnh (kiểm tra kích thước và định dạng)
  bool validateImage(String path, {double maxSizeMB = 10}) {
    if (!isFileExists(path)) return false;

    double sizeMB = getFileSizeMB(path);
    if (sizeMB > maxSizeMB) return false;

    String ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  /// Validate video (kiểm tra kích thước và định dạng)
  bool validateVideo(String path, {double maxSizeMB = 50}) {
    if (!isFileExists(path)) return false;

    double sizeMB = getFileSizeMB(path);
    if (sizeMB > maxSizeMB) return false;

    String ext = path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', '3gp'].contains(ext);
  }

  // ============= FILE OPERATIONS =============

  /// Xóa file
  Future<bool> deleteFile(String path) async {
    try {
      File file = File(path);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  /// Xóa nhiều file
  Future<void> deleteMultipleFiles(List<String> paths) async {
    for (String path in paths) {
      await deleteFile(path);
    }
  }

  /// Xác định loại media từ extension
  String getMediaType(String path) {
    String ext = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
      return 'image';
    } else if (['mp4', 'mov', 'avi', 'mkv', '3gp', 'webm'].contains(ext)) {
      return 'video';
    }
    return 'unknown';
  }

  /// Kiểm tra path có phải là image không
  bool isImage(String path) {
    return getMediaType(path) == 'image';
  }

  /// Kiểm tra path có phải là video không
  bool isVideo(String path) {
    return getMediaType(path) == 'video';
  }

  // ============= COMPRESSION (Optional - requires packages) =============

  /// Note: Để nén ảnh/video cần thêm packages:
  /// - flutter_image_compress
  /// - video_compress
  /// Có thể implement sau nếu cần
}

