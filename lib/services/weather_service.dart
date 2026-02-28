// lib/services/weather_service.dart
import 'dart:async';          // ✅ This fixes TimeoutException error
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../utils/constants.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  final String _base = AppConstants.baseUrl;

  // 60 seconds — NC files are large, first load is slow
  static const _timeout = Duration(seconds: 60);

  Future<CurrentWeather> getCurrentWeather({
    required double lat,
    required double lon,
    String level = '925mb',
  }) async {
    try {
      final uri = Uri.parse('$_base/weather/current').replace(
        queryParameters: {'lat': '$lat', 'lon': '$lon', 'level': level},
      );
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        return CurrentWeather.fromJson(json.decode(res.body));
      }
      throw Exception('Server error: ${res.statusCode}');
    } on SocketException {
      throw Exception('Cannot connect to server.\nCheck IP: $_base\nMake sure phone and PC are on same WiFi.');
    } on TimeoutException {
      throw Exception('Server timeout.\nNC files may still be loading.\nPlease wait 30 seconds and retry.');
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<List<DayForecast>> getForecast({
    required double lat,
    required double lon,
    String level = '925mb',
    int days = 10,
  }) async {
    try {
      final uri = Uri.parse('$_base/weather/forecast').replace(
        queryParameters: {'lat': '$lat', 'lon': '$lon', 'level': level, 'days': '$days'},
      );
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return (data['forecast'] as List).map((e) => DayForecast.fromJson(e)).toList();
      }
      throw Exception('Server error: ${res.statusCode}');
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } on TimeoutException {
      throw Exception('Timeout. Please retry.');
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<List<HourlyWeather>> getHourly({
    required double lat,
    required double lon,
    String level = '925mb',
  }) async {
    try {
      final uri = Uri.parse('$_base/weather/hourly').replace(
        queryParameters: {'lat': '$lat', 'lon': '$lon', 'level': level},
      );
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return (data['hourly'] as List).map((e) => HourlyWeather.fromJson(e)).toList();
      }
      throw Exception('Server error: ${res.statusCode}');
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } on TimeoutException {
      throw Exception('Timeout loading hourly data.');
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<Map<String, dynamic>> getTrend({
    required double lat,
    required double lon,
    String level = '925mb',
  }) async {
    try {
      final uri = Uri.parse('$_base/weather/trend').replace(
        queryParameters: {'lat': '$lat', 'lon': '$lon', 'level': level},
      );
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
      throw Exception('Server error: ${res.statusCode}');
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } on TimeoutException {
      throw Exception('Timeout loading trend data.');
    } catch (e) {
      throw Exception('$e');
    }
  }

  // Test if server is reachable before loading data
  Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('$_base/health');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}