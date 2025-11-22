# SERVICES ARCHITECTURE DIAGRAM

## 📐 KIẾN TRÚC TỔNG QUAN

```
┌─────────────────────────────────────────────────────────────┐
│                          VIEWS (UI)                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Feed    │  │   Plan   │  │Remarkable│  │  Detail  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │ (Gọi methods)
┌────────────────────────▼────────────────────────────────────┐
│                      VIEWMODELS                             │
│  ┌──────────────┐  ┌────────────────┐  ┌────────────────┐  │
│  │ HikeViewModel│  │ObservationVM   │  │  WeatherVM     │  │
│  └──────┬───────┘  └────────┬───────┘  └────────┬───────┘  │
└─────────┼──────────────────┼──────────────────┼────────────┘
          │                  │                   │
┌─────────▼──────────────────▼───────────────────▼────────────┐
│                        SERVICES                              │
│                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐ │
│  │LocationService │  │   MapService   │  │ MediaService  │ │
│  │                │  │                │  │               │ │
│  │• getCurrentLoc │  │• moveCamera    │  │• pickImage    │ │
│  │• getAddress    │  │• createMarker  │  │• pickVideo    │ │
│  │• calcDistance  │  │• createPolyline│  │• validateFile │ │
│  └────────┬───────┘  └────────┬───────┘  └───────┬───────┘ │
│           │                   │                   │         │
│  ┌────────▼───────┐  ┌────────▼───────────────────▼───────┐ │
│  │WeatherService  │  │      AppDatabase (SQLite)         │ │
│  │                │  │                                    │ │
│  │• getWeather    │  │• CRUD Hikes                       │ │
│  │• getForecast   │  │• CRUD Observations                │ │
│  │• recommend     │  │• CRUD Media                       │ │
│  └────────┬───────┘  └────────┬───────────────────────────┘ │
└───────────┼──────────────────┼─────────────────────────────┘
            │                  │
┌───────────▼──────────────────▼─────────────────────────────┐
│               EXTERNAL DEPENDENCIES                         │
│                                                             │
│  📍 Geolocator    🗺️  Google Maps    📷 Image Picker       │
│  🌐 HTTP Client   💾 SQLite          📁 File System        │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔗 SERVICES DEPENDENCY MAP

### LocationService
```
LocationService
├── Dependencies:
│   ├── geolocator (GPS)
│   ├── geocoding (Address conversion)
│   └── google_maps_flutter (LatLng type)
│
├── Used by:
│   ├── HikeViewModel (Get current location)
│   ├── MapPickerView (Reverse geocoding)
│   └── WeatherViewModel (Get coordinates for weather)
│
└── Output:
    ├── Position (lat, lng, altitude...)
    ├── String (Address)
    └── double (Distance in km)
```

### MapService
```
MapService
├── Dependencies:
│   └── google_maps_flutter (Map UI)
│
├── Used by:
│   ├── MapPickerView (Draw markers, polylines)
│   ├── HikeDetailView (Show hiking trail)
│   └── ObservationDetailView (Show location)
│
└── Output:
    ├── Marker
    ├── Polyline
    ├── Circle
    └── String (Google Maps URL)
```

### MediaService
```
MediaService
├── Dependencies:
│   ├── image_picker (Camera, Gallery)
│   └── dart:io (File operations)
│
├── Used by:
│   ├── ObservationViewModel (Add photos/videos)
│   └── MediaGalleryView (Display media)
│
└── Output:
    ├── String (File path)
    ├── List<String> (Multiple paths)
    └── bool (Validation result)
```

### WeatherService
```
WeatherService
├── Dependencies:
│   └── http (API calls)
│
├── Used by:
│   ├── WeatherViewModel (Display weather)
│   ├── HikeFormView (Check weather before hiking)
│   └── PlanView (Planning assistance)
│
└── Output:
    ├── WeatherData (Full weather info)
    ├── List<WeatherData> (Forecast)
    └── String (Recommendations)
```

### AppDatabase
```
AppDatabase (SQLite)
├── Dependencies:
│   ├── sqflite (SQLite)
│   └── path (Database path)
│
├── Used by:
│   ├── HikeViewModel (CRUD hikes)
│   ├── ObservationViewModel (CRUD observations)
│   └── MediaViewModel (CRUD media)
│
└── Output:
    ├── int (Insert ID / Update count)
    ├── Hike / Observation / MediaItem
    └── List<T> (Query results)
```

---

## 🔄 DATA FLOW EXAMPLES

### Example 1: Tạo Hike mới với Location từ Map

```
1. User mở HikeFormView
   ↓
2. User nhấn "Pick Location" button
   ↓
3. Navigate to MapPickerView
   ↓
4. MapPickerView gọi LocationService.getCurrentLocation()
   ↓
5. LocationService trả về Position (lat, lng)
   ↓
6. MapService.moveCamera() → Di chuyển map đến vị trí hiện tại
   ↓
7. User tap vào map để chọn location
   ↓
8. LocationService.getAddressFromLatLng() → Convert to address
   ↓
9. MapPickerView trả kết quả về HikeFormView
   ↓
10. HikeViewModel lưu location vào state
    ↓
11. User nhấn "Save"
    ↓
12. HikeViewModel.saveHike() gọi AppDatabase.insertHike()
    ↓
13. Database trả về hikeId
    ↓
14. ViewModel notifyListeners() → UI update
```

### Example 2: Thêm Observation với nhiều ảnh

```
1. User ở HikeDetailView, nhấn "Add Observation"
   ↓
2. Navigate to ObservationFormView
   ↓
3. User nhấn "Add Photos" button
   ↓
4. ObservationViewModel gọi MediaService.pickMultiImage()
   ↓
5. MediaService mở Gallery picker
   ↓
6. User chọn 3 ảnh
   ↓
7. MediaService validate từng ảnh (size, format)
   ↓
8. MediaService trả về List<String> paths
   ↓
9. ObservationViewModel lưu paths vào state
   ↓
10. User nhập caption, content
    ↓
11. User nhấn "Save"
    ↓
12. ObservationViewModel:
    a. Tạo Observation object
    b. Gọi AppDatabase.insertObservation()
    c. Lấy observationId
    d. Tạo List<MediaItem> từ paths
    e. Gọi AppDatabase.insertMediaItems()
    ↓
13. Database lưu thành công
    ↓
14. ViewModel notifyListeners() → UI update
```

### Example 3: Kiểm tra thời tiết cho Hike

```
1. User ở PlanView, chọn 1 hike
   ↓
2. Tap vào "Check Weather" button
   ↓
3. WeatherViewModel gọi LocationService.getLatLngFromAddress(hike.location)
   ↓
4. LocationService trả về LatLng
   ↓
5. WeatherViewModel gọi WeatherService.getWeatherByCoordinates(lat, lng)
   ↓
6. WeatherService gọi OpenWeatherMap API
   ↓
7. API trả về JSON data
   ↓
8. WeatherService parse thành WeatherData object
   ↓
9. WeatherService.isGoodForHiking() → Đánh giá
   ↓
10. WeatherService.getHikingRecommendation() → Khuyến nghị
    ↓
11. WeatherViewModel notifyListeners()
    ↓
12. View hiển thị:
    - Nhiệt độ, tình trạng thời tiết
    - Icon thời tiết
    - Khuyến nghị (✅ Tốt / ⚠️ Cẩn thận / ❌ Nguy hiểm)
```

---

## 🎨 SERVICE INTERACTION PATTERNS

### Pattern 1: Single Service Call
```dart
// Simple, direct call
final location = await LocationService().getCurrentLocation();
```

### Pattern 2: Chained Services
```dart
// Service A → Service B
final position = await LocationService().getCurrentLocation();
final address = await LocationService().getAddressFromLatLng(
  position.latitude, 
  position.longitude
);
```

### Pattern 3: Parallel Services
```dart
// Gọi nhiều services đồng thời
final results = await Future.wait([
  LocationService().getCurrentLocation(),
  WeatherService().getWeather(lat, lng),
  AppDatabase.instance.getHikeById(id),
]);
```

### Pattern 4: Service + Database Transaction
```dart
// Kết hợp nhiều operations
final db = await AppDatabase.instance.database;
await db.transaction((txn) async {
  // Insert observation
  final obsId = await txn.insert('observations', obs.toMap());
  
  // Insert media items
  for (var path in mediaPaths) {
    await txn.insert('media', {
      'observationId': obsId,
      'path': path,
      'type': MediaService().getMediaType(path),
    });
  }
});
```

---

## 📊 SERVICES COMPLEXITY MATRIX

| Service | Complexity | External Deps | Test Difficulty |
|---------|-----------|---------------|-----------------|
| LocationService | ⭐⭐⭐ | 2 packages | Medium (Mock GPS) |
| MapService | ⭐⭐ | 1 package | Easy (UI test) |
| MediaService | ⭐⭐⭐ | 1 package | Hard (Need device) |
| WeatherService | ⭐⭐ | 1 package | Easy (Mock API) |
| AppDatabase | ⭐⭐⭐⭐ | 2 packages | Medium (In-memory DB) |

---

## 🛠️ TESTING STRATEGY

### Unit Tests
```dart
// Test LocationService
test('Calculate distance between 2 points', () {
  final service = LocationService();
  final distance = service.calculateDistance(
    21.0285, 105.8542,  // Hanoi
    10.8231, 106.6297,  // Ho Chi Minh
  );
  expect(distance, greaterThan(1000)); // >1000km
});
```

### Mock Services
```dart
class MockWeatherService extends WeatherService {
  @override
  Future<WeatherData> getWeather(double lat, double lng) async {
    return WeatherData(
      temperature: 25.0,
      condition: 'Sunny',
      // ... mock data
    );
  }
}
```

---

## 🎯 PERFORMANCE OPTIMIZATION

### 1. Lazy Loading
```dart
// Don't initialize all services at app start
// Initialize only when needed
```

### 2. Caching
```dart
// Cache weather data for 30 minutes
class WeatherService {
  WeatherData? _cachedWeather;
  DateTime? _cacheTime;
  
  Future<WeatherData?> getWeather(lat, lng) async {
    if (_cachedWeather != null && 
        DateTime.now().difference(_cacheTime!) < Duration(minutes: 30)) {
      return _cachedWeather;
    }
    // Fetch new data...
  }
}
```

### 3. Pagination (Database)
```dart
// Load 10 items per page instead of all
final hikes = await AppDatabase.instance.getHikesPaged(page);
```

### 4. Debouncing (Location Stream)
```dart
// Update location every 10 meters, not every change
LocationSettings(distanceFilter: 10)
```

---

## 🔐 SECURITY CONSIDERATIONS

### 1. API Key Protection
```dart
// DON'T commit API keys to Git
// Use environment variables or secure storage
const String apiKey = String.fromEnvironment('WEATHER_API_KEY');
```

### 2. File Path Validation
```dart
// Validate file paths before operations
if (!path.startsWith(appDirectory)) {
  throw SecurityException('Invalid path');
}
```

### 3. SQL Injection Prevention
```dart
// ALWAYS use parameterized queries
db.query('hikes', where: 'id = ?', whereArgs: [id]);
// NEVER: db.rawQuery('SELECT * FROM hikes WHERE id = $id')
```

---

## 📚 DOCUMENTATION CHECKLIST

✅ **LocationService**: Complete
✅ **MapService**: Complete  
✅ **MediaService**: Complete
✅ **WeatherService**: Complete
✅ **AppDatabase**: Complete

✅ **Architecture Diagram**: Complete
✅ **Data Flow Examples**: Complete
✅ **Testing Strategy**: Complete
✅ **Performance Tips**: Complete
✅ **Security Guidelines**: Complete

---

## 🚀 NEXT STEPS

1. ✅ Services implementation → **DONE**
2. ⏭️ Implement ViewModels using these services
3. ⏭️ Build Views (UI) consuming ViewModels
4. ⏭️ Setup Provider for state management
5. ⏭️ Implement navigation
6. ⏭️ Add error handling & loading states
7. ⏭️ Write unit tests
8. ⏭️ Write integration tests
9. ⏭️ Performance optimization
10. ⏭️ Deploy & Test on real devices

