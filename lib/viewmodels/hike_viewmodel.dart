// lib/viewmodels/hike_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/hike.dart';
import '../db/app_db.dart';

class HikeViewModel extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  // Form fields
  String name = '';
  String location = '';
  String date = '';
  double length = 0.0;
  String difficulty = 'Easy';
  String? description;
  bool isComplete = false;
  bool isRemarkable = false;

  // Lists for different categories
  List<Hike> hikes = [];
  List<Hike> feed = [];
  List<Hike> plan = [];
  List<Hike> remarkable = [];

  // Pagination
  int page = 0;
  static const int pageSize = 20;
  bool isLoading = false;
  bool hasMore = true;

  // Length tracking (manual vs auto from map)
  bool autoLength = false;
  double? manualLength;
  double? calculatedLength;

  // Initialize and load first page
  Future<void> initialize() async {
    page = 0;
    hikes.clear();
    feed.clear();
    plan.clear();
    remarkable.clear();
    hasMore = true;
    notifyListeners(); // Notify immediately to show empty state
    await loadMore();
  }

  // Load more hikes (infinity scroll)
  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;

    isLoading = true;
    notifyListeners();

    try {
      final newItems = await AppDatabase.instance.getHikesPaged(page, pageSize);

      if (newItems.isEmpty) {
        hasMore = false;
      } else {
        hikes.addAll(newItems);
        page++;
        _refreshCategories();
      }
    } catch (e) {
      debugPrint('Error loading hikes: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Refresh categories based on filters (load from database)
  Future<void> _refreshCategories() async {
    try {
      feed = await AppDatabase.instance.getCompletedHikes();
      plan = await AppDatabase.instance.getPlannedHikes();
      remarkable = await AppDatabase.instance.getRemarkableHikes();
      notifyListeners(); // Notify listeners after loading categories
    } catch (e) {
      debugPrint('Error refreshing categories: $e');
    }
  }

  // Set manual length (user input)
  void setManualLength(double value) {
    manualLength = value;
    length = value;
    autoLength = false;
    notifyListeners();
  }

  // Set auto length (from map calculation)
  void setAutoLength(double value) {
    calculatedLength = value;
    length = value;
    autoLength = true;
    notifyListeners();
  }

  // Reset form
  void resetForm() {
    name = '';
    location = '';
    date = '';
    length = 0.0;
    difficulty = 'Easy';
    description = null;
    isComplete = false;
    isRemarkable = false;
    autoLength = false;
    manualLength = null;
    calculatedLength = null;
    formKey.currentState?.reset();
    notifyListeners();
  }

  // Load hike for editing
  void loadHike(Hike hike) {
    name = hike.name;
    location = hike.location;
    date = hike.date;
    length = hike.length;
    difficulty = hike.difficulty;
    description = hike.description;
    isComplete = hike.isComplete;
    isRemarkable = hike.isRemarkable;
    notifyListeners();
  }

  // Save hike (create or update)
  Future<bool> saveHike({int? id}) async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    try {
      final hike = Hike(
        id: id,
        name: name,
        location: location,
        date: date,
        length: length,
        difficulty: difficulty,
        description: description,
        isComplete: isComplete,
        isRemarkable: isRemarkable,
      );

      if (id == null) {
        // Create new
        await AppDatabase.instance.insertHike(hike);
      } else {
        // Update existing
        await AppDatabase.instance.updateHike(hike);
      }

      // Refresh list
      await initialize();
      return true;
    } catch (e) {
      debugPrint('Error saving hike: $e');
      return false;
    }
  }

  // Delete hike
  Future<bool> deleteHike(int id) async {
    try {
      await AppDatabase.instance.deleteHike(id);

      // Remove from local list
      hikes.removeWhere((h) => h.id == id);
      _refreshCategories();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting hike: $e');
      return false;
    }
  }

  // Toggle complete status
  Future<void> toggleComplete(int id) async {
    final hike = hikes.firstWhere((h) => h.id == id);
    hike.isComplete = !hike.isComplete;
    await AppDatabase.instance.updateHike(hike);
    _refreshCategories();
    notifyListeners();
  }

  // Toggle remarkable status
  Future<void> toggleRemarkable(int id) async {
    final hike = hikes.firstWhere((h) => h.id == id);
    hike.isRemarkable = !hike.isRemarkable;
    await AppDatabase.instance.updateHike(hike);
    _refreshCategories();
    notifyListeners();
  }

  // Mark hike as completed
  Future<void> markHikeAsCompleted(int id) async {
    try {
      final hike = await AppDatabase.instance.getHikeById(id);
      if (hike != null) {
        hike.isComplete = true;
        await AppDatabase.instance.updateHike(hike);
        await _refreshCategories();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking hike as completed: $e');
    }
  }

  // Get hike by id
  Future<Hike?> getHikeById(int id) async {
    try {
      return await AppDatabase.instance.getHikeById(id);
    } catch (e) {
      debugPrint('Error getting hike: $e');
      return null;
    }
  }

  // Search hikes (using database search)
  Future<List<Hike>> searchHikes(String query) async {
    if (query.isEmpty) {
      return hikes;
    }

    try {
      return await AppDatabase.instance.searchHikes(query);
    } catch (e) {
      debugPrint('Error searching hikes: $e');
      return [];
    }
  }

  // Load completed hikes (Feed)
  Future<void> loadFeed({int? limit}) async {
    try {
      feed.clear(); // Clear old data first
      feed = await AppDatabase.instance.getCompletedHikes(limit: limit);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading feed: $e');
      feed.clear(); // Clear on error too
      notifyListeners();
    }
  }

  // Load planned hikes (Plan)
  Future<void> loadPlan({int? limit}) async {
    try {
      plan.clear(); // Clear old data first
      plan = await AppDatabase.instance.getPlannedHikes(limit: limit);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading plan: $e');
      plan.clear(); // Clear on error too
      notifyListeners();
    }
  }

  // Load remarkable hikes
  Future<void> loadRemarkable({int? limit}) async {
    try {
      remarkable.clear(); // Clear old data first
      remarkable = await AppDatabase.instance.getRemarkableHikes(limit: limit);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading remarkable: $e');
      remarkable.clear(); // Clear on error too
      notifyListeners();
    }
  }

  // Load recent hikes
  Future<List<Hike>> loadRecent({int limit = 10}) async {
    try {
      return await AppDatabase.instance.getRecentHikes(limit: limit);
    } catch (e) {
      debugPrint('Error loading recent hikes: $e');
      return [];
    }
  }

  // Filter hikes by difficulty
  Future<List<Hike>> filterByDifficulty(String difficulty) async {
    try {
      return await AppDatabase.instance.getHikesByDifficulty(difficulty);
    } catch (e) {
      debugPrint('Error filtering by difficulty: $e');
      return [];
    }
  }

  // Advanced filter
  Future<List<Hike>> filterHikes({
    String? difficulty,
    bool? isComplete,
    bool? isRemarkable,
    double? minLength,
    double? maxLength,
    String? orderBy,
  }) async {
    try {
      return await AppDatabase.instance.filterHikes(
        difficulty: difficulty,
        isComplete: isComplete,
        isRemarkable: isRemarkable,
        minLength: minLength,
        maxLength: maxLength,
        orderBy: orderBy,
      );
    } catch (e) {
      debugPrint('Error filtering hikes: $e');
      return [];
    }
  }

  // Get total count
  Future<int> getTotalCount() async {
    try {
      return await AppDatabase.instance.getHikesCount();
    } catch (e) {
      debugPrint('Error getting count: $e');
      return 0;
    }
  }
}
