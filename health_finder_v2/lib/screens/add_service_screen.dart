import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/health_service.dart';
import '../providers/auth_provider.dart';
import '../providers/services_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();

  ServiceType _selectedType = ServiceType.clinic;
  List<String> _selectedBloodGroups = [];
  bool _loading = false;
  double? _lat, _lng;

  final _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    final pos = context.read<LocationProvider>().currentPosition;
    if (pos != null) {
      _lat = pos.latitude;
      _lng = pos.longitude;
    }
  }

  Future<void> _useCurrentLocation() async {
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location captured!')));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please capture the location')));
      return;
    }

    final auth = context.read<AppAuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to add a service')));
      return;
    }

    setState(() => _loading = true);

    final service = HealthService(
      id: '',
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      type: _selectedType,
      latitude: _lat!,
      longitude: _lng!,
      phone: _phoneCtrl.text.trim(),
      openingHours: _hoursCtrl.text.trim().isEmpty ? null : _hoursCtrl.text.trim(),
      bloodGroupsAvailable: _selectedBloodGroups,
      submittedBy: auth.currentUser!.uid,
      createdAt: DateTime.now(),
    );

    final error = await context.read<ServicesProvider>().addService(service);

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service added successfully!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Health Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Service type
              const Text('Service Type',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ServiceType.values.map((type) {
                  final selected = _selectedType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Chip(
                      label: Text('${type.emoji} ${type.label}'),
                      backgroundColor:
                          selected ? AppTheme.primary : Colors.white,
                      labelStyle: TextStyle(
                          color:
                              selected ? Colors.white : AppTheme.textDark),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Name *'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration:
                    const InputDecoration(labelText: 'Address *'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'Phone Number *'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hoursCtrl,
                decoration: const InputDecoration(
                    labelText: 'Opening Hours (optional)',
                    hintText: 'e.g. Mon–Sat 9am–6pm'),
              ),

              // Blood groups (only for blood banks)
              if (_selectedType == ServiceType.bloodBank) ...[
                const SizedBox(height: 20),
                const Text('Available Blood Groups',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _bloodGroups.map((g) {
                    final selected = _selectedBloodGroups.contains(g);
                    return FilterChip(
                      label: Text(g),
                      selected: selected,
                      selectedColor: AppTheme.danger.withOpacity(0.2),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedBloodGroups.add(g);
                          } else {
                            _selectedBloodGroups.remove(g);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),

              // Location
              OutlinedButton.icon(
                onPressed: _useCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: Text(_lat != null
                    ? 'Location: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
                    : 'Use Current Location'),
              ),

              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Service',
                        style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
