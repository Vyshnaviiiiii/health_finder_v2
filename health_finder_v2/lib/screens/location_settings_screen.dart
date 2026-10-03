import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/services_provider.dart';
import '../theme/app_theme.dart';

// Popular Indian cities
const _cities = [
  {'name': 'Kozhikode', 'lat': 11.2588, 'lng': 75.7804},
  {'name': 'Kochi', 'lat': 9.9312, 'lng': 76.2673},
  {'name': 'Thiruvananthapuram', 'lat': 8.5241, 'lng': 76.9366},
  {'name': 'Thrissur', 'lat': 10.5276, 'lng': 76.2144},
  {'name': 'Kannur', 'lat': 11.8745, 'lng': 75.3704},
  {'name': 'Mumbai', 'lat': 19.0760, 'lng': 72.8777},
  {'name': 'Delhi', 'lat': 28.6139, 'lng': 77.2090},
  {'name': 'Bangalore', 'lat': 12.9716, 'lng': 77.5946},
  {'name': 'Chennai', 'lat': 13.0827, 'lng': 80.2707},
  {'name': 'Hyderabad', 'lat': 17.3850, 'lng': 78.4867},
  {'name': 'Pune', 'lat': 18.5204, 'lng': 73.8567},
  {'name': 'Kolkata', 'lat': 22.5726, 'lng': 88.3639},
  {'name': 'Ahmedabad', 'lat': 23.0225, 'lng': 72.5714},
  {'name': 'Jaipur', 'lat': 26.9124, 'lng': 75.7873},
];

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filteredCities = List.from(_cities);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filterCities(String query) {
    setState(() {
      _filteredCities = _cities
          .where((c) =>
              (c['name'] as String).toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _selectCity(Map<String, dynamic> city) async {
    final location = context.read<LocationProvider>();
    final services = context.read<ServicesProvider>();

    location.setManualLocation(
      city['lat'] as double,
      city['lng'] as double,
      city['name'] as String,
    );

    await services.fetchNearbyServices(
      lat: city['lat'] as double,
      lng: city['lng'] as double,
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Showing services near ${city['name']}')),
    );
  }

  Future<void> _useMyLocation() async {
    final location = context.read<LocationProvider>();
    final services = context.read<ServicesProvider>();

    location.clearManualLocation();
    await location.fetchLocation();

    if (!mounted) return;
    final pos = location.currentPosition;
    if (pos != null) {
      await services.fetchNearbyServices(
        lat: pos.latitude,
        lng: pos.longitude,
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Using your current location')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Location Settings')),
      body: Column(
        children: [
          // Current location button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _useMyLocation,
              icon: const Icon(Icons.my_location),
              label: Text(location.isManualLocation
                  ? 'Switch back to My Location'
                  : '📍 Using My Current Location'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: location.isManualLocation
                    ? AppTheme.primary
                    : AppTheme.accent,
              ),
            ),
          ),

          // Search radius
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Search Radius',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('${location.searchRadius.toInt()} km',
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: location.searchRadius,
                  min: 2,
                  max: 50,
                  divisions: 10,
                  activeColor: AppTheme.primary,
                  onChanged: (val) => location.setSearchRadius(val),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('2 km', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    Text('50 km', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // City search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filterCities,
              decoration: const InputDecoration(
                hintText: 'Search city...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Popular Cities',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.textMuted)),
            ),
          ),

          // City list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredCities.length,
              itemBuilder: (context, i) {
                final city = _filteredCities[i];
                final isSelected =
                    location.manualLocationName == city['name'];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? AppTheme.primary
                        : AppTheme.primary.withOpacity(0.1),
                    child: Text(
                      (city['name'] as String)[0],
                      style: TextStyle(
                          color:
                              isSelected ? Colors.white : AppTheme.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(city['name'] as String,
                      style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: AppTheme.primary)
                      : const Icon(Icons.chevron_right,
                          color: AppTheme.textMuted),
                  onTap: () => _selectCity(city),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
