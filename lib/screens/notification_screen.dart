import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> mockNotifications = [
      {
        'title': 'Reminder: Complete Your Donation',
        'message': 'You responded to a request. Have you donated? Please update your status.',
        'time': '1 hour ago',
        'type': 'reminder'
      },
      {
        'title': 'Urgent: Blood Needed Nearby',
        'message': 'Someone in critical condition within 12 km needs B+ blood urgently.',
        'time': '2 hours ago',
        'type': 'alert'
      },
      {
        'title': 'Donation Successful',
        'message': 'Congrats on donating blood. Every drop counts — you’ve done a great job! ❤',
        'time': '4 month ago',
        'type': 'success'
      },
    ];

    Icon _getIcon(String type) {
      switch (type) {
        case 'reminder':
          return const Icon(Icons.notifications_active, color: Colors.orange);
        case 'alert':
          return const Icon(Icons.warning, color: Colors.red);
        case 'success':
          return const Icon(Icons.check_circle, color: Colors.green);
        default:
          return const Icon(Icons.info);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.red,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mockNotifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = mockNotifications[index];
          return ListTile(
            leading: _getIcon(notification['type']),
            title: Text(notification['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(notification['message']),
            trailing: Text(notification['time'], style: const TextStyle(color: Colors.grey)),
            tileColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          );
        },
      ),
    );
  }
}