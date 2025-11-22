# LOGIC CỦA CÁC SERVICES - M_HIKE HYBRID APP

> **Kiến trúc MVVM**: Services là tầng thấp nhất, xử lý trực tiếp với:
> - SQLite Database
> - Device APIs (Camera, Gallery, Location)
> - External APIs (Google Maps, Weather API)
> - File System

---

## 📋 MỤC LỤC

1. [Location Service](#1-location-service)
2. [Map Service](#2-map-service)
3. [Media Service](#3-media-service)
4. [Weather Service](#4-weather-service)
5. [Database Service](#5-database-service)

---

## 1. LOCATION SERVICE
**File**: `lib/services/location_service.dart`

### 🎯 Mục đích
Xử lý mọi thao tác liên quan đến vị trí GPS và chuyển đổi địa chỉ.

### 🔧 Chức năng chính

#### 1.1. Kiểm tra quyền truy cập
```dart
Future<bool> checkLocationPermission()
```
- Kiểm tra Location Service có bật không
- Kiểm tra quyền truy cập (denied/deniedForever)
- Tự động request quyền nếu chưa có
- **Trả về**: `true` nếu có quyền, `false` nếu không

#### 1.2. Lấy vị trí hiện tại
```dart
Future<Position?> getCurrentLocation()
```
- Kiểm tra quyền trước khi lấy vị trí
- Sử dụng `LocationAccuracy.high` (GPS chính xác)
- **Trả về**: `Position` object với lat/lng hoặc `null` nếu lỗi

#### 1.3. Reverse Geocoding (LatLng → Địa chỉ)
```dart
Future<String> getAddressFromLatLng(double latitude, double longitude)
```
- Chuyển tọa độ thành địa chỉ văn bản
- Format: `Street, SubLocality, Locality, State, Country`
- **Sử dụng khi**: User chọn điểm trên map, cần hiển thị địa chỉ

#### 1.4. Forward Geocoding (Địa chỉ → LatLng)
```dart
Future<LatLng?> getLatLngFromAddress(String address)
```
- Chuyển địa chỉ văn bản thành tọa độ
- **Sử dụng khi**: User nhập địa chỉ tay, cần hiển thị trên map

#### 1.5. Tính khoảng cách
```dart
double calculateDistance(double startLat, double startLng, double endLat, double endLng)
double calculateDistanceLatLng(LatLng start, LatLng end)
```
- Tính khoảng cách giữa 2 điểm (đơn vị: km)
- **Sử dụng cho**: Tính độ dài hiking trail

#### 1.6. Stream vị trí liên tục
```dart
Stream<Position> getPositionStream()
```
- Theo dõi vị trí real-time
- Update mỗi 10 meters
- **Sử dụng cho**: Live tracking trong hiking

### 📦 Dependencies
```yaml
dependencies:
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  google_maps_flutter: ^2.5.0
```

---

## 2. MAP SERVICE
**File**: `lib/services/map_service.dart`

### 🎯 Mục đích
Xử lý mọi thao tác liên quan đến Google Maps UI.

### 🔧 Chức năng chính

#### 2.1. Quản lý Map Controller
```dart
void setMapController(GoogleMapController controller)
```
- Lưu controller để thao tác với map

#### 2.2. Di chuyển Camera
```dart
Future<void> moveCamera(LatLng position, {double zoom = 15.0})
```
- Di chuyển camera đến vị trí chỉ định
- Smooth animation

#### 2.3. Auto zoom to bounds
```dart
Future<void> moveToBounds(List<LatLng> positions, {double padding = 50.0})
```
- Tự động zoom để hiển thị tất cả markers
- **Sử dụng khi**: Hiển thị Start & End point của hiking trail

#### 2.4. Tạo Markers
```dart
Marker createMarker({
  required String markerId,
  required LatLng position,
  String? title,
  String? snippet,
  BitmapDescriptor? icon,
  void Function()? onTap,
})
```
- Tạo marker với custom style
- **Sử dụng cho**: Start point, End point, POI

#### 2.5. Vẽ đường đi (Polyline)
```dart
Polyline createPolyline({
  required String polylineId,
  required List<LatLng> points,
  int color = 0xFF2196F3,
  int width = 5,
})
```
- Vẽ đường nối giữa các điểm
- **Sử dụng cho**: Hiking trail visualization

#### 2.6. Tạo vùng tròn (Circle)
```dart
Circle createCircle({
  required String circleId,
  required LatLng center,
  double radius = 1000,
  ...
})
```
- Vẽ vùng tròn trên map
- **Sử dụng cho**: Highlight khu vực hiking

#### 2.7. Tạo Google Maps URL
```dart
String createGoogleMapsUrl(double lat, double lng, {String? label})
String createDirectionUrl(LatLng origin, LatLng destination)
```
- Tạo link mở Google Maps app
- Chỉ đường từ A → B

#### 2.8. Utilities
```dart
LatLng getCenterPoint(List<LatLng> positions)
double getZoomLevelForDistance(double distanceInKm)
bool isValidCoordinate(double lat, double lng)
```

### 📦 Dependencies
```yaml
dependencies:
  google_maps_flutter: ^2.5.0
```

---

## 3. MEDIA SERVICE
**File**: `lib/services/media_service.dart`

### 🎯 Mục đích
Xử lý mọi thao tác với Images và Videos.

### 🔧 Chức năng chính

#### 3.1. IMAGES

##### Chụp ảnh bằng Camera (Feature 8)
```dart
Future<String?> pickImageFromCamera()
```
- Mở camera để chụp ảnh
- Tự động resize: 1920x1080, quality 85%
- **Trả về**: Đường dẫn file ảnh

##### Chọn ảnh từ Gallery
```dart
Future<String?> pickImageFromGallery()
```
- Chọn 1 ảnh từ thư viện
- Tự động resize

##### Chọn nhiều ảnh (Feature 9: Multi Images)
```dart
Future<List<String>> pickMultiImage({int? maxImages})
```
- Chọn nhiều ảnh cùng lúc
- Giới hạn số lượng nếu cần
- **Trả về**: List đường dẫn

#### 3.2. VIDEOS

##### Chọn Video từ Gallery
```dart
Future<String?> pickVideoFromGallery()
```
- Chọn video từ thư viện
- Giới hạn 5 phút

##### Quay Video
```dart
Future<String?> recordVideoFromCamera()
```
- Mở camera để quay video
- Giới hạn 5 phút

##### Chọn nhiều Video
```dart
Future<List<String>> pickMultiVideo({int? maxVideos})
```
- Chọn nhiều video (gọi pickVideo nhiều lần)

#### 3.3. FILE VALIDATION

```dart
bool isFileExists(String path)
int getFileSize(String path)
double getFileSizeMB(String path)
bool validateImage(String path, {double maxSizeMB = 10})
bool validateVideo(String path, {double maxSizeMB = 50})
```
- Kiểm tra file có tồn tại
- Kiểm tra kích thước
- Validate định dạng

#### 3.4. FILE OPERATIONS

```dart
Future<bool> deleteFile(String path)
Future<void> deleteMultipleFiles(List<String> paths)
String getMediaType(String path)
bool isImage(String path)
bool isVideo(String path)
```
- Xóa file
- Xác định loại media

### 📦 Dependencies
```yaml
dependencies:
  image_picker: ^1.0.7
```

---

## 4. WEATHER SERVICE
**File**: `lib/services/weather_service.dart`

### 🎯 Mục đích
Lấy thông tin thời tiết để hỗ trợ lập kế hoạch hiking (Feature 9).

### 🔧 Chức năng chính

#### 4.1. Lấy thời tiết theo tọa độ
```dart
Future<WeatherData?> getWeatherByCoordinates(double lat, double lng)
```
- Gọi OpenWeatherMap API
- **Sử dụng**: Kiểm tra thời tiết tại điểm đi hiking

#### 4.2. Lấy thời tiết theo thành phố
```dart
Future<WeatherData?> getWeatherByCity(String cityName)
```
- Tìm kiếm theo tên thành phố

#### 4.3. Dự báo 5 ngày
```dart
Future<List<WeatherData>?> getForecast(double lat, double lng)
```
- Dự báo thời tiết 5 ngày tới
- Update mỗi 3 giờ

#### 4.4. Mock data (Test mode)
```dart
Future<WeatherData> getMockWeather(double lat, double lng)
```
- Dữ liệu giả để test khi chưa có API key

#### 4.5. Đánh giá và khuyến nghị
```dart
bool isGoodForHiking(WeatherData weather)
String getHikingRecommendation(WeatherData weather)
```
- Đánh giá thời tiết có phù hợp để hiking không
- Đưa ra khuyến nghị cụ thể

### 📊 Weather Data Model
```dart
class WeatherData {
  double temperature;      // Nhiệt độ (°C)
  String condition;        // Sunny, Cloudy, Rain...
  String description;      // Mô tả chi tiết
  double humidity;         // Độ ẩm (%)
  double windSpeed;        // Tốc độ gió (km/h)
  String icon;            // Icon code
  DateTime timestamp;      // Thời gian
}
```

### 🔑 Setup API Key
1. Đăng ký miễn phí tại: https://openweathermap.org/api
2. Thay `YOUR_API_KEY` trong code

### 📦 Dependencies
```yaml
dependencies:
  http: ^1.1.0
```

---

## 5. DATABASE SERVICE (AppDatabase)
**File**: `lib/db/app_db.dart`

### 🎯 Mục đích
Quản lý SQLite database với 3 bảng chính: Hikes, Observations, Media.

### 🏗️ Cấu trúc Database

#### Bảng 1: HIKES
```sql
CREATE TABLE hikes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  date TEXT NOT NULL,
  length REAL NOT NULL,
  difficulty TEXT NOT NULL,
  description TEXT,
  isComplete INTEGER NOT NULL DEFAULT 0,
  isRemarkable INTEGER NOT NULL DEFAULT 0
)
```

#### Bảng 2: OBSERVATIONS
```sql
CREATE TABLE observations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  hikeId INTEGER NOT NULL,
  caption TEXT NOT NULL,
  content TEXT NOT NULL,
  time TEXT NOT NULL,
  FOREIGN KEY (hikeId) REFERENCES hikes (id) ON DELETE CASCADE
)
```

#### Bảng 3: MEDIA
```sql
CREATE TABLE media (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  observationId INTEGER NOT NULL,
  path TEXT NOT NULL,
  type TEXT NOT NULL,
  FOREIGN KEY (observationId) REFERENCES observations (id) ON DELETE CASCADE
)
```

### 🔧 Chức năng chính

#### 5.1. CRUD Hikes
```dart
Future<int> insertHike(Hike hike)
Future<List<Hike>> getHikesPaged(int page)
Future<Hike?> getHikeById(int id)
Future<int> updateHike(Hike hike)
Future<int> deleteHike(int id)
```

**Đặc biệt**:
- `getHikesPaged()`: Hỗ trợ **Infinity Scroll** (Feature 4)
- Mỗi page: 10 items
- Sắp xếp theo `date DESC`

#### 5.2. CRUD Observations
```dart
Future<int> insertObservation(Observation observation)
Future<List<Observation>> getObservationsByHikeId(int hikeId)
```

#### 5.3. CRUD Media
```dart
Future<void> insertMediaItems(List<MediaItem> mediaList)
Future<List<MediaItem>> getMediaForObservation(int observationId)
```

**Transaction**: Sử dụng transaction khi insert nhiều media để đảm bảo atomicity.

### 🔗 Foreign Key Cascade
```dart
FOREIGN KEY (hikeId) REFERENCES hikes (id) ON DELETE CASCADE
```
- Khi xóa Hike → Tự động xóa tất cả Observations
- Khi xóa Observation → Tự động xóa tất cả Media

### 🎨 Singleton Pattern
```dart
static final AppDatabase instance = AppDatabase._privateConstructor();
```
- Đảm bảo chỉ có 1 instance duy nhất
- Tránh conflict khi đa luồng

### 📦 Dependencies
```yaml
dependencies:
  sqflite: ^2.3.0
  path: ^1.8.3
```

---

## 🔄 LUỒNG DỮ LIỆU TỔNG QUÁT

```
View (UI)
  ↕️
ViewModel (Logic + State Management)
  ↕️
Service (Business Logic)
  ↕️
External APIs / Device APIs / SQLite
```

### Ví dụ: User thêm Observation với ảnh

1. **View**: User nhấn "Add Photo" button
2. **ViewModel**: Gọi `MediaService.pickImageFromCamera()`
3. **MediaService**: Mở camera → Trả về path
4. **ViewModel**: Lưu path vào state
5. **ViewModel**: User nhấn "Save" → Gọi `insertObservation()`
6. **AppDatabase**: Insert observation → Lấy ID
7. **AppDatabase**: Insert media với observationId
8. **ViewModel**: `notifyListeners()` → UI update

---

## 📝 BEST PRACTICES

### 1. Error Handling
```dart
try {
  final result = await service.doSomething();
  return result;
} catch (e) {
  print('Error: $e');
  return null;
}
```

### 2. Null Safety
```dart
Future<Position?> getCurrentLocation() async {
  // Có thể trả về null nếu lỗi
}
```

### 3. Async/Await
- Tất cả service methods đều async
- ViewModel phải await kết quả

### 4. Separation of Concerns
- Service KHÔNG biết gì về UI
- Service KHÔNG chứa state
- Service chỉ xử lý logic thuần túy

### 5. Reusability
- Các method nhỏ, tập trung
- Có thể tái sử dụng ở nhiều ViewModel

---

## 🎯 KẾT LUẬN

**5 Services chính**:
1. ✅ **LocationService**: GPS, Geocoding, Distance
2. ✅ **MapService**: Google Maps UI operations
3. ✅ **MediaService**: Images, Videos, Camera
4. ✅ **WeatherService**: Weather API, Recommendations
5. ✅ **AppDatabase**: SQLite CRUD operations

**Đặc điểm chung**:
- Tách biệt hoàn toàn khỏi UI
- Dễ test (unit test)
- Dễ bảo trì và mở rộng
- Tuân thủ MVVM architecture

**Next Steps**:
- Implement ViewModels sử dụng các Services này
- Build Views (UI) consume ViewModels
- Kết nối tất cả với `Provider` để quản lý state

