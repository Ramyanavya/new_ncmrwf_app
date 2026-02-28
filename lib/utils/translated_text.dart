// lib/utils/translated_text.dart
//
// Drop-in replacement for Flutter's Text() widget.
// Automatically translates the given English string
// to the active language using local JSON files.
//
// Usage:
//   TranslatedText('Weather Forecast')           // replaces Text('Weather Forecast')
//   TranslatedText(AppStrings.settings)           // works with AppStrings constants
//
// WithTranslation is for non-Text widgets that need a translated string.

import 'package:flutter/material.dart';
import '../services/translator_service.dart';

// ─── TRANSLATED TEXT ──────────────────────────────────────────────────────────
class TranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const TranslatedText(
      this.text, {
        super.key,
        this.style,
        this.textAlign,
        this.overflow,
        this.maxLines,
      });

  @override
  Widget build(BuildContext context) {
    // Synchronous lookup — instant if cached or English
    final cached = TranslatorService.translateSync(text);

    if (cached != text || TranslatorService.currentLang == 'en') {
      return Text(
        cached,
        style: style,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      );
    }

    return FutureBuilder<String>(
      future: TranslatorService.translate(text),
      initialData: text,
      builder: (_, snap) => Text(
        snap.data ?? text,
        style: style,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      ),
    );
  }
}

// ─── WITH TRANSLATION ─────────────────────────────────────────────────────────
class WithTranslation extends StatelessWidget {
  final String text;
  final Widget Function(String translated) builder;

  const WithTranslation({
    super.key,
    required this.text,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final cached = TranslatorService.translateSync(text);

    if (cached != text || TranslatorService.currentLang == 'en') {
      return builder(cached);
    }

    return FutureBuilder<String>(
      future: TranslatorService.translate(text),
      initialData: text,
      builder: (_, snap) => builder(snap.data ?? text),
    );
  }
}