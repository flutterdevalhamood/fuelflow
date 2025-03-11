import 'package:flutter/material.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    return Scaffold(
      appBar: AppBar(title: Text('Customer Details')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailCard(
                Icons.business,
                'Company Name',
                customer['Name'] ?? '',
              ),
              SizedBox(height: 16),
              _buildDetailCard(
                Icons.person,
                'Representative',
                customer['representative'] ?? '',
              ),
              SizedBox(height: 16),
              _buildDetailCard(
                Icons.phone_android,
                'Mobile',
                customer['mobile'] ?? '',
              ),
              SizedBox(height: 16),
              _buildDetailCard(Icons.email, 'Email', customer['email'] ?? ''),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Colors.blue.shade900),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
