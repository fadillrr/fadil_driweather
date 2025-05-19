import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';
import '../services/weather_service.dart';
import '../logger.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final WeatherService weatherService = WeatherService();

  bool isLoading = true;
  String errorMessage = '';

  double temperature = 0;
  int weatherCode = 0;
  double windSpeed = 0;
  double humidity = 0;

  List<Map<String, dynamic>> hourlyForecast = [];
  List<Map<String, dynamic>> dailyForecast = [];

  final double latitude = -7.0051;
  final double longitude = 110.4381;

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchAllWeather();
  }

  Future<void> _fetchAllWeather() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final current = await weatherService.fetchCurrentWeather(latitude, longitude);
      final allHourly = await weatherService.fetchHourlyForecast(latitude, longitude, hours: 72);
      final daily = await weatherService.fetchDailyForecast(latitude, longitude);

      final now = DateTime.now();

      final hourly = allHourly.where((item) {
        final dt = DateTime.parse(item['time']).toLocal();
        return dt.isAfter(now) &&
            dt.year == selectedDate.year &&
            dt.month == selectedDate.month &&
            dt.day == selectedDate.day;
      }).toList();

      for (var day in daily) {
        logger.info('Daily forecast date: ${day['date']}, weatherCode: ${day['weatherCode']}');
      }

      setState(() {
        temperature = (current['temperature'] as num).toDouble();
        weatherCode = current['weatherCode'] as int;
        windSpeed = (current['windSpeed'] as num).toDouble();
        humidity = (current['humidity'] as num).toDouble();
        hourlyForecast = hourly;
        dailyForecast = daily;
        isLoading = false;
      });
    } catch (e, stack) {
      logger.severe('Error fetching weather: $e\n$stack');
      setState(() {
        errorMessage = 'Failed to load weather data:\n$e';
        isLoading = false;
      });
    }
  }

  IconData _mapWeatherIcon(int code) {
    switch (code) {
      case 1000:
        return WeatherIcons.day_sunny;
      case 1100:
        return WeatherIcons.day_sunny_overcast;
      case 1101:
        return WeatherIcons.day_cloudy;
      case 1102:
        return WeatherIcons.cloudy;
      case 2000:
        return WeatherIcons.fog;
      case 2100:
        return WeatherIcons.night_fog;
      case 3000:
        return WeatherIcons.wind;
      case 3001:
        return WeatherIcons.strong_wind;
      case 3002:
        return WeatherIcons.cloudy_gusts;
      case 4000:
      case 4001:
        return WeatherIcons.sprinkle;
      case 4200:
        return WeatherIcons.rain_mix;
      case 4201:
        return WeatherIcons.rain_wind;
      case 5000:
      case 5100:
        return WeatherIcons.snow;
      case 5001:
      case 5101:
        return WeatherIcons.snow_wind;
      case 6000:
      case 6200:
        return WeatherIcons.rain_mix;
      case 6001:
      case 6201:
        return WeatherIcons.sleet;
      case 7000:
      case 7101:
        return WeatherIcons.thunderstorm;
      case 7102:
        return WeatherIcons.showers;
      case 8000:
        return WeatherIcons.thunderstorm;
      case 8001:
        return WeatherIcons.night_clear;
      default:
        return WeatherIcons.na;
    }
  }

  String _formatHour(String isoTime) {
    final dateTime = DateTime.parse(isoTime).toLocal();
    return "${dateTime.hour.toString().padLeft(2, '0')}:00";
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${months[dateTime.month]}, ${dateTime.day}";
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 3)),
      lastDate: DateTime.now().add(const Duration(days: 14)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      await _fetchAllWeather();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 137, 196, 255),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
        ),
        title: const Text('Weather Details', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Today',
                                style: TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                            Row(
                              children: [
                                Text(_formatDate(selectedDate),
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16)),
                                const SizedBox(width: 4),
                                const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: hourlyForecast.length,
                          itemBuilder: (context, index) {
                            final item = hourlyForecast[index];
                            final dt = DateTime.parse(item['time']).toLocal();

                            final isCurrentHour = dt.year == now.year &&
                                dt.month == now.month &&
                                dt.day == now.day &&
                                dt.hour == now.hour;

                            return Container(
                              width: 60,
                              margin: EdgeInsets.only(right: index == hourlyForecast.length - 1 ? 0 : 18),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isCurrentHour
                                    ? Colors.white.withAlpha(100)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: isCurrentHour
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item['temperature'].toStringAsFixed(0)}°C',
                                    style: TextStyle(
                                        color: isCurrentHour ? Colors.white : Colors.white70,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16),
                                  ),
                                  Icon(_mapWeatherIcon(item['weatherCode']),
                                      color: Colors.yellow.shade300, size: 30),
                                  Text(
                                    _formatHour(item['time']),
                                    style: TextStyle(
                                        color: isCurrentHour ? Colors.white : Colors.white70,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text('Next Forecast',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          thickness: 4,
                          radius: const Radius.circular(20),
                          child: ListView.builder(
                            itemCount: dailyForecast.length,
                            itemBuilder: (context, index) {
                              final item = dailyForecast[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                child: Row(
                                  children: [
                                    Text(
                                      _formatDate(DateTime.parse(item['date'])),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(width: 20),
                                    Icon(_mapWeatherIcon(item['weatherCode']),
                                        color: Colors.white, size: 22),
                                    const Spacer(),
                                    Text(
                                      '${item['tempMax'].toStringAsFixed(0)}°',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
