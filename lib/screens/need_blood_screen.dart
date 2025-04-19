import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropofhope/services/api_service.dart';

class NeedBloodScreen extends StatefulWidget {
  const NeedBloodScreen({super.key});

  @override
  State<NeedBloodScreen> createState() => _NeedBloodScreenState();
}

class _NeedBloodScreenState extends State<NeedBloodScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _requesterNameController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _requiredDateController = TextEditingController();
  final TextEditingController _additionalNotesController = TextEditingController();

  double? _latitude;
  double? _longitude;
  String? _selectedBloodGroup;
  String? _selectedUnitsRequired;
  bool _isCritical = false;
  bool _agreeToTerms = false;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> _unitsRequired = List.generate(9, (index) => (index + 1).toString());
  final String _locationIqKey = 'pk.daaa44b9e63dad7baae605abb7b32d56';

  Future<void> _fetchCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    }

    final Position position = await Geolocator.getCurrentPosition();
    _latitude = position.latitude;
    _longitude = position.longitude;

    await _getAddressFromCoordinates(_latitude!, _longitude!);
  }

  Future<void> _getAddressFromCoordinates(double lat, double lon) async {
    final url =
        'https://us1.locationiq.com/v1/reverse.php?key=$_locationIqKey&lat=$lat&lon=$lon&format=json';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _locationController.text = data['display_name'];
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() || !_agreeToTerms) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null || _latitude == null || _longitude == null) {
        throw Exception("Missing user ID or location.");
      }

      final data = {
        'userId': userId,
        'patientName': _requesterNameController.text.trim(),
        'bloodGroup': _selectedBloodGroup,
        'unitsRequired': int.parse(_selectedUnitsRequired ?? '1'),
        'contactNumber': _contactInfoController.text.trim(),
        'location': _locationController.text.trim(),
        'requiredDate': _requiredDateController.text.trim(),
        'hospitalName': _hospitalController.text.trim(),
        'hospitalAddress': '',
        'isCritical': _isCritical,
        'additionalNotes': _additionalNotesController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude
      };

      await ApiService.createBloodRequest(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Need Blood'), backgroundColor: Colors.red),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _requesterNameController,
                decoration: const InputDecoration(
                  labelText: 'Requester Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedBloodGroup,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                ),
                items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
                onChanged: (val) => setState(() => _selectedBloodGroup = val),
                validator: (val) => val == null ? 'Select blood group' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _contactInfoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty || !RegExp(r'^[0-9]{10}$').hasMatch(val)
                    ? 'Enter valid 10-digit number'
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _locationController,
                readOnly: false,
                decoration: InputDecoration(
                  labelText: 'Location (tap GPS icon to autofill)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.location_on),
                    onPressed: _fetchCurrentLocation,
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter or fetch your location' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _hospitalController,
                decoration: const InputDecoration(
                  labelText: 'Hospital / Blood Bank Name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter hospital name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _requiredDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Required Date',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    _requiredDateController.text =
                    "${picked.day}/${picked.month}/${picked.year}";
                  }
                },
                validator: (val) => val == null || val.isEmpty ? 'Select date' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedUnitsRequired,
                decoration: const InputDecoration(
                  labelText: 'Units Required',
                  border: OutlineInputBorder(),
                ),
                items: _unitsRequired.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (val) => setState(() => _selectedUnitsRequired = val),
                validator: (val) => val == null ? 'Select units' : null,
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Critical Urgency'),
                value: _isCritical,
                onChanged: (val) => setState(() => _isCritical = val),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _additionalNotesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (val) => val == null || val.isEmpty ? 'Add notes' : null,
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                title: const Text('I agree to the terms and privacy policy'),
                value: _agreeToTerms,
                onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}