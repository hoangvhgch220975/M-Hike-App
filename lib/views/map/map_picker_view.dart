// lib/views/map/map_picker_view.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/web_map_service.dart';
import '../../services/location_service.dart';

class MapPickerView extends StatefulWidget {
  const MapPickerView({super.key});

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView> {
  late final WebViewController _controller;
  final WebMapService _webMapService = WebMapService();
  final LocationService _locationService = LocationService();
  bool _isLoading = true;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  // Get current location and send to map - Lấy vị trí hiện tại và gửi vào map
  Future<void> _getCurrentLocationAndSendToMap() async {
    if (_isGettingLocation) return;

    setState(() {
      _isGettingLocation = true;
    });

    try {
      print('🌍 [FLUTTER] Getting current location from device...');

      // Get current position from device - Lấy vị trí từ thiết bị
      final position = await _locationService.getCurrentLocation();

      if (position != null) {
        final lat = position.latitude;
        final lon = position.longitude;

        print('✅ [FLUTTER] Got location: $lat, $lon');

        // Send to map via JavaScript - Gửi vào map qua JavaScript
        final jsCode = '''
          (function() {
            try {
              // Set current location from Flutter - Đặt vị trí hiện tại từ Flutter
              if (typeof startLatLng !== 'undefined') {
                startLatLng = L.latLng($lat, $lon);
                if (typeof startMarker !== 'undefined') {
                  startMarker.setLatLng(startLatLng);
                  map.setView(startLatLng, 15);
                  startMarker.bindPopup('📍 Your Current Location (from device)').openPopup();
                }
                console.log('✅ Location set from Flutter:', $lat, $lon);
              }
            } catch (e) {
              console.error('❌ Error setting location:', e);
            }
          })();
        ''';

        await _controller.runJavaScript(jsCode);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Current location detected'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF2C5E1A),
            ),
          );
        }
      } else {
        print('❌ [FLUTTER] Could not get location');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Could not get current location. Please enable GPS.'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [FLUTTER] Error getting location: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'MapPickerChannel',
        onMessageReceived: (JavaScriptMessage message) {
          // Parse the JSON message from the map using WebMapService
          try {
            print('🗺️ [MAP] RAW MESSAGE: ${message.message}');

            // Sử dụng WebMapService để parse message
            final data = _webMapService.parseMapPickerMessage(message.message);

            if (data == null) {
              print('❌ [MAP] Failed to parse message');
              return;
            }

            // Validate data
            if (!_webMapService.validateLocationData(data)) {
              print('❌ [MAP] Invalid location data');
              return;
            }

            // Log received data
            _webMapService.logReceivedData(data);

            // Check if distance is present
            if (data['distance'] != null) {
              print('✅ [MAP] Distance: ${_webMapService.formatDistance(data['distance'])} km');
            } else {
              print('⚠️ [MAP] No distance in payload. Map HTML may need update.');
            }

            print('📤 [MAP] Returning location data to form');

            // Return the picked location to the previous screen
            Navigator.of(context).pop(data);
          } catch (e) {
            print('❌ [MAP] ERROR: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('Web resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(_webMapService.getDefaultMapUrl()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pick Location on Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2C5E1A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to use'),
                  content: const Text(
                    '1. Search for a location using the search bar\n'
                    '2. Or tap anywhere on the map to pick a location\n'
                    '3. The location will be automatically saved',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C5E1A)),
              ),
            ),
        ],
      ),
    );
  }
}

