// lib/viewmodels/observation_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/observation.dart';
import '../models/media_item.dart';
import '../db/app_db.dart';
import '../services/media_service.dart';

class ObservationViewModel extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final MediaService _mediaService = MediaService();

  // Form fields
  String caption = '';
  String content = '';
  String time = '';
  List<MediaItem> media = [];

  // Current hike context
  int? currentHikeId;

  // List of observations for a hike
  List<Observation> observations = [];

  // Pagination
  int page = 0;
  static const int pageSize = 20;
  bool isLoading = false;
  bool hasMore = true;

  // Initialize for a specific hike
  Future<void> initialize(int hikeId) async {
    currentHikeId = hikeId;
    page = 0;
    observations.clear();
    hasMore = true;
    await loadMore();
  }

  // Load more observations (infinity scroll)
  Future<void> loadMore() async {
    if (isLoading || !hasMore || currentHikeId == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final newItems = await AppDatabase.instance.getObservationsByHikePaged(
        currentHikeId!,
        page,
        pageSize,
      );

      if (newItems.isEmpty) {
        hasMore = false;
      } else {
        observations.addAll(newItems);
        page++;
      }
    } catch (e) {
      debugPrint('Error loading observations: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Reset form
  void resetForm() {
    caption = '';
    content = '';
    time = '';
    media.clear();
    formKey.currentState?.reset();
    notifyListeners();
  }

  // Load observation for editing
  void loadObservation(Observation observation) {
    caption = observation.caption;
    content = observation.content;
    time = observation.time;
    media = List.from(observation.media);
    notifyListeners();
  }

  // Pick single image
  Future<void> pickImage() async {
    try {
      final path = await _mediaService.pickImageFromGallery();
      if (path != null) {
        media.add(MediaItem(
          observationId: 0, // Will be set when saving
          path: path,
          type: 'image',
        ));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // Pick multiple images
  Future<void> pickMultipleImages() async {
    try {
      final paths = await _mediaService.pickMultiImage();
      for (final path in paths) {
        media.add(MediaItem(
          observationId: 0,
          path: path,
          type: 'image',
        ));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
    }
  }

  // Pick single video
  Future<void> pickVideo() async {
    try {
      final path = await _mediaService.pickVideoFromGallery();
      if (path != null) {
        media.add(MediaItem(
          observationId: 0,
          path: path,
          type: 'video',
        ));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  // Pick multiple videos
  Future<void> pickMultipleVideos() async {
    try {
      final paths = await _mediaService.pickMultiVideo();
      for (final path in paths) {
        media.add(MediaItem(
          observationId: 0,
          path: path,
          type: 'video',
        ));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error picking multiple videos: $e');
    }
  }

  // Take photo with camera
  Future<void> takePhoto() async {
    try {
      final path = await _mediaService.pickImageFromCamera();
      if (path != null) {
        media.add(MediaItem(
          observationId: 0,
          path: path,
          type: 'image',
        ));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  // Record video with camera
  Future<void> recordVideo() async {
    try {
      final path = await _mediaService.recordVideoFromCamera();
      if (path != null) {
        media.add(MediaItem(
          observationId: 0,
          path: path,
          type: 'video',
        ));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error recording video: $e');
    }
  }

  // Remove media item
  void removeMedia(int index) {
    if (index >= 0 && index < media.length) {
      media.removeAt(index);
      notifyListeners();
    }
  }

  // Save observation (create or update)
  Future<bool> saveObservation({int? id, int? hikeId}) async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    final targetHikeId = hikeId ?? currentHikeId;
    if (targetHikeId == null) {
      debugPrint('Error: No hike ID provided');
      return false;
    }

    try {
      final observation = Observation(
        id: id,
        hikeId: targetHikeId,
        caption: caption,
        content: content,
        time: time.isEmpty ? DateTime.now().toString() : time,
        media: media,
      );

      int observationId;
      if (id == null) {
        // Create new
        observationId = await AppDatabase.instance.insertObservation(observation);
      } else {
        // Update existing
        await AppDatabase.instance.updateObservation(observation);
        observationId = id;
      }

      // Save media items
      for (final mediaItem in media) {
        mediaItem.observationId = observationId;
        if (mediaItem.id == null) {
          await AppDatabase.instance.insertMediaItem(mediaItem);
        } else {
          await AppDatabase.instance.updateMediaItem(mediaItem);
        }
      }

      // Refresh list
      if (currentHikeId != null) {
        await initialize(currentHikeId!);
      }

      return true;
    } catch (e) {
      debugPrint('Error saving observation: $e');
      return false;
    }
  }

  // Delete observation
  Future<bool> deleteObservation(int id) async {
    try {
      await AppDatabase.instance.deleteObservation(id);

      // Remove from local list
      observations.removeWhere((obs) => obs.id == id);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting observation: $e');
      return false;
    }
  }

  // Get observation by id
  Future<Observation?> getObservationById(int id) async {
    try {
      return await AppDatabase.instance.getObservationById(id);
    } catch (e) {
      debugPrint('Error getting observation: $e');
      return null;
    }
  }

  // Get all observations for a hike
  Future<void> loadAllObservations(int hikeId) async {
    try {
      observations = await AppDatabase.instance.getObservationsByHike(hikeId);
      currentHikeId = hikeId;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading all observations: $e');
    }
  }
}
