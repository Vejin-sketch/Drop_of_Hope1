import 'package:flutter/material.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final List<Map<String, dynamic>> _mockRequests = [
    {
      'id': 1,
      'patient_name': 'Ravi Kumar',
      'blood_group': 'A+',
      'units_required': 4,
      'fulfilled': false,
      'hospital': 'Apollo Hospital',
      'responders': [
        {'name': 'Deepika', 'contact': '9999999999', 'status': 'pending'},
        {'name': 'Brain', 'contact': '8888888888', 'status': 'fulfilled'},
      ],
    },
    {
      'id': 2,
      'patient_name': 'Amith Joshi',
      'blood_group': 'B-',
      'units_required': 2,
      'fulfilled': true,
      'hospital': 'SRM Hospital',
      'responders': [
        {'name': 'Charlie', 'contact': '7777777777', 'status': 'fulfilled'},
      ],
    },
  ];

  void _markAsFulfilled(int requestId) {
    setState(() {
      final req = _mockRequests.firstWhere((r) => r['id'] == requestId);
      req['fulfilled'] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Requests"), backgroundColor: Colors.red),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mockRequests.length,
        itemBuilder: (context, index) {
          final request = _mockRequests[index];
          final responders = request['responders'] as List<dynamic>;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text('${request['patient_name']} - ${request['blood_group']}'),
              subtitle: Text('${request['hospital']} • Units: ${request['units_required']}'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Responders:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...responders.map((res) => ListTile(
                        title: Text(res['name']),
                        subtitle: Text(res['contact']),
                        trailing: Chip(
                          label: Text(res['status'].toUpperCase()),
                          backgroundColor: res['status'] == 'fulfilled'
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                        ),
                      )),
                      const SizedBox(height: 10),
                      request['fulfilled']
                          ? const Text('Request Status: Fulfilled ✅')
                          : ElevatedButton(
                        onPressed: () => _markAsFulfilled(request['id']),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Mark as Fulfilled'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}