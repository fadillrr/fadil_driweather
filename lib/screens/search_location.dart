import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class SearchLocationPage extends StatefulWidget {
  const SearchLocationPage({super.key});

  @override
  State<SearchLocationPage> createState() => _SearchLocationPageState();
}

class _SearchLocationPageState extends State<SearchLocationPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _pickedLocation = LatLng(-7.0051, 110.4381); // default Surakarta
  String _locationName = "Surakarta";

  final List<Map<String, dynamic>> _cities = [
    {'name': 'Jakarta', 'lat': -6.2088, 'lon': 106.8456},
    {'name': 'Surabaya', 'lat': -7.2575, 'lon': 112.7521},
    {'name': 'Bandung', 'lat': -6.9175, 'lon': 107.6191},
    {'name': 'Medan', 'lat': 3.5952, 'lon': 98.6722},
    {'name': 'Semarang', 'lat': -7.0051, 'lon': 110.4381},
    {'name': 'Yogyakarta', 'lat': -7.7956, 'lon': 110.3695},
    {'name': 'Makassar', 'lat': -5.1477, 'lon': 119.4327},
    {'name': 'Palembang', 'lat': -2.9909, 'lon': 104.7566},
    {'name': 'Balikpapan', 'lat': -1.2674, 'lon': 116.8286},
    {'name': 'Pontianak', 'lat': -0.0251, 'lon': 109.3333},
    {'name': 'Banjarmasin', 'lat': -3.3273, 'lon': 114.6065},
    {'name': 'Malang', 'lat': -7.9839, 'lon': 112.6214},
    {'name': 'Bandar Lampung', 'lat': -5.4294, 'lon': 105.2611},
    {'name': 'Padang', 'lat': -0.9471, 'lon': 100.4172},
    {'name': 'Manado', 'lat': 1.4746, 'lon': 124.8426},
    {'name': 'Samarinda', 'lat': -0.5025, 'lon': 117.1537},
    {'name': 'Kupang', 'lat': -10.1783, 'lon': 123.6044},
  ];

  List<Map<String, dynamic>> _searchResults = [];

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied')));
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    if (!mounted) return;
    setState(() {
      _pickedLocation = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_pickedLocation, 13);

    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

    if (!mounted) return;
    setState(() {
      _locationName = '${placemarks.first.locality ?? ''}, ${placemarks.first.country ?? ''}';
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = _cities
            .where((city) => city['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectCity(Map<String, dynamic> city) {
    Navigator.pop(context, {
      'name': city['name'],
      'lat': city['lat'],
      'lon': city['lon'],
    });
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _pickedLocation = latlng;
    });
    _updateLocationName(latlng);
  }

  Future<void> _updateLocationName(LatLng latlng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latlng.latitude, latlng.longitude).timeout(
            const Duration(seconds: 5),
            onTimeout: () => [],
          );
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        setState(() {
          _locationName = '${placemarks.first.locality ?? ''}, ${placemarks.first.country ?? ''}';
        });
      } else {
        setState(() {
          _locationName = 'Unknown Location';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationName = 'Error getting location';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search location',
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  ),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Column(
        children: [
          if (_searchResults.isNotEmpty)
            Material(
              elevation: 4,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final city = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.location_city),
                    title: Text(city['name']),
                    onTap: () => _selectCity(city),
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent search',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _pickedLocation,
                zoom: 13,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.fadil_driweather',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40,
                      height: 40,
                      point: _pickedLocation,
                      builder: (context) => const Icon(
                        Icons.location_pin,
                        size: 40,
                        color: Colors.red,
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.my_location),
                    label: const Text("Current Location"),
                    onPressed: _getCurrentLocation,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Selected: $_locationName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
