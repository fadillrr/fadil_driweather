import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/weather_service.dart';
import 'search_location.dart';
import '../logger.dart';
import 'weather_page.dart';  // Import halaman weather detail

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WeatherService weatherService = WeatherService();

  String city = "Surakarta";
  String temperature = "-";
  String weatherDesc = "-";
  String windSpeed = "-";
  String humidity = "-";
  bool isLoading = true;
  String? errorMessage;

  double latitude = -7.0051;
  double longitude = 110.4381;

  int _currentWeatherCode = -1;
  bool showNotificationPanel = false;

  final List<NotificationItem> newNotifications = [
    NotificationItem(
      icon: WeatherIcons.day_sunny,
      time: "10 minutes ago",
      title: "A sunny day in your location, consider wearing your UV protection",
    ),
  ];

  final List<NotificationItem> earlierNotifications = [
    NotificationItem(
      icon: WeatherIcons.wind,
      time: "1 day ago",
      title: "A cloudy day will occur all day long, don't worry about the heat of the sun",
    ),
    NotificationItem(
      icon: WeatherIcons.cloud_refresh,
      time: "2 days ago",
      title: "Potential for rain today is 84%, don't forget to bring your umbrella.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    logger.info("HomePage initState: cek permission dan load lokasi");
    _checkLocationPermissionAndLoad();
  }

  Future<void> _checkLocationPermissionAndLoad() async {
    logger.info("Cek service location");
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showLocationServiceDialog();
      logger.warning("Service lokasi mati, fallback ke default");
      _loadWeather(latitude, longitude);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    logger.info("Permission: $permission");

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      logger.info("Request permission hasil: $permission");

      if (permission == LocationPermission.denied) {
        _showPermissionDeniedMessage();
        _loadWeather(latitude, longitude);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionDeniedForeverDialog();
      _loadWeather(latitude, longitude);
      return;
    }

    logger.info("Permission diberikan, ambil posisi");
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    logger.info("Posisi ditemukan: ${position.latitude}, ${position.longitude}");
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
      isLoading = true;
    });

    await _loadWeather(latitude, longitude);
    await _updateCityNameFromCoordinates(latitude, longitude);
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Location Service Disabled"),
        content: const Text("Please enable location services to get accurate weather data."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Location permission denied. Using default location.")),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Location Permission Permanently Denied"),
        content: const Text("Please enable location permissions from app settings."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCityNameFromCoordinates(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        setState(() {
          city = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? city;
          logger.info("City name updated dari reverse geocode: $city");
        });
      }
    } catch (e) {
      logger.warning("Error reverse geocode: $e");
    }
  }

  Future<void> _loadWeather(double lat, double lon) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await weatherService.fetchCurrentWeather(lat, lon);

      final tempVal = data['temperature'];
      final tempDouble = tempVal is double
          ? tempVal
          : (tempVal is int ? tempVal.toDouble() : double.tryParse(tempVal.toString()) ?? 0.0);

      int weatherCode = data['weatherCode'] ?? -1;

      setState(() {
        _currentWeatherCode = weatherCode;
        temperature = "${tempDouble.toStringAsFixed(1)}°";
        weatherDesc = _mapWeatherCode(weatherCode);
        windSpeed = "${data['windSpeed'] ?? '-'} km/h";
        humidity = "${data['humidity'] ?? '-'}%";
        isLoading = false;
      });
    } catch (e) {
      logger.warning("Weather error: $e");
      setState(() {
        errorMessage = "Failed to load weather data";
        isLoading = false;
      });
    }
  }

  String _mapWeatherCode(int code) {
    switch (code) {
      case 1000:
        return "Clear";
      case 1001:
        return "Cloudy";
      case 1100:
        return "Mostly Clear";
      case 1101:
        return "Partly Cloudy";
      case 1102:
        return "Mostly Cloudy";
      case 4000:
        return "Drizzle";
      case 4200:
        return "Light Rain";
      case 4201:
        return "Heavy Rain";
      default:
        return "Unknown";
    }
  }

  String _getWeatherImageAsset(int code) {
    switch (code) {
      case 1000: // Clear
        return "assets/picture/sun.png";
      case 1001: // Cloudy
      case 1101: // Partly Cloudy
        return "assets/picture/cloudy.png";
      case 1102: // Mostly Cloudy
        return "assets/picture/mostly_cloudy.png";
      case 4000: // Drizzle
        return "assets/picture/drizzle.png";
      case 4200: // Light Rain
        return "assets/picture/light_rain.png";
      case 4201: // Heavy Rain
        return "assets/picture/thunder.png";
      default:
        return "assets/picture/sun.png"; // fallback
    }
  }

  Future<void> _navigateAndSelectLocation() async {
    logger.info("Navigasi ke SearchLocationPage");
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchLocationPage()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        city = result['name'] ?? city;
        latitude = result['lat'] ?? latitude;
        longitude = result['lon'] ?? longitude;
        isLoading = true;
      });
      await _loadWeather(latitude, longitude);
    }
  }

  void _toggleNotificationPanel() {
    setState(() {
      showNotificationPanel = !showNotificationPanel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 137, 196, 255),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      logger.info("Location text clicked");
                      _navigateAndSelectLocation();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              city,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const Icon(Icons.expand_more, color: Colors.white),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            logger.info("Notification icon tapped");
                            _toggleNotificationPanel();
                          },
                          child: const Icon(Icons.notifications_none, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Image.asset(
                      _getWeatherImageAsset(_currentWeatherCode),
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 1.5),
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 175, 214, 254),
                          Color.fromARGB(255, 175, 214, 254)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withAlpha((1.5 * 255).round()),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : errorMessage != null
                            ? Center(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              )
                            : Column(
                                children: [
                                  const Text(
                                    "Today",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    temperature,
                                    style: const TextStyle(
                                      fontSize: 72,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(2, 2),
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    weatherDesc,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _windHumidityWidget(
                                    windSpeed: windSpeed,
                                    windIcon: WeatherIcons.strong_wind,
                                    humidity: humidity,
                                    humidityIcon: WeatherIcons.humidity,
                                  ),
                                ],
                              ),
                  ),
                  const Spacer(),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4D4D7F),
                        elevation: 6,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        // Navigasi ke WeatherPage saat tombol ditekan
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WeatherPage()),
                        );
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Weather Details",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            if (showNotificationPanel)
              GestureDetector(
                onTap: _toggleNotificationPanel,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withAlpha((0.3 * 255).round()),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: 0.5,
                        widthFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, -3),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 50,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4D4D7F),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    "Your notification",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4D4D7F),
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          offset: Offset(2, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "New",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF4D4D7F),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: ListView(
                                      padding: EdgeInsets.zero,
                                      children: [
                                        NotificationTile(notification: newNotifications[0]),
                                        const SizedBox(height: 15),
                                        const Text(
                                          "Earlier",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF4D4D7F),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        NotificationTile(notification: earlierNotifications[0]),
                                        NotificationTile(notification: earlierNotifications[1]),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _windHumidityWidget({
    required String windSpeed,
    required IconData windIcon,
    required String humidity,
    required IconData humidityIcon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BoxedIcon(windIcon, size: 28, color: Colors.white),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Wind',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: ' | ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: windSpeed,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BoxedIcon(humidityIcon, size: 28, color: Colors.white),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Humidity',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: ' | ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: humidity,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class NotificationItem {
  final IconData icon;
  final String time;
  final String title;

  NotificationItem({
    required this.icon,
    required this.time,
    required this.title,
  });
}

class NotificationTile extends StatelessWidget {
  final NotificationItem notification;

  const NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoxedIcon(notification.icon, size: 28, color: const Color(0xFF4D4D7F)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.time,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4D4D7F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4D4D7F),
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.expand_more, color: Color(0xFF4D4D7F)),
      ],
    );
  }
}
