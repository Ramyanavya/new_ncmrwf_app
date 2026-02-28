// lib/utils/app_strings.dart
//
// Single source of truth — English strings only.
// Hindi (and any other language) is handled automatically
// at runtime by TranslatorService (Google ML Kit).
//
// Usage:  AppStrings.weatherForecast   → 'Weather Forecast'
// Then wrap in TranslatedText() or TranslatorService.translate()

class AppStrings {
  // ── App ────────────────────────────────────────────────────────
  static const String appName           = 'NCMRWF Weather';
  static const String fetchingLocation  = 'Fetching location...';
  static const String retry             = 'Retry';
  static const String unableToLoad      = 'Unable to load weather data';
  static const String close             = 'Close';

  // ── Forecast screen ───────────────────────────────────────────
  static const String weatherForecast   = 'Weather Forecast';
  static const String feelsLike         = 'Feels like';
  static const String humidity          = 'Humidity';
  static const String wind              = 'Wind';
  static const String level             = 'Level';
  static const String tenDayForecast    = '10-Day Forecast';
  static const String now               = 'Now';
  static const String pressureLevel     = 'Pressure Level';
  static const String temperatureTrend  = 'Temperature Trend';
  static const String tapToSelectDay    = 'Tap to select day';
  static const String direction         = 'Direction';
  static const String moderate          = 'Moderate';
  static const String high              = 'High';
  static const String low               = 'Low';
  static const String min               = 'Min';
  static const String max               = 'Max';

  // ── Nav tabs ──────────────────────────────────────────────────
  static const String forecast          = 'Forecast';
  static const String products          = 'Map';
  static const String favorites         = 'Favorites';
  static const String settings          = 'Settings';

  // ── Products screen ───────────────────────────────────────────
  static const String temperatureAnalysis = 'Temperature Analysis';
  static const String windAnalysis        = 'Wind Analysis';
  static const String humidityAnalysis    = 'Humidity Analysis';
  static const String surfaceTemp         = 'Surface Temp';
  static const String tenDaySummary       = '10-Day Summary Table';
  static const String loadForecastFirst   = 'Load forecast first from the Forecast tab';

  // ── Favorites screen ──────────────────────────────────────────
  static const String noFavorites           = 'No favorites yet';
  static const String addFavoritesHint      = 'Search and add locations to favorites';
  static const String addLocation           = 'Add Location';
  static const String addCurrent            = 'Add Current';
  static const String locationAdded         = 'Added to favorites!';
  static const String locationAlreadyAdded  = 'Location already in favorites';
  static const String favoritesLimitReached = 'Favorites limit reached (max 5)';
  static const String favoritesFull         = 'Limit reached';
  static const String searchHint            = 'Search city, village, district...';
  static const String useDefaultLocation    = 'Use default location (New Delhi)';

  // ── Settings screen ───────────────────────────────────────────
  static const String language          = 'Language / भाषा';
  static const String about             = 'About';
  static const String aboutApp          = 'About the App';
  static const String aboutVersion      = 'Version 1.0.0';
  static const String faqs             = 'FAQs';
  static const String faqsSub          = 'Frequently Asked Questions';
  static const String privacy           = 'Privacy Policy';
  static const String privacySub        = 'How we handle your data';
  static const String dataSource        = 'Data Source';
  static const String dataSourceTitle   = 'NCMRWF NWP Data';

  static const String aboutContent =
      'NCMRWF Weather Forecast App provides real-time weather data from the '
      'National Centre for Medium Range Weather Forecasting.\n\n'
      'Version: 1.0.0\n'
      'Data: NWP Model (925mb, 850mb, 700mb, 500mb, 200mb)\n'
      'Coverage: India and surrounding regions';

  static const String privacyContent =
      '1. Location: Used only to fetch weather. Not stored on servers.\n\n'
      '2. Favorites: Stored locally on device only.\n\n'
      '3. No Ads.\n\n'
      '4. No Personal Data Collection.\n\n'
      '5. Internet: Required to fetch weather data.';

  static const String dataSourceDesc =
      'Weather data from National Centre for Medium Range Weather Forecasting '
      '(NCMRWF), Ministry of Earth Sciences, Government of India.';

  // ── FAQs ──────────────────────────────────────────────────────
  static const List<Map<String, String>> faqList = [
    {
      'q': 'What data does this app use?',
      'a': 'The app uses NWP data from NCMRWF — temperature, wind and humidity '
          'at 925mb, 850mb, 700mb, 500mb and 200mb pressure levels.',
    },
    {
      'q': 'What is a pressure level?',
      'a': '925mb is near the surface (~750m), while 200mb is very high (~12km). '
          'For surface weather, 925mb is most relevant.',
    },
    {
      'q': 'How accurate is the forecast?',
      'a': 'NCMRWF NWP model provides forecasts up to 10 days. '
          'Short-range (1-3 days) forecasts are most accurate.',
    },
    {
      'q': 'How do I change the language?',
      'a': 'Go to Settings → Language and tap English or Hindi. '
          'The entire app changes immediately.',
    },
    {
      'q': 'How often is the data updated?',
      'a': 'NC data files update every 6 or 12 hours. Pull down to refresh.',
    },
  ];

  // Products screen labels (used as map keys — translated at runtime)
  static const String surfaceTempLabel   = 'Surface Temp';
  static const String feelsLikeLabel     = 'Feels Like';
  static const String minTenDay          = 'Min (10-day)';
  static const String maxTenDay          = 'Max (10-day)';
  static const String speed              = 'Speed';
  static const String relativeHumidity   = 'Relative Humidity';
  static const String category           = 'Category';
  static const String day                = 'Day';
  static const String temp               = 'Temp';
  static const String today              = 'Today';
}