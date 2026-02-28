// lib/screens/favorites_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../providers/weather_provider.dart';
import '../models/weather_model.dart';
import '../services/translator_service.dart';
import '../utils/weather_condition_theme.dart';
import '../widgets/location_search.dart';
import '../utils/app_strings.dart';
import '../utils/translated_text.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  void _openSearchAndAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationSearchSheet(
        onLocationSelected: (name, lat, lon) async {
          final fp = context.read<FavoritesProvider>();
          final added = await fp.addFavorite(
            FavoriteLocation(name: name, latitude: lat, longitude: lon),
          );
          if (context.mounted) {
            Navigator.pop(context);
            String msg;
            if (added) {
              msg = await TranslatorService.translate(AppStrings.locationAdded);
            } else if (fp.isFull) {
              msg = await TranslatorService.translate(AppStrings.favoritesLimitReached);
            } else {
              msg = await TranslatorService.translate(AppStrings.locationAlreadyAdded);
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white)),
                backgroundColor: Colors.black.withOpacity(0.7),
              ));
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (ctx, wp, _) {
        final condition = wp.currentWeather?.condition ?? 'partly cloudy';
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(.2)),
                          child: const Icon(Icons.star_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        TranslatedText(AppStrings.favorites,
                            style: GoogleFonts.dmSans(color: Colors.white,
                                fontSize: 20, fontWeight: FontWeight.w800)),
                      ]),
                      Consumer<FavoritesProvider>(
                        builder: (_, fp, __) => GestureDetector(
                          onTap: fp.isFull
                              ? () async {
                            final msg = await TranslatorService.translate(
                                AppStrings.favoritesLimitReached);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white)),
                                backgroundColor: Colors.black.withOpacity(0.7),
                              ));
                            }
                          }
                              : () => _openSearchAndAdd(context),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(.3)),
                                ),
                                child: Icon(
                                  fp.isFull ? Icons.location_off_outlined : Icons.add_location_alt_outlined,
                                  color: fp.isFull ? Colors.white38 : Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Limit indicator ──────────────────────────────────────
                Consumer<FavoritesProvider>(builder: (_, fp, __) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${fp.favorites.length} / ${FavoritesProvider.maxFavorites}',
                            style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 11)),
                        const SizedBox(width: 6),
                        ...List.generate(FavoritesProvider.maxFavorites, (i) => Container(
                          margin: const EdgeInsets.only(left: 3),
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < fp.favorites.length ? Colors.white : Colors.white24,
                          ),
                        )),
                      ],
                    ),
                  );
                }),

                // ── List ─────────────────────────────────────────────────
                Expanded(
                  child: Consumer<FavoritesProvider>(builder: (_, fp, __) {
                    if (fp.favorites.isEmpty) return _buildEmpty(context, condTheme);
                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                      itemCount: fp.favorites.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final fav = fp.favorites[i];
                        return Dismissible(
                          key: Key('${fav.latitude}_${fav.longitude}'),
                          direction: DismissDirection.endToStart,
                          background: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red.withOpacity(.30),
                              child: const Icon(Icons.delete_rounded, color: Colors.white),
                            ),
                          ),
                          onDismissed: (_) => fp.removeFavorite(fav.latitude, fav.longitude),
                          child: GestureDetector(
                            onTap: () => context.read<WeatherProvider>().fetchWeatherForLocation(
                                lat: fav.latitude, lon: fav.longitude, name: fav.name),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.white.withOpacity(0.28)),
                                  ),
                                  child: Row(children: [
                                    Container(width: 44, height: 44,
                                        decoration: BoxDecoration(shape: BoxShape.circle,
                                            color: Colors.white.withOpacity(.2)),
                                        child: const Icon(Icons.location_on_rounded,
                                            color: Colors.white, size: 22)),
                                    const SizedBox(width: 14),
                                    Expanded(child: TranslatedText(fav.name,
                                        style: GoogleFonts.dmSans(color: Colors.white,
                                            fontSize: 14, fontWeight: FontWeight.w700),
                                        overflow: TextOverflow.ellipsis)),
                                    const Icon(Icons.chevron_right_rounded,
                                        color: Colors.white38, size: 20),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context, WeatherConditionTheme condTheme) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.white.withOpacity(0.28)),
              ),
              child: const Icon(Icons.star_outline_rounded, color: Colors.white, size: 44),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TranslatedText(AppStrings.noFavorites, style: GoogleFonts.dmSans(
            color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TranslatedText(AppStrings.addFavoritesHint,
            style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => _openSearchAndAdd(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_location_alt_outlined, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  TranslatedText(AppStrings.addLocation, style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}