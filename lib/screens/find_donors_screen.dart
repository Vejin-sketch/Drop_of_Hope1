
import 'package:flutter/material.dart';

class FindDonorsScreen extends StatefulWidget {
  const FindDonorsScreen({super.key});

  @override
  State<FindDonorsScreen> createState() => _FindDonorsScreenState();
}

class _FindDonorsScreenState extends State<FindDonorsScreen> {
  final List<Map<String, dynamic>> mockDonors = [
    {
      'name': 'Ravi Kumar',
      'bloodGroup': 'A+',
      'lastDonation': '12/03/2025',
      'distanceKm': 8,
      'note': 'Available this week',
      'contact': '9876543210',
    },
    {
      'name': 'Priya Sharma',
      'bloodGroup': 'B-',
      'lastDonation': '10/02/2025',
      'distanceKm': 22,
      'note': 'Can donate after 2 days',
      'contact': '9876543211',
    },
    {
      'name': 'Amit Joshi',
      'bloodGroup': 'A+',
      'lastDonation': '25/01/2025',
      'distanceKm': 35,
      'note': 'Call for availability',
      'contact': '9876543212',
    },
  ];

  String? _selectedBloodGroup;
  String? _selectedDistance;
  final List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> distanceOptions = ['10', '20', '30', '35'];

  @override
  Widget build(BuildContext context) {
    final filteredDonors = mockDonors.where((donor) {
      final matchBlood = _selectedBloodGroup == null || donor['bloodGroup'] == _selectedBloodGroup;
      final matchDistance = _selectedDistance == null || donor['distanceKm'] <= int.parse(_selectedDistance!);
      return matchBlood && matchDistance;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Donors'),
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
                itemCount: filteredDonors.length,
                itemBuilder: (context, index) {
                  final donor = filteredDonors[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade100,
                        child: Text(
                          donor['bloodGroup'],
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(donor['name']),
                      subtitle: Text(
                          'Last Donation: ${donor['lastDonation']}\nNote: ${donor['note']}\nDistance: ${donor['distanceKm']} km'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling ${donor['contact']}')),
                          );
                        },
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
