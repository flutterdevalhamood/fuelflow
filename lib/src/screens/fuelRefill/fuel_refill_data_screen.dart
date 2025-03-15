import 'package:flutter/material.dart';

class FuelRefillDataScreen extends StatefulWidget {
  const FuelRefillDataScreen({super.key});

  @override
  State<FuelRefillDataScreen> createState() => _FuelRefillDataScreenState();
}

class _FuelRefillDataScreenState extends State<FuelRefillDataScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fuel entry')),
      body: Center(child: Text('Fuel Entry')),
    );
  }
}
