// lib/providers/weather_provider.dart
import 'package:flutter/foundation.dart';
import '../models/weather_model.dart';
import '../services/local_notification_service.dart';
import '../services/weather_alert_service.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../widgets/weather_widget.dart';

enum WeatherStatus { initial, loading, loaded, error }

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  WeatherStatus _status = WeatherStatus.initial;
  CurrentWeather? _currentWeather;
  List<DayForecast> _forecast = [];
  List<HourlyWeather> _hourly = [];
  List<TrendPoint> _trend = [];
  double _minTemp = 0;
  double _maxTemp = 0;
  String _errorMessage = '';
  String _placeName = '';
  double _latitude = 28.61;
  double _longitude = 77.21;
  String _selectedLevel = '925mb';

  // Only send alerts when location actually changes, not on every refresh.
  String _lastAlertLocationKey = '';

  WeatherStatus get status => _status;
  CurrentWeather? get currentWeather => _currentWeather;
  List<DayForecast> get forecast => _forecast;
  List<HourlyWeather> get hourly => _hourly;
  List<TrendPoint> get trend => _trend;
  double get minTemp => _minTemp;
  double get maxTemp => _maxTemp;
  String get errorMessage => _errorMessage;
  String get placeName => _placeName;
  double get latitude => _latitude;
  double get longitude => _longitude;
  String get selectedLevel => _selectedLevel;

  Future<void> fetchWeatherForCurrentLocation() async {
    _setLoading('Fetching location...');
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        _latitude = position['lat']!;
        _longitude = position['lon']!;
        _placeName = position['name'] ?? 'Current Location';
      } else {
        _latitude = 28.61;
        _longitude = 77.21;
        _placeName = 'New Delhi, Delhi';
      }
      await _fetchAll();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> fetchWeatherForLocation({
    required double lat,
    required double lon,
    required String name,
  }) async {
    _latitude = lat;
    _longitude = lon;
    _setLoading(name); // single notify for loading
    await _fetchAll();
  }

  Future<void> changeLevel(String level) async {
    _selectedLevel = level;
    _setLoading(_placeName);
    await _fetchAll();
  }

  Future<void> refresh() => _fetchAll();

  // ── Helpers: batch state into one notifyListeners per transition ──────────

  void _setLoading(String place) {
    _status = WeatherStatus.loading;
    _placeName = place;
    notifyListeners(); // ← exactly ONE notify for loading state
  }

  void _setError(String message) {
    _status = WeatherStatus.error;
    _errorMessage = message.replaceAll('Exception: ', '');
    notifyListeners(); // ← exactly ONE notify for error state
  }

  Future<void> _fetchAll() async {
    try {
      final connected = await _weatherService.testConnection();
      if (!connected) {
        _setError(
          'Cannot reach server.\n\nMake sure:\n'
              '• FastAPI server is running\n'
              '• Phone and PC are on same WiFi\n'
              '• IP address is correct in constants.dart',
        );
        return;
      }

      // All network requests fire in parallel — no intermediate notifies.
      final results = await Future.wait([
        _weatherService.getCurrentWeather(
            lat: _latitude, lon: _longitude, level: _selectedLevel),
        _weatherService.getForecast(
            lat: _latitude, lon: _longitude, level: _selectedLevel),
        _weatherService.getHourly(
            lat: _latitude, lon: _longitude, level: _selectedLevel),
        _weatherService.getTrend(
            lat: _latitude, lon: _longitude, level: _selectedLevel),
      ]);

      // ── Assign ALL fields before notifying — prevents partial-state renders ─
      _currentWeather = results[0] as CurrentWeather;
      _forecast       = results[1] as List<DayForecast>;
      _hourly         = results[2] as List<HourlyWeather>;

      final trendData = results[3] as Map<String, dynamic>;
      _trend   = (trendData['trend'] as List).map((e) => TrendPoint.fromJson(e)).toList();
      _minTemp = (trendData['min_temp'] as num).toDouble();
      _maxTemp = (trendData['max_temp'] as num).toDouble();
      _status  = WeatherStatus.loaded;

      // ── ONE single notifyListeners for the fully-ready loaded state ───────
      notifyListeners();

      // ── Side-effects run AFTER the UI has been notified ──────────────────
      // Only alert when location actually changes — not on every tap/refresh.
      final locationKey =
          '${_latitude.toStringAsFixed(4)},${_longitude.toStringAsFixed(4)}';
      if (locationKey != _lastAlertLocationKey) {
        _lastAlertLocationKey = locationKey;
        await WeatherAlertService.checkAndSend(_currentWeather!);
        // ⚠️  Remove the line below — it fired a notification on EVERY fetch
        // and was a significant source of jank. Uncomment only for debugging:
        // await LocalNotificationService.showWeatherAlert("Test alert");
      }

      // Update home-screen widget quietly — errors must not cause a rebuild.
      try {
        await WeatherWidgetUpdater.update(this);
      } catch (e) {
        debugPrint('Widget update error (non-fatal): $e');
      }

    } catch (e) {
      _setError(e.toString());
    }
  }
}