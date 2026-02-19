import 'package:flutter/material.dart';
import 'package:sample/src/models/customer_site_model.dart';
import 'package:sample/src/models/trip_stop_model.dart';

class StopEntry {
  final String id;
  CustomerSite? site;
  final TextEditingController qtyCtrl;
  DateTime? arrivalTime;
  DateTime? completedTime;
  List<TripVehicle> availableVehicles;
  Set<int> selectedVehicleIds; // ← track selected vehicle IDs
  int? existingStopId;

  StopEntry({
    required this.id,
    this.site,
    String? qty,
    this.arrivalTime,
    this.completedTime,
    this.availableVehicles = const [],
    Set<int>? selectedVehicleIds, // ← optional initial selection
    this.existingStopId,
  }) : qtyCtrl = TextEditingController(text: qty ?? ''),
       selectedVehicleIds = selectedVehicleIds ?? {};

  void dispose() => qtyCtrl.dispose();

  // Toggle vehicle selection
  void toggleVehicle(int vehicleId) {
    if (selectedVehicleIds.contains(vehicleId)) {
      selectedVehicleIds.remove(vehicleId);
    } else {
      selectedVehicleIds.add(vehicleId);
    }
  }

  static String _fmt(DateTime dt) {
    final y = dt.year.toString();
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi:00';
  }

  Map<String, dynamic> toJson() => {
    'site_id': site!.id,
    'expected_quantity': int.tryParse(qtyCtrl.text.trim()) ?? 0,
    'expected_arrival_time': _fmt(arrivalTime!),
    'expected_completed_time': _fmt(completedTime!),
  };

  bool get isValid =>
      site != null &&
      qtyCtrl.text.trim().isNotEmpty &&
      int.tryParse(qtyCtrl.text.trim()) != null &&
      arrivalTime != null &&
      completedTime != null &&
      completedTime!.isAfter(arrivalTime!);
}
