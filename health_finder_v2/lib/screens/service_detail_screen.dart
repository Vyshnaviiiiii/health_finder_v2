import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/health_service.dart';
import '../providers/auth_provider.dart';
import '../providers/services_provider.dart';
import '../theme/app_theme.dart';

class ServiceDetailScreen extends StatelessWidget {
  final HealthService service;

  const ServiceDetailScreen({super.key, required this.service});

  void _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openMaps(double lat, double lng, String name) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _showReviewDialog(BuildContext context) async {
    double rating = 3;
    final commentCtrl = TextEditingController();
    final auth = context.read<AppAuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to leave a review')));
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Write a Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingBar.builder(
              initialRating: 3,
              minRating: 1,
              itemCount: 5,
              itemBuilder: (_, __) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (r) => rating = r,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Share your experience...'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await context
                  .read<ServicesProvider>()
                  .submitReview(
                    serviceId: service.id,
                    rating: rating,
                    comment: commentCtrl.text,
                    userId: auth.currentUser!.uid,
                  );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      error ?? 'Review submitted! Thank you.')));
            },
            child: const Text('Submit'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(service.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              color: AppTheme.primary.withOpacity(0.1),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(service.type.emoji,
                      style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 8),
                  Text(service.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(service.type.label),
                    backgroundColor: AppTheme.primary.withOpacity(0.15),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: service.rating,
                        itemBuilder: (_, __) =>
                            const Icon(Icons.star, color: Colors.amber),
                        itemSize: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                          '${service.rating.toStringAsFixed(1)} (${service.reviewCount} reviews)',
                          style: const TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Info tiles
                  _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: service.address),
                  const SizedBox(height: 12),
                  _InfoRow(
                      icon: Icons.phone_outlined, text: service.phone),
                  if (service.openingHours != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                        icon: Icons.access_time,
                        text: service.openingHours!),
                  ],
                  if (service.distanceKm != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                        icon: Icons.directions_walk,
                        text:
                            '${service.distanceKm!.toStringAsFixed(1)} km away'),
                  ],

                  // Blood groups
                  if (service.bloodGroupsAvailable.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Available Blood Groups',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: service.bloodGroupsAvailable
                          .map((g) => Chip(
                                label: Text(g,
                                    style: const TextStyle(
                                        color: AppTheme.danger,
                                        fontWeight: FontWeight.bold)),
                                backgroundColor:
                                    AppTheme.danger.withOpacity(0.1),
                              ))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _call(service.phone),
                          icon: const Icon(Icons.phone),
                          label: const Text('Call'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openMaps(
                              service.latitude,
                              service.longitude,
                              service.name),
                          icon: const Icon(Icons.directions),
                          label: const Text('Directions'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showReviewDialog(context),
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Write a Review'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 15))),
      ],
    );
  }
}
