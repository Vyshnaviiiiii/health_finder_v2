import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  double _searchRadius = 5.0; // km
  StreamSubscription<Position>? _positionStream;

  // Manual override location
  double? _manualLat;
  double? _manualLng;
  String? _manualLocationName;

  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get searchRadius => _searchRadius;
  String? get manualLocationName => _manualLocationName;

  // Returns the active location (manual or GPS)
  double? get activeLat => _manualLat ?? _currentPosition?.latitude;
  double? get activeLng => _manualLng ?? _currentPosition?.longitude;
  bool get isManualLocation => _manualLat != null;

  void setSearchRadius(double radius) {
    _searchRadius = radius;
    notifyListeners();
  }

  void setManualLocation(double lat, double lng, String name) {
    _manualLat = lat;
    _manualLng = lng;
    _manualLocationName = name;
    notifyListeners();
  }

  void clearManualLocation() {
    _manualLat = null;
    _manualLng = null;
    _manualLocationName = null;
    notifyListeners();
  }

  Future<void> fetchLocation() async {
    _isLoading = true;
    _error = null;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services disabled. Please enable GPS.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permissions denied.';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions permanently denied.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Start live location updates
      _startLiveUpdates();

    } catch (e) {
      _error = 'Failed to get location: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void _startLiveUpdates() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters
      ),
    ).listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
  }

  double? distanceTo(double lat, double lng) {
    final fromLat = activeLat;
    final fromLng = activeLng;
    if (fromLat == null || fromLng == null) return null;
    final distMeters = Geolocator.distanceBetween(
      fromLat, fromLng, lat, lng,
    );
    return distMeters / 1000;
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
