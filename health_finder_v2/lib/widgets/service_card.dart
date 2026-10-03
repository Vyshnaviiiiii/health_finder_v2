import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/health_service.dart';
import '../theme/app_theme.dart';

class ServiceCard extends StatelessWidget {
  final HealthService service;
  final VoidCallback onTap;

  const ServiceCard({super.key, required this.service, required this.onTap});

  Color _typeColor(ServiceType type) {
    switch (type) {
      case ServiceType.clinic:
        return const Color(0xFFB5D5F5);
      case ServiceType.pharmacy:
        return const Color(0xFFB5E8C8);
      case ServiceType.bloodBank:
        return const Color(0xFFFFB5C8);
      case ServiceType.hospital:
        return const Color(0xFFD5B5F5);
      case ServiceType.laboratory:
        return const Color(0xFFFFE5B5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Emoji bubble
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _typeColor(service.type),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(service.type.emoji,
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(service.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppTheme.textDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: service.isOpen
                                  ? const Color(0xFFE8F8EE)
                                  : const Color(0xFFFFEEF2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              service.isOpen ? 'Open' : 'Closed',
                              style: TextStyle(
                                color: service.isOpen
                                    ? const Color(0xFF4CAF82)
                                    : AppTheme.danger,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(service.address,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: service.rating,
                            itemBuilder: (_, __) => const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFD080)),
                            itemSize: 14,
                          ),
                          const SizedBox(width: 4),
                          Text('(${service.reviewCount})',
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 12)),
                          const Spacer(),
                          if (service.distanceKm != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${service.distanceKm!.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                    color: AppTheme.primaryDark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
