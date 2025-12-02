// lib/services/map_service.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service xử lý các thao tác liên quan đến Google Maps và Geocoding
class MapService {
  GoogleMapController? _mapController;

  /// Lưu trữ Google Maps controller
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Get current map controller
  GoogleMapController? get mapController => _mapController;

  /// Move camera to specific location
  Future<void> moveCamera(LatLng target, {double zoom = 14.0}) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(target, zoom),
      );
    }
  }

  /// Calculate distance between two points (Haversine formula)
  /// Returns distance in kilometers
  double calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // km

    final double lat1 = start.latitude * pi / 180;
    final double lat2 = end.latitude * pi / 180;
    final double dLat = (end.latitude - start.latitude) * pi / 180;
    final double dLon = (end.longitude - start.longitude) * pi / 180;

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Get formatted distance string
  String getFormattedDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)} m';
    } else {
      return '${distanceInKm.toStringAsFixed(2)} km';
    }
  }

  // ============================================================================
  // GEOCODING & ROUTING API
  // ============================================================================

  /// Reverse Geocoding: Lấy tên địa điểm từ tọa độ
  ///
  /// Sử dụng Nominatim API (OpenStreetMap) để chuyển đổi
  /// tọa độ (lat, lon) thành tên địa điểm chi tiết.
  ///
  /// [lat] - Vĩ độ
  /// [lon] - Kinh độ
  ///
  /// Returns: Tên địa điểm hoặc null nếu thất bại
  Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'MHikeApp/1.0', // Nominatim requires User-Agent
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] as String?;
      } else {
        print('❌ Reverse geocoding failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error in reverseGeocode: $e');
      return null;
    }
  }

  /// Forward Geocoding: Tìm kiếm địa điểm theo tên
  ///
  /// Sử dụng Nominatim API để tìm kiếm các địa điểm
  /// phù hợp với query string.
  ///
  /// [query] - Chuỗi tìm kiếm (tên địa điểm, địa chỉ)
  /// [limit] - Số lượng kết quả tối đa (mặc định: 10)
  ///
  /// Returns: Danh sách các địa điểm tìm được
  Future<List<Map<String, dynamic>>> searchLocation(
    String query, {
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=$limit',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'MHikeApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          return {
            'lat': double.parse(item['lat']),
            'lon': double.parse(item['lon']),
            'display_name': item['display_name'] as String,
            'type': item['type'] as String?,
            'importance': item['importance'] as double?,
          };
        }).toList();
      } else {
        print('❌ Location search failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error in searchLocation: $e');
      return [];
    }
  }

  /// Calculate Route Distance: Tính khoảng cách route giữa 2 điểm
  ///
  /// Sử dụng OSRM API (Open Source Routing Machine) để tính
  /// khoảng cách route thực tế (theo đường đi) giữa 2 điểm.
  ///
  /// [startLat] - Vĩ độ điểm bắt đầu
  /// [startLon] - Kinh độ điểm bắt đầu
  /// [endLat] - Vĩ độ điểm kết thúc
  /// [endLon] - Kinh độ điểm kết thúc
  /// [profile] - Loại route: 'foot-walking', 'driving-car', 'cycling-regular'
  ///
  /// Returns: Map chứa distance (km), duration (phút), và geometry
  Future<Map<String, dynamic>?> calculateRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    String profile = 'foot-walking',
  }) async {
    try {
      // Sử dụng OSRM public API
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/$profile/$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];

          return {
            'distance': (route['distance'] as num) / 1000.0, // Convert to km
            'duration': (route['duration'] as num) / 60.0, // Convert to minutes
            'geometry': route['geometry'],
            'legs': route['legs'],
          };
        } else {
          print('❌ Route calculation failed: ${data['code']}');
          return null;
        }
      } else {
        print('❌ OSRM API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error in calculateRoute: $e');
      return null;
    }
  }

  /// Get Route Polyline Points: Lấy danh sách điểm cho polyline
  ///
  /// Parse geometry từ route response để vẽ polyline trên map
  ///
  /// [geometry] - GeoJSON geometry từ OSRM response
  ///
  /// Returns: Danh sách LatLng points
  List<LatLng> parseRouteGeometry(Map<String, dynamic> geometry) {
    try {
      if (geometry['type'] == 'LineString' && geometry['coordinates'] != null) {
        final List<dynamic> coordinates = geometry['coordinates'];
        return coordinates.map((coord) {
          return LatLng(
            coord[1] as double, // lat
            coord[0] as double, // lon
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error parsing geometry: $e');
      return [];
    }
  }

  /// Batch Reverse Geocoding: Lấy tên cho nhiều tọa độ
  ///
  /// Sử dụng khi cần reverse geocode nhiều điểm cùng lúc.
  ///
  /// [positions] - Danh sách tọa độ cần reverse geocode
  /// [delay] - Delay giữa các request (milliseconds) để tránh rate limit
  ///
  /// Returns: Map với key là "lat,lon" và value là display_name
  Future<Map<String, String>> batchReverseGeocode(
    List<LatLng> positions, {
    int delay = 1000,
  }) async {
    final results = <String, String>{};

    for (final pos in positions) {
      final key = '${pos.latitude},${pos.longitude}';
      final name = await reverseGeocode(pos.latitude, pos.longitude);

      if (name != null) {
        results[key] = name;
      }

      // Delay to avoid rate limiting
      if (delay > 0 && positions.indexOf(pos) < positions.length - 1) {
        await Future.delayed(Duration(milliseconds: delay));
      }
    }

    return results;
  }

  /// Validate and Format Location Name
  ///
  /// Chuẩn hóa tên địa điểm, loại bỏ các ký tự không cần thiết
  ///
  /// [locationName] - Tên địa điểm cần format
  /// [maxLength] - Độ dài tối đa (mặc định: 100)
  ///
  /// Returns: Tên địa điểm đã được format
  String formatLocationName(String locationName, {int maxLength = 100}) {
    String formatted = locationName.trim();

    // Remove multiple spaces
    formatted = formatted.replaceAll(RegExp(r'\s+'), ' ');

    // Truncate if too long
    if (formatted.length > maxLength) {
      formatted = '${formatted.substring(0, maxLength - 3)}...';
    }

    return formatted;
  }

  // ============================================================================
  // GOOGLE MAPS UI HELPERS
  // ============================================================================

  /// Create Marker: Tạo marker cho Google Maps
  ///
  /// Helper method để tạo marker với các thuộc tính cơ bản
  ///
  /// [markerId] - ID duy nhất cho marker
  /// [position] - Vị trí của marker (LatLng)
  /// [title] - Tiêu đề hiển thị khi tap vào marker
  /// [snippet] - Mô tả chi tiết (optional)
  /// [icon] - Custom icon (optional, mặc định là marker đỏ)
  /// [infoWindow] - Custom InfoWindow (optional)
  ///
  /// Returns: Marker object
  Marker createMarker({
    required String markerId,
    required LatLng position,
    String? title,
    String? snippet,
    BitmapDescriptor? icon,
    InfoWindow? infoWindow,
    VoidCallback? onTap,
  }) {
    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      icon: icon ?? BitmapDescriptor.defaultMarker,
      infoWindow: infoWindow ?? InfoWindow(
        title: title,
        snippet: snippet,
      ),
      onTap: onTap,
    );
  }

  /// Create Polyline: Tạo polyline cho Google Maps
  ///
  /// Helper method để tạo polyline (đường nối giữa các điểm)
  ///
  /// [polylineId] - ID duy nhất cho polyline
  /// [points] - Danh sách các điểm tạo thành polyline
  /// [color] - Màu của polyline (mặc định: xanh dương)
  /// [width] - Độ rộng của line (mặc định: 5)
  /// [patterns] - Pattern của line (optional, ví dụ: dotted, dashed)
  ///
  /// Returns: Polyline object
  Polyline createPolyline({
    required String polylineId,
    required List<LatLng> points,
    Color color = const Color(0xFF0000FF), // Blue
    int width = 5,
    List<PatternItem>? patterns,
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: color,
      width: width,
      patterns: patterns ?? [], // Use empty list if null
    );
  }

  /// Create Circle: Tạo circle overlay trên map
  ///
  /// Sử dụng để highlight một vùng tròn trên map
  ///
  /// [circleId] - ID duy nhất cho circle
  /// [center] - Tâm của circle
  /// [radius] - Bán kính (meters)
  /// [fillColor] - Màu fill (optional)
  /// [strokeColor] - Màu viền (optional)
  /// [strokeWidth] - Độ rộng viền (optional)
  ///
  /// Returns: Circle object
  Circle createCircle({
    required String circleId,
    required LatLng center,
    required double radius,
    Color fillColor = const Color(0x330000FF),
    Color strokeColor = const Color(0xFF0000FF),
    int strokeWidth = 2,
  }) {
    return Circle(
      circleId: CircleId(circleId),
      center: center,
      radius: radius,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  /// Create Polygon: Tạo polygon trên map
  ///
  /// Sử dụng để vẽ vùng đa giác trên map
  ///
  /// [polygonId] - ID duy nhất cho polygon
  /// [points] - Danh sách các điểm góc của polygon
  /// [fillColor] - Màu fill (optional)
  /// [strokeColor] - Màu viền (optional)
  /// [strokeWidth] - Độ rộng viền (optional)
  ///
  /// Returns: Polygon object
  Polygon createPolygon({
    required String polygonId,
    required List<LatLng> points,
    Color fillColor = const Color(0x3300FF00),
    Color strokeColor = const Color(0xFF00FF00),
    int strokeWidth = 2,
  }) {
    return Polygon(
      polygonId: PolygonId(polygonId),
      points: points,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  /// Get Bounds: Tính toán bounds cho nhiều điểm
  ///
  /// Sử dụng để fit camera vào tất cả các markers
  ///
  /// [points] - Danh sách các điểm cần include
  ///
  /// Returns: LatLngBounds
  LatLngBounds? getBounds(List<LatLng> points) {
    if (points.isEmpty) return null;
    if (points.length == 1) {
      // Single point - create small bounds around it
      final point = points[0];
      return LatLngBounds(
        southwest: LatLng(point.latitude - 0.001, point.longitude - 0.001),
        northeast: LatLng(point.latitude + 0.001, point.longitude + 0.001),
      );
    }

    double? minLat, maxLat, minLon, maxLon;

    for (final point in points) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLon == null || point.longitude < minLon) minLon = point.longitude;
      if (maxLon == null || point.longitude > maxLon) maxLon = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLon!),
      northeast: LatLng(maxLat!, maxLon!),
    );
  }

  /// Fit Bounds: Adjust camera để hiển thị tất cả markers
  ///
  /// [bounds] - LatLngBounds cần fit
  /// [padding] - Padding xung quanh (pixels)
  Future<void> fitBounds(LatLngBounds bounds, {double padding = 50}) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, padding),
      );
    }
  }

  /// Dispose controller
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
  }
}

