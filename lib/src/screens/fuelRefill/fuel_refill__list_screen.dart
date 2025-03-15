import 'package:flutter/material.dart';
import 'package:sample/src/screens/fuelRefill/fuel_refill_data_screen.dart';

class FuelRefillListScreen extends StatefulWidget {
  const FuelRefillListScreen({super.key});

  @override
  State<FuelRefillListScreen> createState() => _FuelRefillListScreenState();
}

class _FuelRefillListScreenState extends State<FuelRefillListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fuel Refill')),
      body: Center(child: Text('Fuel refill')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FuelRefillDataScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
