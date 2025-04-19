import 'package:flutter/material.dart';
import 'package:dropofhope/services/api_service.dart';
import 'package:dropofhope/services/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DonateBloodScreen extends StatefulWidget {
  const DonateBloodScreen({super.key});

  @override
  State<DonateBloodScreen> createState() => _DonateBloodScreenState();
}

class _DonateBloodScreenState extends State<DonateBloodScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _donorNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _lastDonationDateController = TextEditingController();
  String? _bloodGroup;

  bool _isLoading = true;
  bool _submitting = false;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final username = await SessionManager.getUsername();
    final userId = prefs.getInt('userId');

    if (userId != null) {
      try {
        final profile = await ApiService.fetchProfile(userId);

        setState(() {
          _donorNameController.text = username ?? '';
          _bloodGroup = profile['blood_group'];
          _lastDonationDateController.text = profile['last_donation_date'] ?? '';
          _locationController.text = profile['location'] ?? '';
        });
      } catch (e) {
        setState(() {
          _donorNameController.text = username ?? '';
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not found.")),
      );
      return;
    }

    final donationData = {
      'userId': userId,
      'donorName': _donorNameController.text.trim(),
      'bloodGroup': _bloodGroup,
      'contactNumber': _contactController.text.trim(),
      'location': _locationController.text.trim(),
      'lastDonationDate': _lastDonationDateController.text.trim(),
    };

    final missingProfileFields = <String, dynamic>{};
    if (_bloodGroup != null) missingProfileFields['bloodGroup'] = _bloodGroup;
    if (_lastDonationDateController.text.isNotEmpty)
      missingProfileFields['lastDonationDate'] = _lastDonationDateController.text;
    if (_locationController.text.isNotEmpty)
      missingProfileFields['location'] = _locationController.text;

    try {
      print('Donation submitted: $donationData');

      if (missingProfileFields.isNotEmpty) {
        missingProfileFields['userId'] = userId;
        await ApiService.updateProfile(missingProfileFields);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Donation submitted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: $e")),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donate Blood'),
        backgroundColor: Colors.red,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _donorNameController,
                decoration: const InputDecoration(
                  labelText: 'Donor Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _bloodGroup,
                items: _bloodGroups
                    .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                    .toList(),
                onChanged: (val) => setState(() => _bloodGroup = val),
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null ? 'Please select a blood group' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter contact number';
                  }
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                    return 'Enter a valid 10-digit number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _lastDonationDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Last Donation Date',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    _lastDonationDateController.text =
                    "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                  }
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit", style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}