import 'package:flutter/material.dart';

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
  final TextEditingController _requiredDateController = TextEditingController();
  final TextEditingController _additionalNotesController = TextEditingController();
  String? _selectedBloodGroup;
  String? _selectedUnitsRequired;
  bool _isCritical = false; // Default urgency level
  bool _agreeToTerms = false; // Checkbox state

  // List of blood groups
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  // List of units required (1-9)
  final List<String> _unitsRequired = List.generate(9, (index) => (index + 1).toString());

  // Validation for Requester Name
  String? _validateRequesterName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the requester name';
    }
    // Check for numbers
    if (value.contains(RegExp(r'[0-9]'))) {
      return 'Numbers are not allowed in the name';
    }
    // Check for special characters
    if (value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Special characters are not allowed in the name';
    }
    // Check if the first letter of each word is capitalized
    if (!value.split(' ').every((word) => word[0] == word[0].toUpperCase())) {
      return 'First letter of each word should be capitalized';
    }
    return null;
  }

  // Validation for Contact Info
  String? _validateContactInfo(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter contact info';
    }
    // Check if exactly 10 digits
    if (value.length != 10) {
      return 'Contact info must be exactly 10 digits';
    }
    // Check if only numbers are entered
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Only numbers are allowed';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Need Blood'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Requester Name Field
              TextFormField(
                controller: _requesterNameController,
                decoration: const InputDecoration(
                  labelText: 'Requester Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: _validateRequesterName,
              ),
              const SizedBox(height: 20),

              // Contact Info Field
              TextFormField(
                controller: _contactInfoController,
                decoration: const InputDecoration(
                  labelText: 'Contact Info',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: _validateContactInfo,
              ),
              const SizedBox(height: 20),

              // Location Field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Required Date Field
              TextFormField(
                controller: _requiredDateController,
                decoration: const InputDecoration(
                  labelText: 'Required Date',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _requiredDateController.text =
                      "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select the required date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Units Required Dropdown
              DropdownButtonFormField<String>(
                value: _selectedUnitsRequired,
                decoration: const InputDecoration(
                  labelText: 'Units Required',
                  prefixIcon: Icon(Icons.bloodtype),
                  border: OutlineInputBorder(),
                ),
                items: _unitsRequired.map((String unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUnitsRequired = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select the units required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Urgency Level Toggle
              SwitchListTile(
                title: const Text('Critical Urgency'),
                subtitle: const Text('Toggle if the case is critical'),
                value: _isCritical,
                onChanged: (value) {
                  setState(() {
                    _isCritical = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Additional Notes Field
              TextFormField(
                controller: _additionalNotesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide additional notes';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Terms and Privacy Policy Checkbox
              CheckboxListTile(
                title: const Text('I have read and agreed to the terms and privacy policy'),
                value: _agreeToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreeToTerms = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _agreeToTerms) {
                      // Form is valid and terms are agreed, proceed with submission
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request submitted successfully!'),
                        ),
                      );
                      // You can add logic here to send data to a server or database
                    } else if (!_agreeToTerms) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please agree to the terms and privacy policy'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}