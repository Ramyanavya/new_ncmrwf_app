// lib/screens/settings_screen.dart
// REDESIGNED: Illustrated gradient background + glassmorphic cards/tiles.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../providers/weather_provider.dart';
import '../services/translator_service.dart';
import '../utils/app_strings.dart';
import '../utils/translated_text.dart';
import '../utils/weather_condition_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lang = settings.languageCode;
    final wp = context.watch<WeatherProvider>();
    final condition = wp.currentWeather?.condition ?? 'cloudy';
    final condTheme = WeatherConditionTheme.of(condition);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: condTheme.skyGradient,
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            // ── Top bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(.2)),
                  child: const Icon(Icons.settings_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                TranslatedText(
                  AppStrings.settings,
                  style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
              ]),
            ),

            // ── Downloading indicator ──────────────────────────────
            if (settings.isTranslating)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(.3)),
                      ),
                      child: Row(children: [
                        const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text('Downloading language model...',
                            style: GoogleFonts.dmSans(
                                color: Colors.white, fontSize: 13)),
                      ]),
                    ),
                  ),
                ),
              ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                children: [
                  // ── Language ────────────────────────────────────────
                  _SectionHeader(AppStrings.language),
                  const SizedBox(height: 10),
                  _LanguageTile(
                    nativeName: 'English',
                    englishName: 'English',
                    isSelected: lang == 'en',
                    onTap: () =>
                        context.read<SettingsProvider>().setLanguage('en'),
                  ),
                  const SizedBox(height: 8),
                  _LanguageTile(
                    nativeName: 'हिन्दी',
                    englishName: 'Hindi',
                    isSelected: lang == 'hi',
                    onTap: () =>
                        context.read<SettingsProvider>().setLanguage('hi'),
                  ),

                  const SizedBox(height: 24),

                  // ── About ──────────────────────────────────────────
                  _SectionHeader(AppStrings.about),
                  const SizedBox(height: 10),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    titleKey: AppStrings.aboutApp,
                    subtitleKey: AppStrings.aboutVersion,
                    onTap: () => _showDialog(context, condTheme,
                        titleKey: AppStrings.aboutApp,
                        contentKey: AppStrings.aboutContent,
                        closeKey: AppStrings.close),
                  ),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    titleKey: AppStrings.faqs,
                    subtitleKey: AppStrings.faqsSub,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const FAQScreen())),
                  ),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    titleKey: AppStrings.privacy,
                    subtitleKey: AppStrings.privacySub,
                    onTap: () => _showDialog(context, condTheme,
                        titleKey: AppStrings.privacy,
                        contentKey: AppStrings.privacyContent,
                        closeKey: AppStrings.close),
                  ),

                  const SizedBox(height: 24),

                  // ── Data Source ────────────────────────────────────
                  _SectionHeader(AppStrings.dataSource),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.28)),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(.2),
                                        borderRadius:
                                        BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                          Icons.satellite_alt_outlined,
                                          color: Colors.white, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'NCMRWF NWP Data',
                                        style: GoogleFonts.dmSans(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ]),
                              const SizedBox(height: 10),
                              TranslatedText(
                                AppStrings.dataSourceDesc,
                                style: GoogleFonts.dmSans(
                                    color: Colors.white60,
                                    fontSize: 12,
                                    height: 1.5),
                              ),
                            ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showDialog(
      BuildContext context,
      WeatherConditionTheme condTheme, {
        required String titleKey,
        required String contentKey,
        required String closeKey,
      }) async {
    final title = await TranslatorService.translate(titleKey);
    final content = await TranslatorService.translate(contentKey);
    final close = await TranslatorService.translate(closeKey);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor:
          condTheme.skyGradient.first.withOpacity(0.92),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(.2))),
          title: Text(title,
              style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
              child: Text(content,
                  style: GoogleFonts.dmSans(
                      color: Colors.white70, height: 1.6))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(close,
                  style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            )
          ],
        ),
      ),
    );
  }
}

// ─── FAQ SCREEN ───────────────────────────────────────────────────────────────
class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});
  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  List<Map<String, String>>? _translatedFaqs;

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  Future<void> _loadFaqs() async {
    final result = <Map<String, String>>[];
    for (final faq in AppStrings.faqList) {
      result.add({
        'q': await TranslatorService.translate(faq['q']!),
        'a': await TranslatorService.translate(faq['a']!),
      });
    }
    if (mounted) setState(() => _translatedFaqs = result);
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WeatherProvider>();
    final condition = wp.currentWeather?.condition ?? 'cloudy';
    final condTheme = WeatherConditionTheme.of(condition);
    final faqs = _translatedFaqs ?? AppStrings.faqList;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: condTheme.skyGradient,
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(.3)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TranslatedText(
                  AppStrings.faqs,
                  style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
              ]),
            ),
            Expanded(
              child: _translatedFaqs == null
                  ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
                  : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                itemCount: faqs.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (ctx, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter:
                    ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding:
                        const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        childrenPadding:
                        const EdgeInsets.fromLTRB(
                            16, 0, 16, 16),
                        backgroundColor:
                        Colors.white.withOpacity(.18),
                        collapsedBackgroundColor:
                        Colors.white.withOpacity(.18),
                        shape: const RoundedRectangleBorder(),
                        collapsedShape:
                        const RoundedRectangleBorder(),
                        leading: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color:
                            Colors.white.withOpacity(.25),
                            borderRadius:
                            BorderRadius.circular(8),
                          ),
                          child: Text('Q${i + 1}',
                              style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                        title: Text(faqs[i]['q']!,
                            style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        iconColor: Colors.white,
                        collapsedIconColor: Colors.white60,
                        children: [
                          Text(faqs[i]['a']!,
                              style: GoogleFonts.dmSans(
                                  color: Colors.white70,
                                  height: 1.5,
                                  fontSize: 13))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── SHARED WIDGETS ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(
    title.toUpperCase(),
    style: GoogleFonts.dmSans(
        color: Colors.white70,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4),
  );
}

class _LanguageTile extends StatelessWidget {
  final String nativeName;
  final String englishName;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.nativeName,
    required this.englishName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.28)
                  : Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withOpacity(0.55)
                    : Colors.white.withOpacity(0.2),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              // ── App icon ──────────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  "assets/icon/App_Icon.png",
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.thunderstorm_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nativeName,
                          style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      Text(englishName,
                          style: GoogleFonts.dmSans(
                              color: Colors.white54, fontSize: 12)),
                    ]),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: isSelected ? Colors.white : Colors.white38,
                size: 22,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String titleKey, subtitleKey;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border:
              Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.2),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText(
                            titleKey,
                            style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          TranslatedText(
                            subtitleKey,
                            style: GoogleFonts.dmSans(
                                color: Colors.white54, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ]),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white38, size: 20),
                ]),
          ),
        ),
      ),
    );
  }
}