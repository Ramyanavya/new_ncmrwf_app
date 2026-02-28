// lib/main.dart
// REDESIGNED: Bottom nav bar uses frosted glass over the gradient background.
// AppTimeTheme kept for backward compat but new screens use WeatherConditionTheme.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_ncmrwf_app/services/local_notification_service.dart';
import 'package:new_ncmrwf_app/utils/weather_condition_theme.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/weather_provider.dart';
import 'providers/app_providers.dart';
import 'screens/forecast_screen.dart';
import 'screens/products_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/app_strings.dart';
import 'utils/translated_text.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // OneSignal Debug (optional)
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

  // Initialize OneSignal
  OneSignal.initialize("966404a4-cd8a-4d04-b1f5-9a78a8b5e20d");
  await LocalNotificationService.initialize();
  if (Platform.isAndroid) {
    await Permission.notification.request();
  }
  // Request notification permission
  OneSignal.Notifications.requestPermission(true);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  final favProvider = FavoritesProvider();
  await favProvider.loadFavorites();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => WeatherProvider()),
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ChangeNotifierProvider(create: (_) => favProvider),
  ], child: const NCMRWFApp()));
}

class NCMRWFApp extends StatelessWidget {
  const NCMRWFApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF060D1A),
      ),
      home: const MainShell(),
    );
  }
}

// ─── AppTimeTheme kept for any legacy usage ───────────────────────────────────
class AppTimeTheme {
  final List<Color> bgColors;
  final List<Color> glowColors;
  final Color accent;
  final String label;
  const AppTimeTheme({
    required this.bgColors,
    required this.glowColors,
    required this.accent,
    required this.label,
  });

  static AppTimeTheme forHour(int h) {
    if (h >= 5 && h < 9) return const AppTimeTheme(
      bgColors: [Color(0xFF0D2137), Color(0xFF1A3A5C), Color(0xFF1E4976)],
      glowColors: [Color(0xFF4FC3F7), Color(0xFFFFCC80)],
      accent: Color(0xFF81D4FA), label: 'Cool Morning',
    );
    if (h >= 9 && h < 16) return const AppTimeTheme(
      bgColors: [Color(0xFF1C0A00), Color(0xFF3E1F00), Color(0xFF6D3A00)],
      glowColors: [Color(0xFFFF8C42), Color(0xFFFFD166)],
      accent: Color(0xFFFFB347), label: 'Hot Day',
    );
    if (h >= 16 && h < 18) return const AppTimeTheme(
      bgColors: [Color(0xFF12213A), Color(0xFF1E3A5F), Color(0xFF2D5282)],
      glowColors: [Color(0xFFFFAB76), Color(0xFF80DEEA)],
      accent: Color(0xFFFFAB76), label: 'Mid Day',
    );
    return const AppTimeTheme(
      bgColors: [Color(0xFF060D1A), Color(0xFF0D1B2A), Color(0xFF111F35)],
      glowColors: [Color(0xFF1565C0), Color(0xFF4A148C)],
      accent: Color(0xFF90CAF9), label: 'Night',
    );
  }
}

// ─── Legacy animated background (kept for any screen that still uses it) ──────
class AppAnimBg extends StatefulWidget {
  final AppTimeTheme theme;
  const AppAnimBg({super.key, required this.theme});
  @override
  State<AppAnimBg> createState() => _AppAnimBgState();
}

class _AppAnimBgState extends State<AppAnimBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;
    final c1 = widget.theme.glowColors[0];
    final c2 = widget.theme.glowColors[1];
    return AnimatedBuilder(
        animation: _a,
        builder: (_, __) => Stack(children: [
          Container(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: widget.theme.bgColors))),
          Positioned(top: -60 + _a.value * 30, right: -60 + _a.value * 20,
              child: Container(width: s.width * .75, height: s.width * .75,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        c1.withOpacity(.35), c1.withOpacity(.10),
                        Colors.transparent
                      ])))),
          Positioned(bottom: 80 - _a.value * 40, left: -80 + _a.value * 20,
              child: Container(width: s.width * .65, height: s.width * .65,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        c2.withOpacity(.28), c2.withOpacity(.08),
                        Colors.transparent
                      ])))),
        ]));
  }
}

// ─── GLASS CARD (shared) ──────────────────────────────────────────────────────
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 20,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                  color: borderColor ?? Colors.white.withOpacity(0.28)),
            ),
            child: child)),
  );
}

// ─── MAIN SHELL ───────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  final _screens = const [
    ForecastScreen(),
    ProductsScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  static const _tabLabels = [
    AppStrings.forecast,
    AppStrings.products,
    AppStrings.favorites,
    AppStrings.settings,
  ];

  static const _tabIcons = [
    (Icons.cloud_outlined, Icons.cloud),
    (Icons.map_outlined, Icons.map),
    (Icons.star_outline_rounded, Icons.star_rounded),
    (Icons.settings_outlined, Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();

    // Nav bar tint from current weather condition
    final wp = context.watch<WeatherProvider>();
    final condition = wp.currentWeather?.condition ?? 'sunny';
    final condTheme = WeatherConditionTheme.of(condition);
    final navBase = condTheme.skyGradient.last;

    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: navBase.withOpacity(0.75),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(4, (i) {
                    final sel = i == _idx;
                    return GestureDetector(
                      onTap: () => setState(() => _idx = i),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 72,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? Colors.white.withOpacity(0.22)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                    sel
                                        ? _tabIcons[i].$2
                                        : _tabIcons[i].$1,
                                    color: sel
                                        ? Colors.white
                                        : Colors.white38,
                                    size: 24),
                              ),
                              const SizedBox(height: 3),
                              TranslatedText(
                                _tabLabels[i],
                                style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : Colors.white38,
                                    fontSize: 10,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w400),
                              ),
                            ]),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}