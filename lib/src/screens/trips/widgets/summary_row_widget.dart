import 'package:flutter/material.dart';
import 'package:sample/src/models/trip_customer_model.dart';
import 'package:sample/src/screens/trips/widgets/stat_pill_widget.dart';

class SummaryRow extends StatelessWidget {
  final List<Trip> trips;
  const SummaryRow({required this.trips});

  @override
  Widget build(BuildContext context) {
    final completed = trips.where((t) => t.status == 'completed').length;
    final inProgress = trips.where((t) => t.status == 'in_progress').length;
    final pending = trips.where((t) => t.status == 'pending_acceptance').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          StatPill(
            label: 'Total',
            count: trips.length,
            color: const Color(0xFF3D7EFF),
          ),
          const SizedBox(width: 8),
          StatPill(
            label: 'Active',
            count: inProgress,
            color: const Color(0xFF3D7EFF).withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          StatPill(
            label: 'Pending',
            count: pending,
            color: const Color(0xFFFF9F43),
          ),
          const SizedBox(width: 8),
          StatPill(
            label: 'Done',
            count: completed,
            color: const Color(0xFF00C48C),
          ),
        ],
      ),
    );
  }
}
