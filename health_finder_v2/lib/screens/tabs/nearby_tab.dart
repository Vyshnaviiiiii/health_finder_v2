import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/location_provider.dart';
import '../../models/health_service.dart';
import '../../theme/app_theme.dart';
import '../service_detail_screen.dart';
import '../add_service_screen.dart';
import '../location_settings_screen.dart';
import '../../widgets/service_card.dart';

class NearbyTab extends StatefulWidget {
  const NearbyTab({super.key});

  @override
  State<NearbyTab> createState() => _NearbyTabState();
}

class _NearbyTabState extends State<NearbyTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = context.watch<ServicesProvider>();
    final location = context.watch<LocationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Finder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Service',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddServiceScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Location bar
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LocationSettingsScreen())),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    location.isManualLocation
                        ? Icons.location_city
                        : Icons.my_location,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location.isManualLocation
                          ? '📍 ${location.manualLocationName}'
                          : location.currentPosition != null
                              ? '📍 Current Location (${location.searchRadius.toInt()} km radius)'
                              : '📍 Tap to set location',
                      style: const TextStyle(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w500,
                          fontSize: 13),
                    ),
                  ),
                  const Icon(Icons.tune,
                      color: AppTheme.primary, size: 18),
                ],
              ),
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: services.setSearchQuery,
              decoration: const InputDecoration(
                hintText: 'Search clinics, pharmacies...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: services.activeFilter == null,
                  onTap: () => services.setFilter(null),
                ),
                ...ServiceType.values.map((type) => _FilterChip(
                      label: '${type.emoji} ${type.label}',
                      selected: services.activeFilter == type,
                      onTap: () => services.setFilter(type),
                    )),
              ],
            ),
          ),

          // List
          Expanded(
            child: services.isLoading
                ? const Center(child: CircularProgressIndicator())
                : services.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 60, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            Text(services.error!,
                                style: const TextStyle(
                                    color: AppTheme.textMuted),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    : services.services.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off,
                                    size: 60, color: AppTheme.textMuted),
                                const SizedBox(height: 12),
                                const Text('No services found.',
                                    style: TextStyle(
                                        color: AppTheme.textMuted)),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const LocationSettingsScreen())),
                                  icon: const Icon(Icons.location_on),
                                  label: const Text('Change Location'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              final lat = location.activeLat;
                              final lng = location.activeLng;
                              if (lat != null && lng != null) {
                                await context
                                    .read<ServicesProvider>()
                                    .fetchNearbyServices(
                                        lat: lat, lng: lng);
                              }
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: services.services.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final service = services.services[i];
                                return ServiceCard(
                                  service: service,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ServiceDetailScreen(
                                          service: service),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected
                    ? AppTheme.primary
                    : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textDark,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
