class CurrentWeather {
  final double latitude;
  final double longitude;
  final String level;
  final double temperatureC;
  final double feelsLikeC;
  final double windSpeedKmh;
  final String windDirection;
  final double humidityPercent;
  final int pressureMb;
  final String condition;
  final String? dataTime;

  CurrentWeather({
    required this.latitude,
    required this.longitude,
    required this.level,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.windSpeedKmh,
    required this.windDirection,
    required this.humidityPercent,
    required this.pressureMb,
    required this.condition,
    this.dataTime,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      level: json['level'] ?? '925mb',
      temperatureC: (json['temperature_c'] as num).toDouble(),
      feelsLikeC: (json['feels_like_c'] as num).toDouble(),
      windSpeedKmh: (json['wind_speed_kmh'] as num).toDouble(),
      windDirection: json['wind_direction'] ?? 'N',
      humidityPercent: (json['humidity_percent'] as num).toDouble(),
      pressureMb: (json['pressure_mb'] as num).toInt(),
      condition: json['condition'] ?? 'Cloudy',
      dataTime: json['data_time'],
    );
  }
}

class DayForecast {
  final String date;
  final String day;
  final double temperatureC;
  final double windSpeedKmh;
  final double humidityPercent;
  final String condition;

  DayForecast({
    required this.date,
    required this.day,
    required this.temperatureC,
    required this.windSpeedKmh,
    required this.humidityPercent,
    required this.condition,
  });

  factory DayForecast.fromJson(Map<String, dynamic> json) {
    return DayForecast(
      date: json['date'],
      day: json['day'],
      temperatureC: (json['temperature_c'] as num).toDouble(),
      windSpeedKmh: (json['wind_speed_kmh'] as num).toDouble(),
      humidityPercent: (json['humidity_percent'] as num).toDouble(),
      condition: json['condition'] ?? 'Cloudy',
    );
  }
}

class HourlyWeather {
  final String label;
  final String datetime;
  final double temperatureC;
  final double windSpeedKmh;
  final double humidityPercent;
  final String condition;

  HourlyWeather({
    required this.label,
    required this.datetime,
    required this.temperatureC,
    required this.windSpeedKmh,
    required this.humidityPercent,
    required this.condition,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    return HourlyWeather(
      label: json['label'],
      datetime: json['datetime'],
      temperatureC: (json['temperature_c'] as num).toDouble(),
      windSpeedKmh: (json['wind_speed_kmh'] as num).toDouble(),
      humidityPercent: (json['humidity_percent'] as num).toDouble(),
      condition: json['condition'] ?? 'Cloudy',
    );
  }
}

class TrendPoint {
  final String day;
  final String date;
  final double temperatureC;

  TrendPoint({required this.day, required this.date, required this.temperatureC});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      day: json['day'],
      date: json['date'],
      temperatureC: (json['temperature_c'] as num).toDouble(),
    );
  }
}

class FavoriteLocation {
  final String name;
  final double latitude;
  final double longitude;

  FavoriteLocation({required this.name, required this.latitude, required this.longitude});

  Map<String, dynamic> toJson() => {'name': name, 'latitude': latitude, 'longitude': longitude};

  factory FavoriteLocation.fromJson(Map<String, dynamic> json) => FavoriteLocation(
        name: json['name'],
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
}
