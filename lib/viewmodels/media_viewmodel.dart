// lib/viewmodels/media_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/media_service.dart';
import '../db/app_db.dart';


class MediaViewModel extends ChangeNotifier {
  final MediaService _mediaService = MediaService();

  // Current media items for viewing
  List<MediaItem> mediaItems = [];

  // Current index for gallery view
  int currentIndex = 0;

  // Loading state
  bool isLoading = false;

  // Initialize with media items
  void initialize(List<MediaItem> items, {int initialIndex = 0}) {
    mediaItems = items;
    currentIndex = initialIndex;
    notifyListeners();
  }

  // Load media for an observation
  Future<void> loadMediaForObservation(int observationId) async {
    isLoading = true;
    notifyListeners();

    try {
      mediaItems = await DbHelper.instance.getMediaForObservation(observationId);
      currentIndex = 0;
    } catch (e) {
      debugPrint('Error loading media: $e');
      mediaItems = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Set current index
  void setCurrentIndex(int index) {
    if (index >= 0 && index < mediaItems.length) {
      currentIndex = index;
      notifyListeners();
    }
  }

  // Go to next media
  void nextMedia() {
    if (currentIndex < mediaItems.length - 1) {
      currentIndex++;
      notifyListeners();
    }
  }

  // Go to previous media
  void previousMedia() {
    if (currentIndex > 0) {
      currentIndex--;
      notifyListeners();
    }
  }

  // Get current media item
  MediaItem? get currentMedia {
    if (mediaItems.isEmpty || currentIndex >= mediaItems.length) {
      return null;
    }
    return mediaItems[currentIndex];
  }

  // Filter by type
  List<MediaItem> get images => mediaItems.where((m) => m.type == 'image').toList();
  List<MediaItem> get videos => mediaItems.where((m) => m.type == 'video').toList();

  // Pick image and add to list
  Future<MediaItem?> pickAndAddImage(int observationId) async {
    try {
      final path = await _mediaService.pickImageFromGallery();
      if (path != null) {
        final mediaItem = MediaItem(
          observationId: observationId,
          path: path,
          type: 'image',
        );

        // Save to database
        final id = await DbHelper.instance.insertMediaItem(mediaItem);
        mediaItem.id = id;

        // Add to local list
        mediaItems.add(mediaItem);
        notifyListeners();

        return mediaItem;
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  // Pick video and add to list
  Future<MediaItem?> pickAndAddVideo(int observationId) async {
    try {
      final path = await _mediaService.pickVideoFromGallery();
      if (path != null) {
        final mediaItem = MediaItem(
          observationId: observationId,
          path: path,
          type: 'video',
        );

        // Save to database
        final id = await DbHelper.instance.insertMediaItem(mediaItem);
        mediaItem.id = id;

        // Add to local list
        mediaItems.add(mediaItem);
        notifyListeners();

        return mediaItem;
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
    return null;
  }

  // Take photo with camera and add to list
  Future<MediaItem?> takePhotoAndAdd(int observationId) async {
    try {
      final path = await _mediaService.pickImageFromCamera();
      if (path != null) {
        final mediaItem = MediaItem(
          observationId: observationId,
          path: path,
          type: 'image',
        );

        // Save to database
        final id = await DbHelper.instance.insertMediaItem(mediaItem);
        mediaItem.id = id;

        // Add to local list
        mediaItems.add(mediaItem);
        notifyListeners();

        return mediaItem;
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
    return null;
  }

  // Record video with camera and add to list
  Future<MediaItem?> recordVideoAndAdd(int observationId) async {
    try {
      final path = await _mediaService.recordVideoFromCamera();
      if (path != null) {
        final mediaItem = MediaItem(
          observationId: observationId,
          path: path,
          type: 'video',
        );

        // Save to database
        final id = await DbHelper.instance.insertMediaItem(mediaItem);
        mediaItem.id = id;

        // Add to local list
        mediaItems.add(mediaItem);
        notifyListeners();

        return mediaItem;
      }
    } catch (e) {
      debugPrint('Error recording video: $e');
    }
    return null;
  }

  // Delete media item
  Future<bool> deleteMedia(int id) async {
    try {
      await DbHelper.instance.deleteMediaItem(id);
      mediaItems.removeWhere((m) => m.id == id);

      // Adjust current index if needed
      if (currentIndex >= mediaItems.length && mediaItems.isNotEmpty) {
        currentIndex = mediaItems.length - 1;
      } else if (mediaItems.isEmpty) {
        currentIndex = 0;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting media: $e');
      return false;
    }
  }

  // Clear all media
  void clear() {
    mediaItems.clear();
    currentIndex = 0;
    notifyListeners();
  }
}

