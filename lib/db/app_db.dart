// lib/db/app_db.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/hike.dart';
import '../models/observation.dart';
import '../models/media_item.dart';

// ============================================================================
// LỚP QUẢN LÝ DATABASE (SINGLETON)
// Chịu trách nhiệm khởi tạo DB và cung cấp các hàm CRUD cơ bản.
// ============================================================================
class AppDatabase {
  // Sử dụng Singleton Pattern: Chỉ có duy nhất một instance của AppDatabase
  static final AppDatabase instance = AppDatabase._privateConstructor();
  static Database? _database;

  AppDatabase._privateConstructor();

  // Tên Database và Version
  final String _dbName = 'm_hike_hybrid_app.db';
  // Reset to version 1 with all fields included from the start
  final int _dbVersion = 1;

  // Tên Bảng
  final String _hikeTable = 'hikes';
  final String _observationTable = 'observations';
  final String _mediaTable = 'media';
  final String _weatherTable = 'weather_forecasts';

  // Getter cho Database instance
  // Nếu database đã tồn tại (_database != null) thì trả về, ngược lại khởi tạo
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Khởi tạo Database: Mở hoặc tạo database tại đường dẫn xác định
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate, // Hàm tạo bảng
      onConfigure: _onConfigure, // Hàm bật Foreign Key
      onUpgrade: _onUpgrade, // Hàm xử lý nâng cấp schema (no-op for completed migration)
      onOpen: _onOpen,
    );
  }

  // onOpen — no runtime schema migrations performed here. The DB schema already contains `hasParking`.
  Future _onOpen(Database db) async {
    // intentionally left blank
  }

  // Bật chế độ Foreign Keys
  // Đảm bảo tính toàn vẹn dữ liệu khi xóa (ON DELETE CASCADE)
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Xử lý nâng cấp database
  // No migrations needed - version 1 includes all fields from the start
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // This should not be called since we're at version 1
    // If you need to upgrade in the future, add migration logic here
  }

  // Tạo các bảng khi database được tạo lần đầu
  Future _onCreate(Database db, int version) async {
    // 1. Bảng HIKES
    await db.execute('''
      CREATE TABLE $_hikeTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        date TEXT NOT NULL,
        length REAL NOT NULL,
        difficulty TEXT NOT NULL,
        description TEXT,
        isComplete INTEGER NOT NULL DEFAULT 0,
        isRemarkable INTEGER NOT NULL DEFAULT 0,
        hasParking INTEGER NOT NULL DEFAULT 0,
        estimatedDuration INTEGER NOT NULL DEFAULT 1,
        latitude REAL,
        longitude REAL,
        isMapPicked INTEGER NOT NULL DEFAULT 0,
        isLengthFromMap INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. Bảng OBSERVATIONS (Liên kết với HIKES)
    await db.execute('''
      CREATE TABLE $_observationTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hikeId INTEGER NOT NULL,
        caption TEXT NOT NULL,
        content TEXT NOT NULL,
        time TEXT NOT NULL,
        FOREIGN KEY (hikeId) REFERENCES $_hikeTable (id) ON DELETE CASCADE
      )
    ''');

    // 3. Bảng MEDIA (Liên kết với OBSERVATIONS)
    await db.execute('''
      CREATE TABLE $_mediaTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        observationId INTEGER NOT NULL,
        path TEXT NOT NULL,
        type TEXT NOT NULL,
        FOREIGN KEY (observationId) REFERENCES $_observationTable (id) ON DELETE CASCADE
      )
    ''');

    // 4. Bảng WEATHER_FORECASTS (Liên kết với HIKES)
    await db.execute('''
      CREATE TABLE $_weatherTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hikeId INTEGER NOT NULL,
        temperature REAL NOT NULL,
        condition TEXT NOT NULL,
        description TEXT NOT NULL,
        humidity REAL NOT NULL,
        windSpeed REAL NOT NULL,
        icon TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        forecastDate TEXT NOT NULL,
        FOREIGN KEY (hikeId) REFERENCES $_hikeTable (id) ON DELETE CASCADE
      )
    ''');
  }

  // ============================================================================
  // MARK: - CRUD Hikes (Feature 1, 4)
  // ============================================================================

   /// Thêm một chuyến đi mới vào bảng hikes.
   Future<int> insertHike(Hike hike) async {
     Database db = await instance.database;
     return await db.insert(_hikeTable, hike.toMap());
   }

   /// Lấy một Hike theo ID.
   Future<Hike?> getHikeById(int id) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       where: 'id = ?',
       whereArgs: [id],
     );
     if (maps.isNotEmpty) {
       return Hike.fromMap(maps.first);
     }
     return null;
   }

   /// Cập nhật thông tin của một Hike dựa trên ID.
   Future<int> updateHike(Hike hike) async {
     Database db = await instance.database;
     return await db.update(
       _hikeTable,
       hike.toMap(),
       where: 'id = ?',
       whereArgs: [hike.id],
     );
   }

   /// Xóa một Hike theo ID.
   /// Nhờ ON DELETE CASCADE, các Observations và Media liên quan sẽ tự động bị xóa.
   Future<int> deleteHike(int id) async {
     Database db = await instance.database;
     return await db.delete(
       _hikeTable,
       where: 'id = ?',
       whereArgs: [id],
     );
   }

   // Lấy tất cả Hikes (không phân trang).
   Future<List<Hike>> getAllHikes() async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       orderBy: 'date DESC',
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   /// Lấy danh sách Hike theo trang với kích thước tùy chỉnh (cho Infinity Scroll).
   Future<List<Hike>> getHikesPaged(int page, int pageSize) async {
     Database db = await instance.database;
     final offset = page * pageSize;

     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       limit: pageSize,
       offset: offset,
       orderBy: 'date DESC',
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   /// Đếm số lượng Hikes.
   Future<int> getHikesCount() async {
     Database db = await instance.database;
     final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_hikeTable');
     return Sqflite.firstIntValue(result) ?? 0;
   }

   /// Tìm kiếm Hikes theo tên hoặc địa điểm.
   Future<List<Hike>> searchHikes(String query) async {
     if (query.isEmpty) return [];

     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       where: 'name LIKE ? OR location LIKE ?',
       whereArgs: ['%$query%', '%$query%'],
       orderBy: 'date DESC',
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   /// Lấy danh sách Hikes đã hoàn thành (Feed).
   Future<List<Hike>> getCompletedHikes({int? limit}) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       where: 'isComplete = ?',
       whereArgs: [1],
       orderBy: 'date DESC',
       limit: limit,
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   /// Lấy danh sách Hikes chưa hoàn thành (Plan).
   Future<List<Hike>> getPlannedHikes({int? limit}) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       where: 'isComplete = ?',
       whereArgs: [0],
       orderBy: 'date DESC',
       limit: limit,
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   /// Lấy danh sách Hikes đáng nhớ (Remarkable).
   Future<List<Hike>> getRemarkableHikes({int? limit}) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       where: 'isRemarkable = ?',
       whereArgs: [1],
       orderBy: 'date DESC',
       limit: limit,
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   /// Lấy danh sách Hikes gần đây (Recent).
   Future<List<Hike>> getRecentHikes({int limit = 10}) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       orderBy: 'date DESC',
       limit: limit,
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   /// Lọc Hikes theo độ khó.
   Future<List<Hike>> getHikesByDifficulty(String difficulty) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       where: 'difficulty = ?',
       whereArgs: [difficulty],
       orderBy: 'date DESC',
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   /// Lọc Hikes theo nhiều tiêu chí (advanced filter).
   Future<List<Hike>> filterHikes({
     String? difficulty,
     bool? isComplete,
     bool? isRemarkable,
     double? minLength,
     double? maxLength,
     String? orderBy,
   }) async {
     Database db = await instance.database;

     List<String> whereClauses = [];
     List<dynamic> whereArgs = [];

     if (difficulty != null) {
       whereClauses.add('difficulty = ?');
       whereArgs.add(difficulty);
     }

     if (isComplete != null) {
       whereClauses.add('isComplete = ?');
       whereArgs.add(isComplete ? 1 : 0);
     }

     if (isRemarkable != null) {
       whereClauses.add('isRemarkable = ?');
       whereArgs.add(isRemarkable ? 1 : 0);
     }

     if (minLength != null) {
       whereClauses.add('length >= ?');
       whereArgs.add(minLength);
     }

     if (maxLength != null) {
       whereClauses.add('length <= ?');
       whereArgs.add(maxLength);
     }

     final whereClause = whereClauses.isEmpty ? null : whereClauses.join(' AND ');
     final order = orderBy ?? 'date DESC';

     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       where: whereClause,
       whereArgs: whereArgs.isEmpty ? null : whereArgs,
       orderBy: order,
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   // ============================================================================
   // MARK: - CRUD Observations (Feature 2)
   // ============================================================================

   /// Thêm một Observation mới vào bảng observations.
   Future<int> insertObservation(Observation observation) async {
     Database db = await instance.database;
     return await db.insert(_observationTable, observation.toMap());
   }

   /// Cập nhật Observation dựa trên ID.
   Future<int> updateObservation(Observation observation) async {
     Database db = await instance.database;
     return await db.update(
       _observationTable,
       observation.toMap(),
       where: 'id = ?',
       whereArgs: [observation.id],
     );
   }

   /// Xóa Observation theo ID.
   /// Nhờ ON DELETE CASCADE, các Media liên quan sẽ tự động bị xóa.
   Future<int> deleteObservation(int id) async {
     Database db = await instance.database;
     return await db.delete(
       _observationTable,
       where: 'id = ?',
       whereArgs: [id],
     );
   }

   /// Lấy Observation theo ID (kèm media).
   Future<Observation?> getObservationById(int id) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _observationTable,
       where: 'id = ?',
       whereArgs: [id],
     );

     if (maps.isNotEmpty) {
       Observation obs = Observation.fromMap(maps.first);
       // Load media
       if (obs.id != null) {
         obs.media = await getMediaForObservation(obs.id!);
       }
       return obs;
     }
     return null;
   }

   /// Lấy tất cả Observations theo hikeId (không phân trang, kèm media).
   Future<List<Observation>> getObservationsByHike(int hikeId) async {
     Database db = await instance.database;

     final List<Map<String, dynamic>> maps = await db.query(
       _observationTable,
       where: 'hikeId = ?',
       whereArgs: [hikeId],
       orderBy: 'time DESC',
     );

     List<Observation> observations = List.generate(maps.length, (i) {
       return Observation.fromMap(maps[i]);
     });

     // Load media for each observation
     for (var obs in observations) {
       if (obs.id != null) {
         obs.media = await getMediaForObservation(obs.id!);
       }
     }

     return observations;
   }

   /// Lấy danh sách Observation theo hikeId với phân trang (cho Infinity Scroll).
   Future<List<Observation>> getObservationsByHikePaged(
     int hikeId,
     int page,
     int pageSize,
   ) async {
     Database db = await instance.database;
     final offset = page * pageSize;

     final List<Map<String, dynamic>> maps = await db.query(
       _observationTable,
       where: 'hikeId = ?',
       whereArgs: [hikeId],
       orderBy: 'time DESC',
       limit: pageSize,
       offset: offset,
     );

     List<Observation> observations = List.generate(maps.length, (i) {
       return Observation.fromMap(maps[i]);
     });

     // Load media for each observation
     for (var obs in observations) {
       if (obs.id != null) {
         obs.media = await getMediaForObservation(obs.id!);
       }
     }

     return observations;
   }

   /// Đếm số lượng Observations theo hikeId.
   Future<int> getObservationsCount(int hikeId) async {
     Database db = await instance.database;
     final result = await db.rawQuery(
       'SELECT COUNT(*) as count FROM $_observationTable WHERE hikeId = ?',
       [hikeId],
     );
     return Sqflite.firstIntValue(result) ?? 0;
   }

   // ============================================================================
   // MARK: - CRUD Media Items (Feature 2)
   // ============================================================================

   /// Thêm danh sách MediaItem (ảnh/video) vào bảng media.
   /// Sử dụng transaction để đảm bảo tất cả được lưu thành công.
   Future<void> insertMediaItems(List<MediaItem> mediaList) async {
     Database db = await instance.database;
     await db.transaction((txn) async {
       for (final media in mediaList) {
         await txn.insert(_mediaTable, media.toMap());
       }
     });
   }

   /// Lấy danh sách MediaItem thuộc về một Observation cụ thể.
   Future<List<MediaItem>> getMediaForObservation(int observationId) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _mediaTable,
       where: 'observationId = ?',
       whereArgs: [observationId],
       orderBy: 'id ASC',
     );

     return List.generate(maps.length, (i) {
       return MediaItem.fromMap(maps[i]);
     });
   }

  /// Lấy một MediaItem cụ thể theo observationId và media id.
  Future<MediaItem?> getMediaItemByObservationAndId(int observationId, int mediaId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _mediaTable,
      where: 'observationId = ? AND id = ?',
      whereArgs: [observationId, mediaId],
      limit: 1,
    );

    if (maps.isNotEmpty) return MediaItem.fromMap(maps.first);
    return null;
  }

   /// Thêm một MediaItem.
   Future<int> insertMediaItem(MediaItem mediaItem) async {
     Database db = await instance.database;
     return await db.insert(_mediaTable, mediaItem.toMap());
   }

   /// Cập nhật MediaItem.
   Future<int> updateMediaItem(MediaItem mediaItem) async {
     Database db = await instance.database;
     return await db.update(
       _mediaTable,
       mediaItem.toMap(),
       where: 'id = ?',
       whereArgs: [mediaItem.id],
     );
   }

   /// Xóa MediaItem theo ID.
   Future<int> deleteMediaItem(int id) async {
     Database db = await instance.database;
     return await db.delete(
       _mediaTable,
       where: 'id = ?',
       whereArgs: [id],
     );
   }

   // ============================================================================
   // MARK: - CUSTOM DATA RETRIEVAL (Dùng cho Hike Detail và Logic ảnh đại diện)
   // ============================================================================

   /// Lấy chi tiết Hike bao gồm tất cả Observations và MediaItems liên quan.
   /// Phục vụ cho màn hình Hike Detail và logic xác định ảnh đại diện/carousel
   /// theo yêu cầu tùy chỉnh.
   Future<Hike?> getHikeDetailData(int hikeId) async {
     Database db = await instance.database;

     // 1. Lấy Hike cơ bản
     final List<Map<String, dynamic>> hikeMaps = await db.query(
       _hikeTable,
       where: 'id = ?',
       whereArgs: [hikeId],
     );
     if (hikeMaps.isEmpty) return null;

     Hike hike = Hike.fromMap(hikeMaps.first);

     // 2. Lấy Observations liên quan
     final List<Map<String, dynamic>> obsMaps = await db.query(
       _observationTable,
       where: 'hikeId = ?',
       whereArgs: [hikeId],
       orderBy: 'time DESC',
     );

     List<Observation> observations = List.generate(obsMaps.length, (i) {
       return Observation.fromMap(obsMaps[i]);
     });

     // 3. Lấy Media liên quan đến TẤT CẢ Observations
     if (observations.isNotEmpty) {
       final obsIds = observations.map((o) => o.id).whereType<int>().toList();

       // Query tất cả MediaItem có observationId nằm trong danh sách obsIds
       final List<Map<String, dynamic>> mediaMaps = await db.query(
         _mediaTable,
         where: 'observationId IN (${List.filled(obsIds.length, '?').join(', ')})',
         whereArgs: obsIds,
         orderBy: 'id ASC',
       );

       // Map MediaItem vào Observation tương ứng
       final mediaMap = <int, List<MediaItem>>{};
       for (final map in mediaMaps) {
         final mediaItem = MediaItem.fromMap(map);
         final obsId = mediaItem.observationId;
         mediaMap.putIfAbsent(obsId, () => []).add(mediaItem);
       }

       // Gán danh sách MediaItems đã lấy được vào từng Observation
       for (var obs in observations) {
         obs.media = mediaMap[obs.id] ?? [];
       }
     }

     // Gán danh sách Observation đã được populate MediaItems vào Hike
     hike.observations = observations;

     return hike;
   }

   // ============================================================================
   // MARK: - CRUD Weather Forecasts (Feature 9)
   // ============================================================================

   /// Thêm một dự báo thời tiết vào bảng weather_forecasts
   Future<int> insertWeatherForecast(Map<String, dynamic> weatherData) async {
     Database db = await instance.database;
     return await db.insert(_weatherTable, weatherData);
   }

   /// Thêm nhiều dự báo thời tiết cùng lúc (cho forecast nhiều ngày)
   Future<void> insertWeatherForecasts(List<Map<String, dynamic>> forecasts) async {
     Database db = await instance.database;
     await db.transaction((txn) async {
       for (final forecast in forecasts) {
         await txn.insert(_weatherTable, forecast);
       }
     });
   }

   /// Get all weather forecasts for a hike
   /// Lấy tất cả dự báo thời tiết cho một hike
   Future<List<Map<String, dynamic>>> getWeatherForecastsByHike(int hikeId) async {
     if (hikeId <= 0) {
       return [];
     }

     try {
       Database db = await instance.database;
       final List<Map<String, dynamic>> maps = await db.query(
         _weatherTable,
         where: 'hikeId = ?',
         whereArgs: [hikeId],
         orderBy: 'forecastDate ASC',
       );
       return maps;
     } catch (e) {
       return [];
     }
   }

   /// Lấy dự báo thời tiết cho một ngày cụ thể của hike
   Future<Map<String, dynamic>?> getWeatherForecastByDate(int hikeId, String date) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _weatherTable,
       where: 'hikeId = ? AND forecastDate = ?',
       whereArgs: [hikeId, date],
       limit: 1,
     );

     if (maps.isNotEmpty) {
       return maps.first;
     }
     return null;
   }

   /// Xóa tất cả dự báo thời tiết của một hike
   Future<int> deleteWeatherForecastsByHike(int hikeId) async {
     Database db = await instance.database;
     return await db.delete(
       _weatherTable,
       where: 'hikeId = ?',
       whereArgs: [hikeId],
     );
   }

   /// Xóa dự báo thời tiết cũ (quá 7 ngày)
   Future<int> deleteOldWeatherForecasts() async {
     Database db = await instance.database;
     final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
     return await db.delete(
       _weatherTable,
       where: 'timestamp < ?',
       whereArgs: [sevenDaysAgo],
     );
   }

   /// Cập nhật dự báo thời tiết cho một hike (xóa cũ và thêm mới)
   Future<void> updateWeatherForecastsForHike(int hikeId, List<Map<String, dynamic>> forecasts) async {
     Database db = await instance.database;
     await db.transaction((txn) async {
       // Xóa dự báo cũ
       await txn.delete(
         _weatherTable,
         where: 'hikeId = ?',
         whereArgs: [hikeId],
       );

       // Thêm dự báo mới
       for (final forecast in forecasts) {
         await txn.insert(_weatherTable, forecast);
       }
     });
   }

   // ============================================================================
   // MARK: - UTILITY METHODS
   // ============================================================================


   /// Xóa tất cả dữ liệu (dùng cho testing hoặc reset app)
   Future<void> clearAllData() async {
     Database db = await instance.database;
     await db.delete(_weatherTable);
     await db.delete(_mediaTable);
     await db.delete(_observationTable);
     await db.delete(_hikeTable);
   }

   /// Đóng database
   Future<void> close() async {
     Database db = await instance.database;
     await db.close();
   }
}

// Tạo alias để dễ sử dụng
typedef DbHelper = AppDatabase;
