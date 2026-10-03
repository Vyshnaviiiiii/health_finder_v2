import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/services_provider.dart';
import '../../models/health_service.dart';
import '../../theme/app_theme.dart';
import '../service_detail_screen.dart';

class BloodDonorTab extends StatefulWidget {
  const BloodDonorTab({super.key});

  @override
  State<BloodDonorTab> createState() => _BloodDonorTabState();
}

class _BloodDonorTabState extends State<BloodDonorTab> {
  String? _selectedGroup;

  final _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  Widget build(BuildContext context) {
    final services = context.watch<ServicesProvider>();
    final bloodBanks = services.services
        .where((s) => s.type == ServiceType.bloodBank)
        .where((s) =>
            _selectedGroup == null ||
            s.bloodGroupsAvailable.contains(_selectedGroup))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Blood Banks')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Filter by Blood Group',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _BloodChip(
                  label: 'All',
                  selected: _selectedGroup == null,
                  onTap: () => setState(() => _selectedGroup = null),
                ),
                ..._bloodGroups.map((g) => _BloodChip(
                      label: g,
                      selected: _selectedGroup == g,
                      onTap: () =>
                          setState(() => _selectedGroup = g),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: bloodBanks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bloodtype_outlined,
                            size: 60, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          _selectedGroup != null
                              ? 'No blood banks with $_selectedGroup nearby'
                              : 'No blood banks found nearby',
                          style:
                              const TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: bloodBanks.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final bank = bloodBanks[i];
                      return Card(
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bloodtype,
                                color: AppTheme.danger),
                          ),
                          title: Text(bank.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(bank.address,
                                  style: const TextStyle(fontSize: 12)),
                              if (bank.bloodGroupsAvailable.isNotEmpty)
                                Wrap(
                                  spacing: 4,
                                  children: bank.bloodGroupsAvailable
                                      .map((g) => Chip(
                                            label: Text(g,
                                                style: const TextStyle(
                                                    fontSize: 11)),
                                            backgroundColor: AppTheme
                                                .danger
                                                .withOpacity(0.1),
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ))
                                      .toList(),
                                ),
                            ],
                          ),
                          trailing: bank.distanceKm != null
                              ? Text(
                                  '${bank.distanceKm!.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold))
                              : null,
                          isThreeLine: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ServiceDetailScreen(service: bank)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BloodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BloodChip(
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
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.danger : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppTheme.danger : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textDark,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
