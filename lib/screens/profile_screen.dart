import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import '../services/api_service.dart'; // Import ApiService for backend integration

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key}); // No username and email parameters

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditMode = false;
  bool _isLoading = true;
  final TextEditingController _lastDonationDateController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _hasTattoo = false; // Initialized as false
  bool _isHIVPositive = false; // Initialized as false

  String _username = 'Unknown'; // Default username
  String _email = 'No email'; // Default email

  // Dropdown options
  final List<String> _bloodGroupOptions = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> _genderOptions = ['Male', 'Female', 'Others'];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      // Fetch username and email from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _username = prefs.getString('username') ?? 'Unknown';
        _email = prefs.getString('email') ?? 'No email';
      });

      // Fetch additional profile details from the backend
      final userId = prefs.getInt('userId'); // Assuming userId is stored in SharedPreferences
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final profileData = await ApiService.fetchProfile(userId);
      setState(() {
        _lastDonationDateController.text = profileData['last_donation_date'] ?? '';
        _bloodGroupController.text = profileData['blood_group'] ?? '';
        _genderController.text = profileData['gender'] ?? '';
        _ageController.text = profileData['age']?.toString() ?? '';
        _weightController.text = profileData['weight']?.toString() ?? '';
        _locationController.text = profileData['location'] ?? '';
        _hasTattoo = profileData['has_tattoo'] == 1; // Only update if backend provides a value
        _isHIVPositive = profileData['is_hiv_positive'] == 1; // Only update if backend provides a value
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch profile data: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId'); // Assuming userId is stored in SharedPreferences
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final profileData = {
        'userId': userId, // Include userId in the request body
        'lastDonationDate': _lastDonationDateController.text.isEmpty ? null : _lastDonationDateController.text,
        'bloodGroup': _bloodGroupController.text.isEmpty ? null : _bloodGroupController.text,
        'gender': _genderController.text.isEmpty ? null : _genderController.text,
        'age': _ageController.text.isEmpty ? null : int.tryParse(_ageController.text),
        'weight': _weightController.text.isEmpty ? null : double.tryParse(_weightController.text),
        'location': _locationController.text.isEmpty ? null : _locationController.text,
        'hasTattoo': _hasTattoo, // Send current value (false by default)
        'isHivPositive': _isHIVPositive, // Send current value (false by default)
      };

      await ApiService.updateProfile(profileData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.save : Icons.edit),
            onPressed: () async {
              if (_isEditMode) {
                await _updateProfileData();
              }
              setState(() => _isEditMode = !_isEditMode);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage('assets/profile_pic.png'), // Add a default profile picture
                    ),
                    if (_isEditMode)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.red),
                          onPressed: () {
                            // Add logic to upload a profile picture
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Username (Non-editable)
              _buildProfileField('Username', _username, false),
              const SizedBox(height: 10),

              // Email (Non-editable)
              _buildProfileField('Email', _email, false),
              const SizedBox(height: 20),

              // Last Donation Date
              _buildEditableField(
                'Last Donation Date',
                _lastDonationDateController,
                Icons.calendar_today,
                isDateField: true,
              ),
              const SizedBox(height: 10),

              // Blood Group Dropdown
              _buildDropdownField(
                'Blood Group',
                _bloodGroupController,
                _bloodGroupOptions,
                Icons.bloodtype,
              ),
              const SizedBox(height: 10),

              // Gender Dropdown
              _buildDropdownField(
                'Gender',
                _genderController,
                _genderOptions,
                Icons.transgender,
              ),
              const SizedBox(height: 10),

              // Age (Numeric Input)
              _buildEditableField(
                'Age',
                _ageController,
                Icons.cake,
                isNumeric: true,
              ),
              const SizedBox(height: 10),

              // Weight (Numeric Input)
              _buildEditableField(
                'Weight (in Kgs)',
                _weightController,
                Icons.monitor_weight,
                isNumeric: true,
              ),
              const SizedBox(height: 10),

              // Location
              _buildEditableField(
                'Location',
                _locationController,
                Icons.location_on,
              ),
              const SizedBox(height: 20),

              // Additional Details (Non-editable by default)
              const Text(
                'Additional Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Tattoo in Last 12 Months
              _buildAdditionalDetail(
                'Did you get a tattoo in the last 12 months?',
                _hasTattoo,
                    (value) {
                  setState(() {
                    _hasTattoo = value;
                  });
                },
              ),
              const SizedBox(height: 10),

              // HIV Positive Test
              _buildAdditionalDetail(
                'Have you ever tested HIV Positive?',
                _isHIVPositive,
                    (value) {
                  setState(() {
                    _isHIVPositive = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build non-editable profile fields
  Widget _buildProfileField(String label, String value, bool isEditable) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.person),
        border: const OutlineInputBorder(),
        filled: !isEditable,
        fillColor: Colors.grey.shade200,
      ),
      controller: TextEditingController(text: value),
      readOnly: !isEditable,
    );
  }

  // Helper method to build editable fields
  Widget _buildEditableField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool isDateField = false,
        bool isNumeric = false,
      }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      controller: controller,
      readOnly: !_isEditMode,
      onTap: isDateField
          ? () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          setState(() {
            controller.text =
            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
          });
        }
      }
          : null,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
    );
  }

  // Helper method to build dropdown fields
  Widget _buildDropdownField(
      String label,
      TextEditingController controller,
      List<String> options,
      IconData icon,
      ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      value: controller.text.isEmpty ? null : controller.text,
      items: options.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: _isEditMode
          ? (value) {
        setState(() {
          controller.text = value ?? '';
        });
      }
          : null,
    );
  }

  // Helper method to build additional details (toggleable in edit mode)
  Widget _buildAdditionalDetail(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Switch(
          value: value,
          onChanged: _isEditMode ? onChanged : null,
          activeColor: Colors.red,
        ),
      ],
    );
  }
}