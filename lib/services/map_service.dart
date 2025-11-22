// lib/services/map_service.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math';


/// Service xử lý các thao tác liên quan đến Google Maps
class MapService {
  GoogleMapController? _mapController;

  /// Set map controller khi GoogleMap được khởi tạo
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Di chuyển camera đến vị trí chỉ định
  Future<void> moveCamera(LatLng position, {double zoom = 15.0}) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(position, zoom),
      );
    }
  }

  /// Di chuyển camera đến bounds chứa tất cả markers
  Future<void> moveToBounds(List<LatLng> positions, {double padding = 50.0}) async {
    if (_mapController == null || positions.isEmpty) return;

    // Tính toán bounds
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (var pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }

  /// Tạo marker với custom style
  Marker createMarker({
    required String markerId,
    required LatLng position,
    String? title,
    String? snippet,
    BitmapDescriptor? icon,
    void Function()? onTap,
  }) {
    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(
        title: title ?? '',
        snippet: snippet ?? '',
      ),
      icon: icon ?? BitmapDescriptor.defaultMarker,
      onTap: onTap,
    );
  }

  /// Tạo polyline giữa 2 điểm
  Polyline createPolyline({
    required String polylineId,
    required List<LatLng> points,
    int color = 0xFF2196F3, // Blue
    int width = 5,
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: Color(color),
      width: width,
    );
  }

  /// Tạo circle (vùng tròn)
  Circle createCircle({
    required String circleId,
    required LatLng center,
    double radius = 1000, // meters
    int fillColor = 0x5502A4F5,
    int strokeColor = 0xFF0288D1,
    int strokeWidth = 2,
  }) {
    return Circle(
      circleId: CircleId(circleId),
      center: center,
      radius: radius,
      fillColor: Color(fillColor),
      strokeColor: Color(strokeColor),
      strokeWidth: strokeWidth,
    );
  }

  /// Tạo Google Maps URL để mở trên browser/app
  String createGoogleMapsUrl(double lat, double lng, {String? label}) {
    if (label != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$label';
    }
    return 'https://maps.google.com/?q=$lat,$lng';
  }

  /// Tạo Google Maps Direction URL (chỉ đường từ A đến B)
  String createDirectionUrl(LatLng origin, LatLng destination) {
    return 'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=walking';
  }

  /// Validate tọa độ hợp lệ
  bool isValidCoordinate(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  /// Tính center point của danh sách tọa độ
  LatLng getCenterPoint(List<LatLng> positions) {
    if (positions.isEmpty) {
      return const LatLng(0, 0);
    }

    double totalLat = 0;
    double totalLng = 0;

    for (var pos in positions) {
      totalLat += pos.latitude;
      totalLng += pos.longitude;
    }

    return LatLng(
      totalLat / positions.length,
      totalLng / positions.length,
    );
  }

  /// Get zoom level phù hợp dựa trên khoảng cách
  double getZoomLevelForDistance(double distanceInKm) {
    // Công thức gần đúng cho zoom level
    if (distanceInKm <= 0.5) return 16.0;
    if (distanceInKm <= 1) return 15.0;
    if (distanceInKm <= 2) return 14.0;
    if (distanceInKm <= 5) return 13.0;
    if (distanceInKm <= 10) return 12.0;
    if (distanceInKm <= 20) return 11.0;
    if (distanceInKm <= 50) return 10.0;
    return 9.0;
  }

  /// Tính khoảng cách giữa 2 điểm (đơn vị: km).
  ///
  /// Sử dụng công thức Haversine để tính khoảng cách chính xác
  /// giữa hai tọa độ trên bề mặt cầu Trái Đất.
  ///
  /// [start] - Tọa độ điểm bắt đầu
  /// [end] - Tọa độ điểm kết thúc
  ///
  /// Returns: Khoảng cách tính bằng kilometers (km)
  double calculateDistance(LatLng start, LatLng end) {
    const double earthRadiusKm = 6371.0;

    // Chuyển đổi độ sang radian
    double lat1 = start.latitude * pi / 180.0;
    double lat2 = end.latitude * pi / 180.0;
    double lon1 = start.longitude * pi / 180.0;
    double lon2 = end.longitude * pi / 180.0;

    // Haversine formula
    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) *
        sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * asin(sqrt(a));

    return earthRadiusKm * c;
  }

  /// Dispose controller
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
  }
}

