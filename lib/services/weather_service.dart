import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../logger.dart';

class WeatherService {
  final String apiKey = dotenv.env['TOMORROW_API_KEY'] ?? '';

  Future<Map<String, dynamic>> fetchCurrentWeather(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.tomorrow.io/v4/timelines?location=$lat,$lon&fields=temperature,weatherCode,windSpeed,humidity&units=metric&timesteps=current&apikey=$apiKey',
    );

    final response = await http.get(url);
    logger.info('fetchCurrentWeather URL: $url');
    logger.info('Status code: ${response.statusCode}');
    logger.info('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final values = jsonData['data']['timelines'][0]['intervals'][0]['values'];

      return {
        'temperature': values['temperature'],
        'weatherCode': values['weatherCode'],
        'windSpeed': values['windSpeed'],
        'humidity': values['humidity'],
      };
    } else {
      logger.severe('Failed to load weather data with status ${response.statusCode}');
      throw Exception('Failed to load weather data with status ${response.statusCode}');
    }
  }

  /// Ambil hourly forecast tanpa filter tanggal (ambil beberapa jam ke depan)
  Future<List<Map<String, dynamic>>> fetchHourlyForecast(double lat, double lon, {int hours = 48}) async {
    final url = Uri.parse(
      'https://api.tomorrow.io/v4/timelines?location=$lat,$lon&fields=temperature,weatherCode&units=metric&timesteps=1h&apikey=$apiKey',
    );

    final response = await http.get(url);
    logger.info('fetchHourlyForecast URL: $url');
    logger.info('Status code: ${response.statusCode}');
    logger.info('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final intervals = jsonData['data']['timelines'][0]['intervals'] as List;
      return intervals.take(hours).map((interval) {
        final values = interval['values'];
        final time = interval['startTime'];
        return {
          'time': time,
          'temperature': values['temperature'],
          'weatherCode': values['weatherCode'],
        };
      }).toList();
    } else {
      logger.severe('Failed to load hourly forecast with status ${response.statusCode}');
      throw Exception('Failed to load hourly forecast with status ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchDailyForecast(double lat, double lon,
      {int days = 5}) async {
    final url = Uri.parse(
      'https://api.tomorrow.io/v4/timelines?location=$lat,$lon&fields=temperatureMax,temperatureMin,weatherCode&units=metric&timesteps=1d&apikey=$apiKey',
    );

    final response = await http.get(url);
    logger.info('fetchDailyForecast URL: $url');
    logger.info('Status code: ${response.statusCode}');
    logger.info('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final intervals = jsonData['data']['timelines'][0]['intervals'] as List;
      return intervals.take(days).map((interval) {
        final values = interval['values'];
        final time = interval['startTime'];
        return {
          'date': time,
          'tempMax': values['temperatureMax'],
          'tempMin': values['temperatureMin'],
          'weatherCode': values['weatherCode'],
        };
      }).toList();
    } else {
      logger.severe('Failed to load daily forecast with status ${response.statusCode}');
      throw Exception('Failed to load daily forecast with status ${response.statusCode}');
    }
  }
}
