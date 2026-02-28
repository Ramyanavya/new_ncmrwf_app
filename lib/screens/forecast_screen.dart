// lib/screens/forecast_screen.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/app_providers.dart';
import '../models/weather_model.dart';
import '../services/translator_service.dart';
import '../utils/app_strings.dart';
import '../utils/translated_text.dart';
import '../utils/weather_condition_theme.dart';
import '../utils/weather_icon_painter.dart';
import '../widgets/location_search.dart';
import '../main.dart';

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.white.withOpacity(0.28)),
        ),
        child: child,
      ),
    ),
  );
}

class _TempPainter extends CustomPainter {
  final List<TrendPoint> trend;
  final double mn, mx, range;
  final int sel;
  final Color accent;
  _TempPainter({
    required this.trend,
    required this.mn,
    required this.mx,
    required this.range,
    required this.sel,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (trend.isEmpty || range == 0) return;
    const pH = 24.0, pV = 20.0;
    final gW = size.width - pH * 2;
    final gH = size.height - pV * 2 - 20;
    final pts = <Offset>[];
    for (int i = 0; i < trend.length; i++) {
      pts.add(Offset(
        pH + (i / (trend.length - 1)) * gW,
        pV + (1 - (trend[i].temperatureC - mn) / range) * gH,
      ));
    }
    final fill = Path()..moveTo(pts.first.dx, size.height - 20);
    for (var p in pts) fill.lineTo(p.dx, p.dy);
    fill.lineTo(pts.last.dx, size.height - 20);
    fill.close();
    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent.withOpacity(.35), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final c1 = Offset((pts[i-1].dx + pts[i].dx) / 2, pts[i-1].dy);
      final c2 = Offset((pts[i-1].dx + pts[i].dx) / 2, pts[i].dy);
      line.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(line, Paint()
      ..color = accent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);
    for (int i = 0; i < pts.length; i++) {
      final s2 = i == sel;
      if (s2) {
        canvas.drawLine(Offset(pts[i].dx, 0), Offset(pts[i].dx, gH + pV),
            Paint()..color = accent.withOpacity(.25)..strokeWidth = 1);
        canvas.drawCircle(pts[i], 11, Paint()..color = accent.withOpacity(.20));
        canvas.drawCircle(pts[i], 6, Paint()..color = accent);
        canvas.drawCircle(pts[i], 3, Paint()..color = Colors.white);
      } else {
        canvas.drawCircle(pts[i], 4, Paint()..color = accent.withOpacity(.6));
        canvas.drawCircle(pts[i], 2.5, Paint()..color = Colors.white.withOpacity(.7));
      }
      final tp = TextPainter(
        text: TextSpan(
          text: "${trend[i].temperatureC.toStringAsFixed(0)}\u00b0",
          style: TextStyle(
            color: s2 ? accent : Colors.white60,
            fontSize: s2 ? 12 : 10,
            fontWeight: s2 ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pts[i].dx - tp.width / 2, pts[i].dy - 18));
      final dp = TextPainter(
        text: TextSpan(
          text: trend[i].day,
          style: TextStyle(
            color: s2 ? accent : Colors.white30,
            fontSize: 10,
            fontWeight: s2 ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      dp.paint(canvas, Offset(pts[i].dx - dp.width / 2, size.height - 16));
    }
  }

  @override
  bool shouldRepaint(covariant _TempPainter o) =>
      o.sel != sel || o.trend != trend;
}

class _ActiveDay {
  final double temperatureC, feelsLikeC, windSpeedKmh, humidityPercent, pressureHpa;
  final String windDirection, condition, dayLabel;
  const _ActiveDay({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.windSpeedKmh,
    required this.windDirection,
    required this.humidityPercent,
    required this.pressureHpa,
    required this.condition,
    required this.dayLabel,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});
  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen>
    with TickerProviderStateMixin {

  AppTimeTheme _appTheme = AppTimeTheme.forHour(DateTime.now().hour);
  int _selDay = 0;
  bool _entryAnimationPlayed = false;

  // ── ALL controllers stored as nullable so hot-reload never hits
  //    LateInitializationError. Getters assert non-null for convenience.
  AnimationController? _entryFadeC;
  AnimationController? _entrySlideC;
  AnimationController? _daySwitchC;

  Animation<double>?  _entryFadeA;
  Animation<Offset>?  _entrySlideA;
  Animation<double>?  _daySwitchA;

  // Safe non-null getters — only called after initState completes
  Animation<double>  get entryFade  => _entryFadeA!;
  Animation<Offset>  get entrySlide => _entrySlideA!;
  Animation<double>  get daySwitch  => _daySwitchA!;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final wp = context.read<WeatherProvider>();
      if (wp.status == WeatherStatus.loaded) _playEntryAnimation();
      wp.addListener(_onWeatherChanged);
      if (wp.status == WeatherStatus.initial) wp.fetchWeatherForCurrentLocation();
    });
  }

  void _initAnimations() {
    // Entry: full-screen fade + slide up, plays once on first data load
    _entryFadeC = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _entryFadeA = CurvedAnimation(parent: _entryFadeC!, curve: Curves.easeIn);

    _entrySlideC = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _entrySlideA = Tween<Offset>(begin: const Offset(0, .05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entrySlideC!, curve: Curves.easeOut));

    // Day-switch: only cross-fades the content panels, NOT the whole screen
    _daySwitchC = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _daySwitchA = CurvedAnimation(parent: _daySwitchC!, curve: Curves.easeInOut);
    // Start at 1.0 so content is immediately visible on first build
    _daySwitchC!.value = 1.0;
  }

  void _onWeatherChanged() {
    if (!mounted) return;
    if (context.read<WeatherProvider>().status == WeatherStatus.loaded) {
      _playEntryAnimation();
    }
  }

  void _playEntryAnimation() {
    if (_entryAnimationPlayed) return;
    _entryAnimationPlayed = true;
    _entryFadeC?.forward();
    _entrySlideC?.forward();
  }

  @override
  void dispose() {
    try {
      context.read<WeatherProvider>().removeListener(_onWeatherChanged);
    } catch (_) {}
    _entryFadeC?.dispose();
    _entrySlideC?.dispose();
    _daySwitchC?.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _openSearch() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const LocationSearchSheet(),
  );

  // Cross-fades only the content panels — top bar + day strip stay visible
  Future<void> _selectDay(int i) async {
    if (_selDay == i) return;
    await _daySwitchC?.reverse();
    if (!mounted) return;
    setState(() => _selDay = i);
    _daySwitchC?.forward();
  }

  _ActiveDay _getActiveDay(WeatherProvider wp) {
    if (_selDay == 0 || wp.forecast.isEmpty) {
      final cw = wp.currentWeather!;
      return _ActiveDay(
        temperatureC: cw.temperatureC, feelsLikeC: cw.feelsLikeC,
        windSpeedKmh: cw.windSpeedKmh, windDirection: cw.windDirection,
        humidityPercent: cw.humidityPercent, pressureHpa: 1013.25,
        condition: cw.condition, dayLabel: AppStrings.today,
      );
    }
    final df = wp.forecast[_selDay.clamp(0, wp.forecast.length - 1)];
    return _ActiveDay(
      temperatureC: df.temperatureC, feelsLikeC: df.temperatureC - 1.2,
      windSpeedKmh: df.windSpeedKmh, windDirection: '--',
      humidityPercent: df.humidityPercent, pressureHpa: 1013.25,
      condition: df.condition, dayLabel: df.day,
    );
  }

  IconData _weatherIcon(String cond) {
    switch (cond.toLowerCase()) {
      case 'rainy':         return Icons.water_drop_rounded;
      case 'cloudy':        return Icons.cloud_rounded;
      case 'partly cloudy': return Icons.wb_cloudy_rounded;
      case 'hot':           return Icons.wb_sunny_rounded;
      case 'cold':          return Icons.ac_unit_rounded;
      case 'stormy':        return Icons.thunderstorm_rounded;
      case 'windy':         return Icons.air_rounded;
      default:              return Icons.wb_cloudy_rounded;
    }
  }

  void _showFavoritesSwitcher(BuildContext context, WeatherConditionTheme condTheme) {
    final favorites = context.read<FavoritesProvider>().favorites;
    if (favorites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No favorites yet. Add from the Favorites tab.',
            style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: Colors.black.withOpacity(0.7),
      ));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: condTheme.skyGradient.last.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.15))),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15)),
                    child: const Icon(Icons.star_rounded, color: Colors.white, size: 16)),
                const SizedBox(width: 10),
                Text('Switch Location', style: GoogleFonts.dmSans(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 14),
              ...favorites.map((fav) {
                final isActive = context.read<WeatherProvider>().placeName == fav.name;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<WeatherProvider>().fetchWeatherForLocation(
                        lat: fav.latitude, lon: fav.longitude, name: fav.name);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isActive
                          ? Colors.white.withOpacity(0.28)
                          : Colors.white.withOpacity(0.12),
                      border: Border.all(
                          color: isActive
                              ? Colors.white.withOpacity(0.6)
                              : Colors.white.withOpacity(0.2),
                          width: isActive ? 1.5 : 1),
                    ),
                    child: Row(children: [
                      Container(width: 36, height: 36,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15)),
                          child: Icon(
                              isActive ? Icons.location_on_rounded : Icons.location_on_outlined,
                              color: isActive ? Colors.white : Colors.white60, size: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(fav.name, style: GoogleFonts.dmSans(
                          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis)),
                      if (isActive)
                        Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white.withOpacity(0.2)),
                            child: Text('Active', style: GoogleFonts.dmSans(
                                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))
                      else
                        const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
                    ]),
                  ),
                );
              }),
            ]),
          ),
        ),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Guard: if animations aren't ready yet (shouldn't happen after initState,
    // but protects against hot-reload edge cases), show a plain scaffold.
    if (_entryFadeA == null || _entrySlideA == null || _daySwitchA == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1565C0),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Consumer<WeatherProvider>(builder: (ctx, wp, _) {
      final condition = wp.currentWeather?.condition ?? 'sunny';
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
          child: SafeArea(child: _buildBody(wp, condTheme)),
        ),
      );
    });
  }

  Widget _buildBody(WeatherProvider wp, WeatherConditionTheme condTheme) {
    if (wp.status == WeatherStatus.loading || wp.status == WeatherStatus.initial) {
      return _buildLoading();
    }
    if (wp.status == WeatherStatus.error) return _buildError(wp);

    final day = _getActiveDay(wp);
    final dayCondTheme = WeatherConditionTheme.of(day.condition);

    // Entry animation: wraps everything, plays once
    return FadeTransition(
      opacity: entryFade,
      child: SlideTransition(
        position: entrySlide,
        child: Column(children: [

          // ── Top bar: NEVER animated on day-switch — stays fully visible ──
          _buildTopBar(wp, dayCondTheme),

          Expanded(
            child: RefreshIndicator(
              onRefresh: wp.refresh,
              color: dayCondTheme.accentColor,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(children: [

                  // Day-switch fade: only the data panels cross-fade
                  FadeTransition(
                    opacity: daySwitch,
                    child: Column(children: [
                      _buildHeroSection(wp, day, dayCondTheme),
                      _buildStatChips(day),
                    ]),
                  ),

                  const SizedBox(height: 20),

                  // Day strip: NEVER animated — always fully visible & tappable
                  _buildDayStrip(wp),

                  const SizedBox(height: 20),

                  // More data panels — also cross-fade on day-switch
                  FadeTransition(
                    opacity: daySwitch,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(children: [
                        _buildHourlyRow(wp, day),
                        const SizedBox(height: 18),
                        _buildGraph(wp, dayCondTheme),
                        const SizedBox(height: 18),
                        _buildWindHum(day),
                        const SizedBox(height: 30),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── TOP BAR ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(WeatherProvider wp, WeatherConditionTheme condTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25),
                    blurRadius: 10, offset: const Offset(0, 2))],
              ),
              padding: const EdgeInsets.all(4),
              child: Image.asset("assets/icon/App_Icon.png",
                  width: 36, height: 36, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.thunderstorm_rounded, color: Colors.white, size: 22)),
            ),
            const SizedBox(width: 8),
            Text('NCMRWF', style: GoogleFonts.dmSans(
                color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          ]),
          Consumer<FavoritesProvider>(
            builder: (_, fp, __) => GestureDetector(
              onTap: () => _showFavoritesSwitcher(context, condTheme),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                      if (fp.favorites.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                              color: Colors.white.withOpacity(0.25)),
                          child: Text('${fp.favorites.length}', style: GoogleFonts.dmSans(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 16),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HERO ───────────────────────────────────────────────────────────────────
  Widget _buildHeroSection(WeatherProvider wp, _ActiveDay day, WeatherConditionTheme condTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2)),
              child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 13)),
          const SizedBox(width: 6),
          Expanded(child: TranslatedText(
            wp.placeName.isEmpty ? AppStrings.fetchingLocation : wp.placeName,
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 15,
                fontWeight: FontWeight.w700,
                shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)]),
            overflow: TextOverflow.ellipsis,
          )),
          GestureDetector(
            onTap: _openSearch,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(.28))),
                  child: const Icon(Icons.search_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.25))),
          child: Text(_formatDate(DateTime.now().add(Duration(days: _selDay))),
              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.w600, letterSpacing: 0.2)),
        ),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(day.temperatureC.toStringAsFixed(0), style: GoogleFonts.dmSans(
                  color: Colors.white, fontSize: 88, fontWeight: FontWeight.w200, height: 0.9)),
              Padding(padding: const EdgeInsets.only(top: 10),
                  child: Text('°C', style: GoogleFonts.dmSans(
                      color: Colors.white70, fontSize: 30, fontWeight: FontWeight.w300))),
            ]),
            const SizedBox(height: 6),
            TranslatedText(day.condition, style: GoogleFonts.dmSans(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            FutureBuilder<String>(
              future: TranslatorService.translate(AppStrings.feelsLike),
              initialData: AppStrings.feelsLike,
              builder: (_, snap) => Text("${snap.data} ${day.feelsLikeC.toStringAsFixed(1)}°C",
                  style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 13)),
            ),
          ])),
          AnimatedWeatherIcon(condition: day.condition, size: 140),
        ]),
      ]),
    );
  }

  // ── STAT CHIPS ─────────────────────────────────────────────────────────────
  Widget _buildStatChips(_ActiveDay day) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(children: [
        _StatChip(icon: Icons.water_drop_rounded, iconColor: const Color(0xFF64B5F6),
            value: '${day.humidityPercent.toStringAsFixed(0)}%', labelKey: AppStrings.humidity),
        const SizedBox(width: 12),
        _StatChip(icon: Icons.air_rounded, iconColor: const Color(0xFF81C784),
            value: '${day.windSpeedKmh.toStringAsFixed(1)} km/h', labelKey: AppStrings.wind),
      ]),
    );
  }

  // ── DAY STRIP ──────────────────────────────────────────────────────────────
  Widget _buildDayStrip(WeatherProvider wp) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: TranslatedText(AppStrings.tenDayForecast, style: GoogleFonts.dmSans(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      SizedBox(
        height: 108,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: wp.forecast.length,
          itemBuilder: (ctx, i) {
            final sel = i == _selDay;
            final df = wp.forecast[i];
            final date = DateTime.now().add(Duration(days: i));
            final dayShort = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][date.weekday - 1];
            return GestureDetector(
              onTap: () => _selectDay(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(right: 8),
                width: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: sel ? Colors.white.withOpacity(0.28) : Colors.white.withOpacity(0.14),
                  border: Border.all(
                    color: sel ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.2),
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(dayShort, style: GoogleFonts.dmSans(
                          color: sel ? Colors.white : Colors.white70,
                          fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Icon(_weatherIcon(df.condition), color: Colors.white, size: 22),
                      const SizedBox(height: 4),
                      Text("${df.temperatureC.toStringAsFixed(0)}°", style: GoogleFonts.dmSans(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  // ── HOURLY ROW ─────────────────────────────────────────────────────────────
  Widget _buildHourlyRow(WeatherProvider wp, _ActiveDay day) {
    final base = day.temperatureC;
    final hrs = [AppStrings.now, "3h", "6h", "9h", "12h", "15h"];
    final ts = List.generate(6,
            (i) => base + sin(i * .8) * 2.5 + Random(_selDay * 6 + i).nextDouble() * 1.5);
    final useRealHourly = _selDay == 0 && wp.hourly.isNotEmpty;
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TranslatedText(AppStrings.now,
              style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white.withOpacity(0.3))),
            child: Text(_appTheme.label, style: GoogleFonts.dmSans(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(useRealHourly ? wp.hourly.length : 6, (i) {
            final t = useRealHourly ? wp.hourly[i].temperatureC : ts[i];
            final lbl = useRealHourly ? wp.hourly[i].label : hrs[i];
            final con = useRealHourly ? wp.hourly[i].condition : day.condition;
            return Column(children: [
              Icon(_weatherIcon(con), color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text("${t.toStringAsFixed(0)}°", style: GoogleFonts.dmSans(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(lbl, style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 11)),
            ]);
          }),
        ),
      ]),
    );
  }

  // ── GRAPH ──────────────────────────────────────────────────────────────────
  List<TrendPoint> _limit(List<TrendPoint> full) {
    if (full.length <= 10) return full;
    final result = <TrendPoint>[];
    final step = (full.length - 1) / 9;
    for (int i = 0; i < 10; i++) result.add(full[(i * step).round()]);
    return result;
  }

  Widget _buildGraph(WeatherProvider wp, WeatherConditionTheme condTheme) {
    if (wp.trend.isEmpty) return const SizedBox.shrink();
    final data = _limit(wp.trend);
    final mn = wp.minTemp - 2;
    final mx = wp.maxTemp + 2;
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TranslatedText(AppStrings.temperatureTrend, style: GoogleFonts.dmSans(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          TranslatedText(AppStrings.tapToSelectDay, style: GoogleFonts.dmSans(
              color: Colors.white38, fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        Text(wp.placeName, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 16),
        GestureDetector(
          onTapDown: (d) {
            final w = MediaQuery.of(context).size.width - 80;
            final idx = ((d.localPosition.dx / w) * (data.length - 1))
                .round().clamp(0, data.length - 1);
            _selectDay(idx);
          },
          child: SizedBox(
            height: 150,
            child: CustomPaint(
              size: const Size(double.infinity, 150),
              painter: _TempPainter(trend: data, mn: mn, mx: mx,
                  range: mx - mn, sel: _selDay, accent: condTheme.accentColor),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          FutureBuilder<String>(
            future: TranslatorService.translate(AppStrings.min),
            initialData: AppStrings.min,
            builder: (_, s) => Text("${s.data}: ${wp.minTemp.toStringAsFixed(1)}°C",
                style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11)),
          ),
          FutureBuilder<String>(
            future: TranslatorService.translate(AppStrings.max),
            initialData: AppStrings.max,
            builder: (_, s) => Text("${s.data}: ${wp.maxTemp.toStringAsFixed(1)}°C",
                style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11)),
          ),
        ]),
      ]),
    );
  }

  // ── WIND + HUMIDITY ────────────────────────────────────────────────────────
  Widget _buildWindHum(_ActiveDay day) {
    final hum = day.humidityPercent;
    final wkh = day.windSpeedKmh;
    final humLabel = hum > 70 ? AppStrings.high : hum > 40 ? AppStrings.moderate : AppStrings.low;
    return Row(children: [
      Expanded(child: _detCard(Icons.air_rounded, AppStrings.wind,
          wkh.toStringAsFixed(1), 'km/h',
          "${AppStrings.direction}: ${day.windDirection}",
          (wkh / 100).clamp(0.0, 1.0), const Color(0xFF81C784))),
      const SizedBox(width: 12),
      Expanded(child: _detCard(Icons.water_drop_rounded, AppStrings.humidity,
          hum.toStringAsFixed(0), '%', humLabel,
          hum / 100, const Color(0xFF64B5F6))),
    ]);
  }

  Widget _detCard(IconData ico, String title, String val, String unit,
      String sub, double prog, Color c) =>
      _GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(ico, color: c, size: 20), const SizedBox(width: 8),
          TranslatedText(title, style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 13)),
        ]),
        const SizedBox(height: 10),
        RichText(text: TextSpan(children: [
          TextSpan(text: val, style: GoogleFonts.dmSans(
              color: Colors.white, fontSize: 32, fontWeight: FontWeight.w200)),
          TextSpan(text: " $unit", style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13)),
        ])),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: prog,
                backgroundColor: Colors.white.withOpacity(.15),
                valueColor: AlwaysStoppedAnimation<Color>(c), minHeight: 4)),
        const SizedBox(height: 8),
        TranslatedText(sub, style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12)),
      ]));

  // ── LOADING ────────────────────────────────────────────────────────────────
  Widget _buildLoading() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15)),
          child: const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 44)),
      const SizedBox(height: 24),
      TranslatedText(AppStrings.weatherForecast, style: GoogleFonts.dmSans(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      TranslatedText(AppStrings.fetchingLocation, style: GoogleFonts.dmSans(
          color: Colors.white60, fontSize: 13)),
      const SizedBox(height: 28),
      SizedBox(width: 200, child: ClipRRect(borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(backgroundColor: Colors.white.withOpacity(.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), minHeight: 3))),
    ]),
  );

  // ── ERROR ──────────────────────────────────────────────────────────────────
  Widget _buildError(WeatherProvider wp) => Center(
    child: Padding(padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15)),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 38)),
          const SizedBox(height: 24),
          TranslatedText(AppStrings.unableToLoad, style: GoogleFonts.dmSans(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(wp.errorMessage, style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: wp.refresh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(30),
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white.withOpacity(0.4))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                TranslatedText(AppStrings.retry, style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ]),
            ),
          ),
        ])),
  );
}

// ─── STAT CHIP ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String labelKey;
  const _StatChip({required this.icon, required this.iconColor,
    required this.value, required this.labelKey});

  @override
  Widget build(BuildContext context) => Expanded(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.28)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.dmSans(color: Colors.white,
                fontSize: 13, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            TranslatedText(labelKey,
                style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 10)),
          ]),
        ),
      ),
    ),
  );
}