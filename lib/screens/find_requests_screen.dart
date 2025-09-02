import 'package:flutter/material.dart';
import 'package:dropofhope/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropofhope/screens/track_response_screeen.dart';
import 'package:share_plus/share_plus.dart';

class FindRequestsScreen extends StatefulWidget {
  const FindRequestsScreen({super.key});

  @override
  State<FindRequestsScreen> createState() => _FindRequestsScreenState();
}

class _FindRequestsScreenState extends State<FindRequestsScreen> {
  List<dynamic> _requests = [];
  String? _selectedBloodGroup;
  String? _selectedDistance;
  bool _isLoading = true;

  final List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> distanceOptions = ['10', '20', '30', '35'];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final donorId = prefs.getInt('userId');

      if (donorId != null) {
        final matches = await ApiService.getMatchesForDonor(donorId);
        setState(() => _requests = matches);
      } else {
        throw Exception("Donor ID not found");
      }
    } catch (e) {
      print("Error loading matches: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load matches")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ Share function
  void shareBloodRequest(Map<String, dynamic> request) {
    final String patientName = request['patient_name'];
    final String units = request['units_required'].toString();
    final String bloodGroup = request['blood_group'];
    final String hospital = request['hospital_name'] ?? 'Unknown Hospital';
    final String notes = request['additional_notes'] ?? '';
    final String location = request['location'] ?? 'Location not specified';
    final String distance = "${request['distance'].toStringAsFixed(1)} km";
    final double lat = request['latitude'];
    final double lon = request['longitude'];

    final String mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';

    final String message = '''
🩸 Urgent Blood Request 🩸

$patientName needs $units unit(s) of $bloodGroup blood.

🏥 Hospital: $hospital
📍 Location: $location
📋 Notes: $notes
📏 Distance: $distance
🌐 Map: $mapsUrl

Kindly help or share this message. 🙏
(Drop of Hope App)
''';

    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _requests
        .where((req) {
      final matchBlood = _selectedBloodGroup == null || req['blood_group'] == _selectedBloodGroup;
      final distanceValue = double.tryParse(req['distance'].toString()) ?? 0.0;
      final matchDistance = _selectedDistance == null || distanceValue <= double.parse(_selectedDistance!);
      return matchBlood && matchDistance;
    })
        .toList()
      ..sort((a, b) => b['is_critical'] == 1 ? 1 : -1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Requests'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedBloodGroup,
                    items: bloodGroups
                        .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedBloodGroup = val),
                    decoration: const InputDecoration(labelText: 'Blood Group'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDistance,
                    items: distanceOptions
                        .map((d) => DropdownMenuItem(value: d, child: Text("Within $d km")))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedDistance = val),
                    decoration: const InputDecoration(labelText: 'Distance'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedBloodGroup = null;
                      _selectedDistance = null;
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
              child: _requests.isEmpty
                  ? const Text("No matching requests found.")
                  : ListView.builder(
                itemCount: filteredRequests.length,
                itemBuilder: (context, index) {
                  final request = filteredRequests[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade100,
                        child: Text(
                          request['blood_group'],
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        '${request['patient_name']} - ${request['is_critical'] == 1 ? 'Critical' : 'Normal'}',
                      ),
                      subtitle: Text(
                        '${request['hospital_name'] ?? 'Unknown Hospital'}\n'
                            '${request['additional_notes'] ?? ''}\n'
                            'Distance: ${request['distance'].toStringAsFixed(1)} km',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.grey),
                            onPressed: () => shareBloodRequest(request),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Confirm Help"),
                                  content: const Text("Do you want to offer help for this request?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text("Yes, Help"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                try {
                                  final prefs = await SharedPreferences.getInstance();
                                  final donorId = prefs.getInt('userId');
                                  final responseId = await ApiService.logHelpResponse(donorId!, request['id'], request);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TrackResponseScreen(),
                                    ),
                                  );
                                } catch (e) {
                                  if (e.toString().contains("already responded")) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TrackResponseScreen(),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Error: $e")),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Help'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
