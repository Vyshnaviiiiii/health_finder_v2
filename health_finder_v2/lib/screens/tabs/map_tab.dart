import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/services_provider.dart';
import '../../models/health_service.dart';
import '../../theme/app_theme.dart';
import '../service_detail_screen.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();
  HealthService? _selectedService;

  Color _markerColor(ServiceType type) {
    switch (type) {
      case ServiceType.bloodBank:
        return AppTheme.danger;
      case ServiceType.pharmacy:
        return AppTheme.accent;
      case ServiceType.hospital:
        return AppTheme.primaryDark;
      case ServiceType.laboratory:
        return AppTheme.warning;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();
    final services = context.watch<ServicesProvider>();

    final pos = location.currentPosition;
    final center = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : const LatLng(10.1632, 76.6413); // Kerala default

    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
              onTap: (_, __) => setState(() => _selectedService = null),
            ),
            children: [
              // OpenStreetMap tile layer — completely free
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.health_finder',
              ),

              // Your location marker
              if (pos != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location,
                          color: AppTheme.primary, size: 36),
                    ),
                  ],
                ),

              // Service markers
              MarkerLayer(
                markers: services.services.map((service) {
                  return Marker(
                    point: LatLng(service.latitude, service.longitude),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedService = service),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _markerColor(service.type),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(service.type.emoji,
                              style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // OSM attribution (required by OpenStreetMap license)
          Positioned(
            bottom: _selectedService != null ? 180 : 8,
            right: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10)),
            ),
          ),

          // Legend
          Positioned(
            top: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: ServiceType.values.map((type) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 7,
                            backgroundColor: _markerColor(type),
                          ),
                          const SizedBox(width: 6),
                          Text(type.label,
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Bottom card for selected service
          if (_selectedService != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(_selectedService!.type.emoji,
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedService!.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text(_selectedService!.address,
                                    style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _selectedService = null),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceDetailScreen(
                                  service: _selectedService!),
                            ),
                          ),
                          child: const Text('View Details'),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
