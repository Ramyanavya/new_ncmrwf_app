// lib/services/location_service.dart
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // ─── GET CURRENT GPS POSITION ─────────────────────────────────────────────
  // Returns {lat, lon, name} or null on failure.
  // Handles permission requests automatically.
  Future<Map<String, dynamic>?> getCurrentPosition() async {
    try {
      // 1. Check if location services are enabled on the device
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are turned off — fall back to default
        return null;
      }

      // 2. Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // User denied — fall back to default
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        // User permanently denied — can't request again
        return null;
      }

      // 3. Get actual device coordinates
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      final lat = pos.latitude;
      final lon = pos.longitude;

      // 4. Reverse-geocode to get a human-readable place name
      final placeName = await _reverseGeocode(lat, lon);

      return {
        'lat':  lat,
        'lon':  lon,
        'name': placeName ?? 'Current Location',
      };
    } catch (_) {
      return null;
    }
  }

  // ─── REVERSE GEOCODE ──────────────────────────────────────────────────────
  // Given lat/lon, returns a short place name using Nominatim.
  Future<String?> _reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
            '?lat=$lat&lon=$lon&format=json&accept-language=en',
      );
      final res = await http.get(url, headers: {
        'User-Agent':      'NCMRWFWeatherApp/1.0',
        'Accept-Language': 'en',
      }).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data    = json.decode(res.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>? ?? {};

        // Pick the most specific available field
        final name =
            address['city']          ??
                address['town']          ??
                address['village']       ??
                address['suburb']        ??
                address['county']        ??
                address['state_district'] ??
                address['state'];

        final state = address['state'] as String?;

        if (name != null && state != null && name != state) {
          return '$name, $state';
        }
        if (name != null) return name as String;

        // Fall back to first part of display_name
        final display = data['display_name'] as String?;
        if (display != null) return display.split(',').first.trim();
      }
    } catch (_) {
      // Silently fail
    }
    return null;
  }

  // ─── SEARCH PLACES ────────────────────────────────────────────────────────
  // Search places using Nominatim OpenStreetMap (free, no API key).
  // Pass [langCode] to get localised names ('hi' for Hindi, 'en' for English).
  Future<List<Map<String, dynamic>>> searchPlaces(
      String query, {
        String langCode = 'en',
      }) async {
    if (query.trim().length < 2) return [];

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(query)}'
            '&format=json'
            '&limit=10'
            '&countrycodes=in'
            '&accept-language=$langCode',
      );

      final res = await http.get(url, headers: {
        'User-Agent':      'NCMRWFWeatherApp/1.0',
        'Accept-Language': langCode,
      }).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.map((e) {
          final parts       = (e['display_name'] as String).split(',');
          final displayName = parts.take(3).join(', ').trim();
          final shortName   = parts.first.trim();
          return {
            'name':     displayName,
            'short':    shortName,
            'fullName': e['display_name'] as String,
            'lat':      double.parse(e['lat']),
            'lon':      double.parse(e['lon']),
          };
        }).toList();
      }
    } catch (_) {
      // Silently fail
    }
    return [];
  }
}