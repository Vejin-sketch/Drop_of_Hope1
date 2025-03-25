import 'package:flutter/material.dart';

class BloodStockScreen extends StatelessWidget {
  const BloodStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Stock'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last Updated Time
            const Text(
              'Last Updated: 10 minutes ago',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),

            // Blood Stock Table
            Expanded(
              child: ListView(
                children: [
                  _buildBloodStockRow('A+', 85),
                  _buildBloodStockRow('A-', 45),
                  _buildBloodStockRow('B+', 60),
                  _buildBloodStockRow('B-', 30),
                  _buildBloodStockRow('O+', 90),
                  _buildBloodStockRow('O-', 25),
                  _buildBloodStockRow('AB+', 70),
                  _buildBloodStockRow('AB-', 20),
                ],
              ),
            ),

            // Request Blood Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to Request Blood Screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Request Blood'),
              ),
            ),

            const SizedBox(height: 10),

            // Donate Blood Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to Donate Blood Screen
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Donate Blood'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build a row for a blood group
  Widget _buildBloodStockRow(String bloodGroup, int stockLevel) {
    Color stockColor;
    if (stockLevel >= 70) {
      stockColor = Colors.green;
    } else if (stockLevel >= 30) {
      stockColor = Colors.orange;
    } else {
      stockColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: stockColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            bloodGroup,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: stockColor,
            ),
          ),
        ),
        title: Text('$stockLevel%'),
        subtitle: Text(
          stockLevel >= 70
              ? 'Sufficient Stock'
              : stockLevel >= 30
              ? 'Low Stock'
              : 'Critical Stock',
          style: TextStyle(
            color: stockColor,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}