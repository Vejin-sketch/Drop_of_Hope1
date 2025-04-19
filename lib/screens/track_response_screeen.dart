import 'package:flutter/material.dart';

class TrackResponseScreen extends StatefulWidget {
  const TrackResponseScreen({super.key});

  @override
  State<TrackResponseScreen> createState() => _TrackResponseScreenState();
}

class _TrackResponseScreenState extends State<TrackResponseScreen> {
  late Map<String, dynamic> _request;
  String status = 'pending';
  String cancelReason = '';
  bool showCancelField = false;

  @override
  void initState() {
    super.initState();
    _loadMockResponse();
  }

  void _loadMockResponse() {
    _request = {
      'patient_name': 'Sneha Rani',
      'blood_group': 'B+',
      'units_required': 3,
      'hospital_name': 'Apollo Hospital',
      'location': 'Chennai, India',
      'is_critical': 1
    };
  }

  void _markFulfilled() {
    setState(() => status = 'fulfilled');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Marked as fulfilled")),
    );
  }

  void _cancelResponse() {
    if (cancelReason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a reason for cancellation.")),
      );
      return;
    }
    setState(() => status = 'cancelled');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Response cancelled: $cancelReason")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final req = _request;
    final bool isCritical = req['is_critical'] == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Response"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Patient: ${req['patient_name']}", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildDetailRow("Blood Group", req['blood_group'] ?? "-"),
            _buildDetailRow("Units Needed", req['units_required']?.toString() ?? "-"),
            _buildDetailRow("Hospital", req['hospital_name'] ?? "Unknown"),
            _buildDetailRow("Location", req['location'] ?? "Not Provided"),
            _buildDetailRow("Critical", isCritical ? "Yes" : "No"),
            _buildDetailRow("Time Left", "~48 hrs"),

            const SizedBox(height: 20),
            Row(
              children: [
                const Text("Status: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(status.toUpperCase()),
                  backgroundColor: status == 'fulfilled'
                      ? Colors.green
                      : status == 'cancelled'
                      ? Colors.grey
                      : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (status == 'pending') ...[
              ElevatedButton(
                onPressed: _markFulfilled,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Mark as Fulfilled"),
              ),
              const SizedBox(height: 10),
              if (!showCancelField)
                ElevatedButton(
                  onPressed: () => setState(() => showCancelField = true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text("Cancel Response"),
                ),
              if (showCancelField) ...[
                TextField(
                  onChanged: (val) => cancelReason = val,
                  decoration: const InputDecoration(
                    labelText: "Reason for cancellation",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _cancelResponse,
                  child: const Text("Confirm Cancel"),
                )
              ]
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}