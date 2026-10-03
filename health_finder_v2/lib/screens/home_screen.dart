import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/services_provider.dart';
import 'tabs/nearby_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/blood_donor_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _tabs = const [
    NearbyTab(),
    MapTab(),
    BloodDonorTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final locationProvider = context.read<LocationProvider>();
    await locationProvider.fetchLocation();
    if (!mounted) return;
    final pos = locationProvider.currentPosition;
    if (pos != null) {
      await context.read<ServicesProvider>().fetchNearbyServices(
            lat: pos.latitude,
            lng: pos.longitude,
          );
    } else {
      // Fallback to Firebase data if location not available
      await context.read<ServicesProvider>().fetchAllServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Nearby'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.bloodtype_outlined), label: 'Blood'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
