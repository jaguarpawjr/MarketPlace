import 'dart:convert';

import 'package:http/http.dart' as http;

class Forecast {
  final int timepoint; // hours ahead
  final int? tempC;
  final int? rh2m;
  final int? windSpeed;
  final String? windDir;
  final int? cloudcover;

  Forecast({
    required this.timepoint,
    this.tempC,
    this.rh2m,
    this.windSpeed,
    this.windDir,
    this.cloudcover,
  });
}

class DailyForecast {
  final DateTime date;
  final int? tempMax;
  final int? tempMin;
  final double? precipitation;

  DailyForecast({
    required this.date,
    this.tempMax,
    this.tempMin,
    this.precipitation,
  });
}

class WeatherData {
  final String timezone;
  final List<Forecast> series; // hourly
  final List<DailyForecast> daily;

  WeatherData({
    required this.timezone,
    required this.series,
    required this.daily,
  });
}

class WeatherService {
  /// Uses Open-Meteo (no API key required) to fetch hourly forecast data.
  /// Returns forecasts with `timepoint` expressed as hours ahead from now.
  static Future<WeatherData> fetchWeather({
    required double lat,
    required double lon,
    int hours = 48,
  }) async {
    final params = {
      'latitude': lat.toString(),
      'longitude': lon.toString(),

      'hourly':
          'temperature_2m,relative_humidity_2m,cloud_cover,wind_speed_10m,wind_direction_10m',

      'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum',

      'current_weather': 'true',
      'timezone': 'auto',
    };

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', params);
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load weather (${res.statusCode})');
    }

    final Map<String, dynamic> json = jsonDecode(res.body);
    final hourly = json['hourly'] as Map<String, dynamic>?;
    if (hourly == null) {
      throw Exception('No hourly data in response');
    }

    final List<dynamic> times = hourly['time'] as List<dynamic>? ?? [];
    final List<dynamic> temps =
        hourly['temperature_2m'] as List<dynamic>? ?? [];
    final List<dynamic> rh =
        hourly['relative_humidity_2m'] as List<dynamic>? ?? [];

    final List<dynamic> cloud = hourly['cloud_cover'] as List<dynamic>? ?? [];

    final List<dynamic> windSp =
        hourly['wind_speed_10m'] as List<dynamic>? ?? [];

    final List<dynamic> windDir =
        hourly['wind_direction_10m'] as List<dynamic>? ?? [];

    final now = DateTime.now();

    // Build list of (index, datetime) and find the index nearest to now
    final dateTimes = <DateTime>[];
    for (final t in times) {
      try {
        dateTimes.add(DateTime.parse(t as String).toLocal());
      } catch (_) {
        dateTimes.add(now);
      }
    }

    if (dateTimes.isEmpty) {
      throw Exception('Empty time series from weather API');
    }

    int closest = 0;
    var bestDiff = dateTimes[0].difference(now).abs();
    for (var i = 1; i < dateTimes.length; i++) {
      final d = dateTimes[i].difference(now).abs();
      if (d < bestDiff) {
        bestDiff = d;
        closest = i;
      }
    }

    final list = <Forecast>[];
    final maxCount = (dateTimes.length - closest).clamp(0, hours);
    for (var i = 0; i < maxCount; i++) {
      final idx = closest + i;
      final dt = dateTimes[idx];
      final hoursAhead = dt.difference(now).inHours;
      final tempVal = idx < temps.length ? temps[idx] : null;
      final rhVal = idx < rh.length ? rh[idx] : null;
      final cloudVal = idx < cloud.length ? cloud[idx] : null;
      final wSp = idx < windSp.length ? windSp[idx] : null;
      final wDir = idx < windDir.length ? windDir[idx] : null;

      list.add(
        Forecast(
          timepoint: hoursAhead,
          tempC: tempVal != null ? (tempVal as num).round() : null,
          rh2m: rhVal != null ? (rhVal as num).round() : null,
          windSpeed: wSp != null ? (wSp as num).round() : null,
          windDir: wDir != null ? _degToDir((wDir as num).toDouble()) : null,
          cloudcover: cloudVal != null ? (cloudVal as num).round() : null,
        ),
      );
    }

    // parse daily
    final dailyMap = json['daily'] as Map<String, dynamic>?;
    final dailyList = <DailyForecast>[];
    if (dailyMap != null) {
      final List<dynamic> dTimes = dailyMap['time'] as List<dynamic>? ?? [];
      final List<dynamic> tMax =
          dailyMap['temperature_2m_max'] as List<dynamic>? ?? [];
      final List<dynamic> tMin =
          dailyMap['temperature_2m_min'] as List<dynamic>? ?? [];
      final List<dynamic> prec =
          dailyMap['precipitation_sum'] as List<dynamic>? ?? [];
      for (var i = 0; i < dTimes.length; i++) {
        DateTime dt;
        try {
          dt = DateTime.parse(dTimes[i] as String).toLocal();
        } catch (_) {
          dt = now.add(Duration(days: i));
        }
        dailyList.add(
          DailyForecast(
            date: dt,
            tempMax: i < tMax.length && tMax[i] != null
                ? (tMax[i] as num).round()
                : null,
            tempMin: i < tMin.length && tMin[i] != null
                ? (tMin[i] as num).round()
                : null,
            precipitation: i < prec.length && prec[i] != null
                ? (prec[i] as num).toDouble()
                : null,
          ),
        );
      }
    }

    return WeatherData(
      timezone: json['timezone'] ?? '',
      series: list,
      daily: dailyList,
    );
  }

  static String _degToDir(double deg) {
    const dirs = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW',
    ];
    final idx = ((deg + 11.25) % 360) ~/ 22.5;
    return dirs[idx % dirs.length];
  }
}
