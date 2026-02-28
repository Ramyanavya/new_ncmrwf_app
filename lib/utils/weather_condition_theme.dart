// lib/theme/weather_condition_theme.dart
import 'package:flutter/material.dart';

class WeatherConditionTheme {
  final List<Color> skyGradient;
  final Color accentColor;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final String iconAssetHint; // used to pick which painter to draw

  const WeatherConditionTheme({
    required this.skyGradient,
    required this.accentColor,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconAssetHint,
  });

  static WeatherConditionTheme of(String condition) {
    switch (condition.toLowerCase()) {

    // ── Sunny/Hot: deeper blue gradient — bottom darkened for text contrast
      case 'sunny':
      case 'hot':
        return const WeatherConditionTheme(
          skyGradient: [
            Color(0xFF0D3B7A), // very deep blue top
            Color(0xFF1056A8), // deep blue
            Color(0xFF1A72C9), // medium blue
            Color(0xFF2D8FD8), // darker than before (was 0xFF90CAF9)
          ],
          accentColor: Color(0xFFFFD54F),
          cardColor: Color(0x44FFFFFF),
          textPrimary: Colors.white,
          textSecondary: Color(0xEEFFFFFF),
          iconAssetHint: 'sunny',
        );

    // ── Partly Cloudy: richer, deeper blue — no washed-out tones
      case 'partly cloudy':
        return const WeatherConditionTheme(
          skyGradient: [
            Color(0xFF0D3472), // dark navy top
            Color(0xFF1045A0), // deep blue
            Color(0xFF1A5CC0), // medium-dark blue
            Color(0xFF1A5CC0), // consistent — no light bottom
          ],
          accentColor: Color(0xFFFFE082),
          cardColor: Color(0x44FFFFFF),
          textPrimary: Colors.white,
          textSecondary: Color(0xEEFFFFFF),
          iconAssetHint: 'partly_cloudy',
        );

    // ── Cloudy: muted, darker blue-grey sky
      case 'cloudy':
        return const WeatherConditionTheme(
          skyGradient: [
            Color(0xFF182D42), // very dark slate top
            Color(0xFF213D58), // dark blue-grey
            Color(0xFF2E5272), // medium blue-grey
            Color(0xFF3E6D90), // darker than before (was 0xFF90B8D8)
          ],
          accentColor: Color(0xFF7BA8C4),
          cardColor: Color(0x44FFFFFF),
          textPrimary: Colors.white,
          textSecondary: Color(0xEEFFFFFF),
          iconAssetHint: 'cloudy',
        );

    // ── Rainy: very deep navy — already dark, pushed even deeper
      case 'rainy':
        return const WeatherConditionTheme(
          skyGradient: [
            Color(0xFF050D18), // near-black navy top
            Color(0xFF0A1E30), // very deep navy
            Color(0xFF0F2B46), // deep navy-blue
            Color(0xFF14396A), // dark blue bottom (was 0xFF2255A0)
          ],
          accentColor: Color(0xFF64AADF),
          cardColor: Color(0x44FFFFFF),
          textPrimary: Colors.white,
          textSecondary: Color(0xEEFFFFFF),
          iconAssetHint: 'rainy',
        );

    // ── Stormy: darkest — deep charcoal-navy
      case 'stormy':
        return const WeatherConditionTheme(
          skyGradient: [
            Color(0xFF040810), // almost black top
            Color(0xFF080F1E), // very dark navy
            Color(0xFF0C1830), // dark navy-blue
            Color(0xFF111F3E), // dark blue bottom (was 0xFF1A3060)
          ],
          accentColor: Color(0xFFFFEE58),
          cardColor: Color(0x44FFFFFF),
          textPrimary: Colors.white,
          textSecondary: Color(0xEEFFFFFF),
          iconAssetHint: 'stormy',
        );

    // ── Snowy/Cold: deeper icy blue — bottom significantly darkened
      case 'snowy':
      case 'cold':
        return const WeatherConditionTheme(
          skyGradient: [
            Color(0xFF0D3B7A), // deep blue top
            Color(0xFF1056A8), // medium-deep blue
            Color(0xFF2678CC), // medium blue
            Color(0xFF4A98D8), // darker bottom (was 0xFFBBDEFB — very light)
          ],
          accentColor: Color(0xFFAAD4F5),
          cardColor: Color(0x44FFFFFF),
          textPrimary: Colors.white,
          textSecondary: Color(0xEEFFFFFF),
          iconAssetHint: 'snowy',
        );

    // ── Windy: deeper blue tones throughout
      case 'windy':
        return const WeatherConditionTheme(
          skyGradient: [
            Color(0xFF0D3B7A), // deep blue top
            Color(0xFF104A9E), // darker blue
            Color(0xFF1A6AC0), // medium-deep blue
            Color(0xFF2D82C8), // darker bottom (was 0xFF90CAF9)
          ],
          accentColor: Color(0xFF70C4EC),
          cardColor: Color(0x44FFFFFF),
          textPrimary: Colors.white,
          textSecondary: Color(0xEEFFFFFF),
          iconAssetHint: 'windy',
        );

    // ── Default: deeper medium-to-blue gradient
      default:
        return const WeatherConditionTheme(
          skyGradient: [
            Color(0xFF0D3B7A), // deep blue top
            Color(0xFF104A9E), // dark blue
            Color(0xFF1A6AC0), // medium blue
            Color(0xFF3A88CE), // darker bottom (was 0xFFBBDEFB — very light)
          ],
          accentColor: Color(0xFFFFD54F),
          cardColor: Color(0x44FFFFFF),
          textPrimary: Colors.white,
          textSecondary: Color(0xEEFFFFFF),
          iconAssetHint: 'sunny',
        );
    }
  }
}