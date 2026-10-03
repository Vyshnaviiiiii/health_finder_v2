import 'package:cloud_firestore/cloud_firestore.dart';

enum ServiceType { clinic, pharmacy, bloodBank, hospital, laboratory }

extension ServiceTypeExt on ServiceType {
  String get label {
    switch (this) {
      case ServiceType.clinic:
        return 'Clinic';
      case ServiceType.pharmacy:
        return 'Pharmacy';
      case ServiceType.bloodBank:
        return 'Blood Bank';
      case ServiceType.hospital:
        return 'Hospital';
      case ServiceType.laboratory:
        return 'Laboratory';
    }
  }

  String get emoji {
    switch (this) {
      case ServiceType.clinic:
        return '🏥';
      case ServiceType.pharmacy:
        return '💊';
      case ServiceType.bloodBank:
        return '🩸';
      case ServiceType.hospital:
        return '🏨';
      case ServiceType.laboratory:
        return '🔬';
    }
  }
}

class HealthService {
  final String id;
  final String name;
  final String address;
  final ServiceType type;
  final double latitude;
  final double longitude;
  final String phone;
  final String? website;
  final double rating;
  final int reviewCount;
  final bool isOpen;
  final String? openingHours;
  final List<String> bloodGroupsAvailable; // For blood banks
  final String submittedBy;
  final DateTime createdAt;
  double? distanceKm;

  HealthService({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.website,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isOpen = true,
    this.openingHours,
    this.bloodGroupsAvailable = const [],
    required this.submittedBy,
    required this.createdAt,
    this.distanceKm,
  });

  factory HealthService.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HealthService(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      type: ServiceType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ServiceType.clinic,
      ),
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      phone: data['phone'] ?? '',
      website: data['website'],
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] ?? 0,
      isOpen: data['isOpen'] ?? true,
      openingHours: data['openingHours'],
      bloodGroupsAvailable:
          List<String>.from(data['bloodGroupsAvailable'] ?? []),
      submittedBy: data['submittedBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'type': type.name,
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone,
        'website': website,
        'rating': rating,
        'reviewCount': reviewCount,
        'isOpen': isOpen,
        'openingHours': openingHours,
        'bloodGroupsAvailable': bloodGroupsAvailable,
        'submittedBy': submittedBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
