import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_service.dart';

class ServicesProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<HealthService> _services = [];
  bool _isLoading = false;
  String? _error;
  ServiceType? _activeFilter;
  String _searchQuery = '';

  List<HealthService> get services {
    var result = _services;
    if (_activeFilter != null) {
      result = result.where((s) => s.type == _activeFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((s) =>
              s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.address.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return result;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  ServiceType? get activeFilter => _activeFilter;

  void setFilter(ServiceType? type) {
    _activeFilter = type;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Map OSM amenity tags to our ServiceType
  ServiceType? _osmAmenityToType(String amenity) {
    switch (amenity) {
      case 'clinic':
        return ServiceType.clinic;
      case 'pharmacy':
        return ServiceType.pharmacy;
      case 'blood_bank':
        return ServiceType.bloodBank;
      case 'hospital':
        return ServiceType.hospital;
      case 'doctors':
        return ServiceType.clinic;
      case 'laboratory':
      case 'diagnostics':
        return ServiceType.laboratory;
      default:
        return null;
    }
  }

  Future<void> fetchNearbyServices({
    required double lat,
    required double lng,
    double radiusMeters = 5000,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Overpass API query - fetches health facilities from OpenStreetMap
      final query = '''
[out:json][timeout:25];
(
  node["amenity"~"clinic|pharmacy|blood_bank|hospital|doctors|laboratory"](around:$radiusMeters,$lat,$lng);
  way["amenity"~"clinic|pharmacy|blood_bank|hospital|doctors|laboratory"](around:$radiusMeters,$lat,$lng);
);
out center;
''';

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;

        List<HealthService> osmServices = [];

        for (final element in elements) {
          final tags = element['tags'] as Map<String, dynamic>? ?? {};
          final amenity = tags['amenity'] as String? ?? '';
          final type = _osmAmenityToType(amenity);
          if (type == null) continue;

          // Get coordinates
          double? eLat, eLng;
          if (element['type'] == 'node') {
            eLat = (element['lat'] as num).toDouble();
            eLng = (element['lon'] as num).toDouble();
          } else if (element['center'] != null) {
            eLat = (element['center']['lat'] as num).toDouble();
            eLng = (element['center']['lon'] as num).toDouble();
          }
          if (eLat == null || eLng == null) continue;

          // Calculate distance
          final dLat = eLat - lat;
          final dLng = eLng - lng;
          final distKm = ((dLat * dLat + dLng * dLng) * 111.0 * 111.0) / 111.0;

          final name = tags['name'] ??
              tags['name:en'] ??
              tags['brand'] ??
              _typeToDefaultName(type);

          final address = _buildAddress(tags);
          final phone = tags['phone'] ??
              tags['contact:phone'] ??
              tags['contact:mobile'] ??
              '';

          osmServices.add(HealthService(
            id: '${element['type']}_${element['id']}',
            name: name,
            address: address,
            type: type,
            latitude: eLat,
            longitude: eLng,
            phone: phone,
            openingHours: tags['opening_hours'],
            bloodGroupsAvailable: const [],
            submittedBy: 'openstreetmap',
            createdAt: DateTime.now(),
            distanceKm: distKm,
            rating: 0,
            reviewCount: 0,
            isOpen: true,
          ));
        }

        // Sort by distance
        osmServices.sort((a, b) =>
            (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));

        _services = osmServices;

        if (_services.isEmpty) {
          _error = 'No health services found nearby. Try increasing the search radius.';
        }
      } else {
        _error = 'Failed to fetch data. Please try again.';
      }
    } catch (e) {
      _error = 'Network error. Please check your connection.';
    }

    _isLoading = false;
    notifyListeners();
  }

  String _typeToDefaultName(ServiceType type) {
    switch (type) {
      case ServiceType.clinic:
        return 'Medical Clinic';
      case ServiceType.pharmacy:
        return 'Pharmacy';
      case ServiceType.bloodBank:
        return 'Blood Bank';
      case ServiceType.hospital:
        return 'Hospital';
      case ServiceType.laboratory:
        return 'Diagnostic Lab';
    }
  }

  String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    if (tags['addr:housenumber'] != null) parts.add(tags['addr:housenumber']);
    if (tags['addr:street'] != null) parts.add(tags['addr:street']);
    if (tags['addr:suburb'] != null) parts.add(tags['addr:suburb']);
    if (tags['addr:city'] != null) parts.add(tags['addr:city']);
    if (tags['addr:state'] != null) parts.add(tags['addr:state']);
    if (parts.isEmpty && tags['addr:full'] != null) return tags['addr:full'];
    return parts.isEmpty ? 'Address not available' : parts.join(', ');
  }

  // Keep Firestore for user-submitted services
  Future<void> fetchAllServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snap = await _db
          .collection('health_services')
          .orderBy('createdAt', descending: true)
          .get();
      _services = snap.docs.map((doc) => HealthService.fromFirestore(doc)).toList();
    } catch (e) {
      _error = 'Failed to fetch services: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> addService(HealthService service) async {
    try {
      await _db.collection('health_services').add(service.toMap());
      return null;
    } catch (e) {
      return 'Failed to add service: $e';
    }
  }

  Future<String?> submitReview({
    required String serviceId,
    required double rating,
    required String comment,
    required String userId,
  }) async {
    try {
      final ref = _db.collection('health_services').doc(serviceId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data()!;
        final oldRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        final count = (data['reviewCount'] as num?)?.toInt() ?? 0;
        final newCount = count + 1;
        final newRating = ((oldRating * count) + rating) / newCount;
        tx.update(ref, {'rating': newRating, 'reviewCount': newCount});
        tx.set(ref.collection('reviews').doc(), {
          'rating': rating,
          'comment': comment,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      return null;
    } catch (e) {
      return 'Failed to submit review: $e';
    }
  }
}
