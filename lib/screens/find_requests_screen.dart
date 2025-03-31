
import 'package:flutter/material.dart';

class FindRequestsScreen extends StatefulWidget {
  const FindRequestsScreen({super.key});

  @override
  State<FindRequestsScreen> createState() => _FindRequestsScreenState();
}

class _FindRequestsScreenState extends State<FindRequestsScreen> {
  final List<Map<String, dynamic>> mockRequests = [
    {
      'patient': 'Anita Singh',
      'hospital': 'City Hospital',
      'bloodGroup': 'O-',
      'urgency': 'Critical',
      'location': '5 km away',
      'distanceKm': 5,
      'contact': '9123456789',
      'note': '2 units needed urgently',
    },
    {
      'patient': 'Rohan Das',
      'hospital': 'General Medical',
      'bloodGroup': 'AB+',
      'urgency': 'Medium',
      'location': '22 km away',
      'distanceKm': 22,
      'contact': '9988776655',
      'note': '1 unit required by tomorrow',
    },
  ];

  String? _selectedBloodGroup;
  String? _selectedDistance;
  final List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> distanceOptions = ['10', '20', '30', '35'];

  @override
  Widget build(BuildContext context) {
    final filteredRequests = mockRequests
        .where((req) {
      final matchBlood = _selectedBloodGroup == null || req['bloodGroup'] == _selectedBloodGroup;
      final matchDistance = _selectedDistance == null || req['distanceKm'] <= int.parse(_selectedDistance!);
      return matchBlood && matchDistance;
    })
        .toList()
      ..sort((a, b) => b['urgency'] == 'Critical' ? 1 : -1);

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
                        .map((d) => DropdownMenuItem(value: d, child: Text('Within $d km')))
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
            Expanded(
              child: ListView.builder(
                itemCount: filteredRequests.length,
                itemBuilder: (context, index) {
                  final request = filteredRequests[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade100,
                        child: Text(
                          request['bloodGroup'],
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text('${request['patient']} - ${request['urgency']}'),
                      subtitle: Text(
                          '${request['hospital']}\n${request['note']}\n${request['location']}'),
                      isThreeLine: true,
                      trailing: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Offering help to ${request['contact']}')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Help'),
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
