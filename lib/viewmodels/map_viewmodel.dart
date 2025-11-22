// lib/viewmodels/map_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';

class MapViewModel extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();

  // Map controller
  GoogleMapController? mapController;

  // Selected locations
  LatLng? startLocation;
  LatLng? endLocation;
  LatLng? selectedLocation;

  // Current user location
  LatLng? currentLocation;

  // Address text
  String? startAddress;
  String? endAddress;
  String? selectedAddress;

  // Calculated distance
  double? distance;

  // Route polyline
  Set<Polyline> polylines = {};
  Set<Marker> markers = {};

  // Loading state
  bool isLoading = false;
  String? errorMessage;

  // Initialize map
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    notifyListeners();
  }

  // Get current location
  Future<void> getCurrentLocation() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        currentLocation = LatLng(position.latitude, position.longitude);

        // Move camera to current location
        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(currentLocation!, 15),
          );
        }
      } else {
        errorMessage = 'Could not get current location';
      }
    } catch (e) {
      errorMessage = 'Error: ${e.toString()}';
      debugPrint('Error getting location: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Set start location
  Future<void> setStartLocation(LatLng location) async {
    startLocation = location;

    // Get address
    startAddress = await _locationService.getAddressFromLatLng(
      location.latitude,
      location.longitude,
    );

    // Update markers
    _updateMarkers();

    // Calculate distance if end location is set
    if (endLocation != null) {
      _calculateDistance();
    }

    notifyListeners();
  }

  // Set end location
  Future<void> setEndLocation(LatLng location) async {
    endLocation = location;

    // Get address
    endAddress = await _locationService.getAddressFromLatLng(
      location.latitude,
      location.longitude,
    );

    // Update markers
    _updateMarkers();

    // Calculate distance if start location is set
    if (startLocation != null) {
      _calculateDistance();
    }

    notifyListeners();
  }

  // Set single selected location
  Future<void> setSelectedLocation(LatLng location) async {
    selectedLocation = location;

    // Get address
    selectedAddress = await _locationService.getAddressFromLatLng(
      location.latitude,
      location.longitude,
    );

    // Clear other markers and add single marker
    markers.clear();
    markers.add(_mapService.createMarker(
      markerId: 'selected',
      position: location,
      title: 'Selected Location',
    ));

    notifyListeners();
  }

  // Search location by address
  Future<void> searchLocation(String address) async {
    if (address.isEmpty) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final location = await _locationService.getLatLngFromAddress(address);

      if (location != null) {
        selectedLocation = location;
        selectedAddress = address;

        // Move camera to searched location
        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(location, 15),
          );
        }

        // Update marker
        markers.clear();
        markers.add(_mapService.createMarker(
          markerId: 'searched',
          position: location,
          title: address,
        ));
      } else {
        errorMessage = 'Location not found';
      }
    } catch (e) {
      errorMessage = 'Error searching location: ${e.toString()}';
      debugPrint('Error searching location: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Update markers for start and end
  void _updateMarkers() {
    markers.clear();

    if (startLocation != null) {
      markers.add(_mapService.createMarker(
        markerId: 'start',
        position: startLocation!,
        title: 'Start',
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    if (endLocation != null) {
      markers.add(_mapService.createMarker(
        markerId: 'end',
        position: endLocation!,
        title: 'End',
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    // Update polyline if both points are set
    if (startLocation != null && endLocation != null) {
      polylines.clear();
      polylines.add(_mapService.createPolyline(
        polylineId: 'route',
        points: [startLocation!, endLocation!],
      ));
    }
  }

  /// Calculate distance between start and end locations
  /// Uses Haversine formula from MapService
  void _calculateDistance() {
    if (startLocation != null && endLocation != null) {
      distance = _mapService.calculateDistance(
        startLocation!,
        endLocation!,
      );
      notifyListeners();
    }
  }

  // Clear start location
  void clearStartLocation() {
    startLocation = null;
    startAddress = null;
    distance = null;
    polylines.clear();
    _updateMarkers();
    notifyListeners();
  }

  // Clear end location
  void clearEndLocation() {
    endLocation = null;
    endAddress = null;
    distance = null;
    polylines.clear();
    _updateMarkers();
    notifyListeners();
  }

  // Clear selected location
  void clearSelectedLocation() {
    selectedLocation = null;
    selectedAddress = null;
    markers.clear();
    notifyListeners();
  }

  // Clear all
  void clear() {
    startLocation = null;
    endLocation = null;
    selectedLocation = null;
    startAddress = null;
    endAddress = null;
    selectedAddress = null;
    distance = null;
    polylines.clear();
    markers.clear();
    errorMessage = null;
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}

