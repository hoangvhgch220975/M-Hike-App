// lib/viewmodels/weather_viewmodel.dart

import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();

  // Weather data
  String? temperature;
  String? description;
  String? icon;
  String? humidity;
  String? windSpeed;
  String? cityName;

  // Loading and error states
  bool isLoading = false;
  String? errorMessage;

  // Get weather by city name
  Future<void> getWeatherByCity(String city) async {
    if (city.isEmpty) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final weatherData = await _weatherService.getWeatherByCity(city);

      if (weatherData != null) {
        _updateWeatherFromObject(weatherData);
      } else {
        errorMessage = 'Could not fetch weather data';
      }
    } catch (e) {
      errorMessage = 'Error: ${e.toString()}';
      debugPrint('Error getting weather: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Get weather by coordinates
  Future<void> getWeatherByCoordinates(double lat, double lon) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final weatherData = await _weatherService.getWeatherByCoordinates(lat, lon);

      if (weatherData != null) {
        _updateWeatherFromObject(weatherData);
      } else {
        errorMessage = 'Could not fetch weather data';
      }
    } catch (e) {
      errorMessage = 'Error: ${e.toString()}';
      debugPrint('Error getting weather: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Update weather data from WeatherData object
  void _updateWeatherFromObject(dynamic data) {
    try {
      temperature = '${data.temperature.toStringAsFixed(1)}°C';
      description = data.description;
      icon = data.icon;
      humidity = '${data.humidity.toStringAsFixed(0)}%';
      windSpeed = '${data.windSpeed.toStringAsFixed(1)} km/h';
      cityName = data.condition; // Use condition as city name fallback
    } catch (e) {
      debugPrint('Error parsing weather data: $e');
      errorMessage = 'Error parsing weather data';
    }
  }

  // Get weather icon URL
  String? getWeatherIconUrl() {
    if (icon != null) {
      return 'https://openweathermap.org/img/wn/$icon@2x.png';
    }
    return null;
  }

  // Clear weather data
  void clear() {
    temperature = null;
    description = null;
    icon = null;
    humidity = null;
    windSpeed = null;
    cityName = null;
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }

  // Check if weather data is available
  bool get hasWeatherData => temperature != null && description != null;
}

