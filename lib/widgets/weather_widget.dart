// lib/widget/weather_widget.dart
// Saves directly to FlutterSharedPreferences — bypasses home_widget storage
// so the Kotlin widget can read it directly.

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../providers/weather_provider.dart';

class WeatherWidgetUpdater {
  static const _channel = MethodChannel('com.example.new_ncmrwf_app/widget');

  static Future<void> update(WeatherProvider wp) async {
    if (wp.currentWeather == null) {
      debugPrint('Widget update skipped: no data');
      return;
    }

    try {
      final cw = wp.currentWeather!;

      // Save via shared_preferences which writes to FlutterSharedPreferences
      // home_widget also writes here with "flutter." prefix
      await _channel.invokeMethod('updateWidget', {
        'location':    wp.placeName,
        'temperature': cw.temperatureC.toStringAsFixed(0),
        'condition':   cw.condition,
        'feels_like':  cw.feelsLikeC.toStringAsFixed(1),
        'humidity':    cw.humidityPercent.toStringAsFixed(0),
        'wind':        cw.windSpeedKmh.toStringAsFixed(1),
        'pressure':    cw.pressureMb.toString(),
        'fc_day_0':    wp.forecast.length > 0 ? _dayShort(wp.forecast[0].day) : '---',
        'fc_temp_0':   wp.forecast.length > 0 ? wp.forecast[0].temperatureC.toStringAsFixed(0) : '--',
        'fc_cond_0':   wp.forecast.length > 0 ? wp.forecast[0].condition : '',
        'fc_day_1':    wp.forecast.length > 1 ? _dayShort(wp.forecast[1].day) : '---',
        'fc_temp_1':   wp.forecast.length > 1 ? wp.forecast[1].temperatureC.toStringAsFixed(0) : '--',
        'fc_cond_1':   wp.forecast.length > 1 ? wp.forecast[1].condition : '',
        'fc_day_2':    wp.forecast.length > 2 ? _dayShort(wp.forecast[2].day) : '---',
        'fc_temp_2':   wp.forecast.length > 2 ? wp.forecast[2].temperatureC.toStringAsFixed(0) : '--',
        'fc_cond_2':   wp.forecast.length > 2 ? wp.forecast[2].condition : '',
        'fc_day_3':    wp.forecast.length > 3 ? _dayShort(wp.forecast[3].day) : '---',
        'fc_temp_3':   wp.forecast.length > 3 ? wp.forecast[3].temperatureC.toStringAsFixed(0) : '--',
        'fc_cond_3':   wp.forecast.length > 3 ? wp.forecast[3].condition : '',
      });

      debugPrint('✅ Widget updated via MethodChannel');
    } catch (e) {
      debugPrint('⚠️ Widget update failed: $e');
    }
  }

  static String _dayShort(String day) =>
      day.length >= 3 ? day.substring(0, 3) : day;
}