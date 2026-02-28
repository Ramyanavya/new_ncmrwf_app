// lib/services/translator_service.dart
//
// Simple local translator — reads from assets/translations/hi.json
// NO internet, NO Google ML Kit, NO downloads.
// Works 100% offline, instantly.

import 'dart:convert';
import 'package:flutter/services.dart';

class TranslatorService {
  TranslatorService._(); // private constructor — all methods are static

  // Currently active language code ('en' or 'hi')
  static String _currentLang = 'en';

  // Loaded translations map: English → Hindi
  static Map<String, String> _translations = {};

  // Cache: avoids re-looking up the same string twice
  static final Map<String, String> _cache = {};

  // ── Call this when user changes language ────────────────────────────────
  static Future<void> init(String langCode) async {
    _currentLang = langCode;
    _cache.clear(); // clear cache so all widgets retranslate

    if (langCode == 'en') {
      _translations = {}; // English = no translation needed
      return;
    }

    try {
      // Load the JSON file from assets
      final jsonString = await rootBundle
          .loadString('assets/translations/$langCode.json');
      final Map<String, dynamic> decoded = json.decode(jsonString);

      // Cast to Map<String, String>
      _translations = decoded.map(
            (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      // If file not found or parse error, fall back to English
      _translations = {};
    }
  }

  // ── Translate a single string ────────────────────────────────────────────
  // Returns the Hindi translation if available, otherwise returns original.
  static Future<String> translate(String text) async {
    if (_currentLang == 'en' || text.isEmpty) return text;

    // Check cache first
    if (_cache.containsKey(text)) return _cache[text]!;

    // Look up in translations map
    final translated = _translations[text] ?? text;

    // Save in cache
    _cache[text] = translated;

    return translated;
  }

  // ── Synchronous version (use when async is not possible) ─────────────────
  static String translateSync(String text) {
    if (_currentLang == 'en' || text.isEmpty) return text;
    if (_cache.containsKey(text)) return _cache[text]!;
    final translated = _translations[text] ?? text;
    _cache[text] = translated;
    return translated;
  }

  // ── Get current language ─────────────────────────────────────────────────
  static String get currentLang => _currentLang;
}