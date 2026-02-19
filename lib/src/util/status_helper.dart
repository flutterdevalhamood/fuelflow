import 'package:flutter/material.dart';

extension TripStatusX on String {
  Color get statusColor {
    switch (this) {
      case 'completed':
        return const Color(0xFF00C48C);
      case 'in_progress':
        return const Color(0xFF3D7EFF);
      case 'pending_acceptance':
        return const Color(0xFFFF9F43);
      case 'cancelled':
        return const Color(0xFFFF5C5C);
      default:
        return const Color(0xFF8F9BB3);
    }
  }

  Color get statusBg {
    switch (this) {
      case 'completed':
        return const Color(0xFF00C48C).withOpacity(0.12);
      case 'in_progress':
        return const Color(0xFF3D7EFF).withOpacity(0.12);
      case 'pending_acceptance':
        return const Color(0xFFFF9F43).withOpacity(0.12);
      case 'cancelled':
        return const Color(0xFFFF5C5C).withOpacity(0.12);
      default:
        return const Color(0xFF8F9BB3).withOpacity(0.12);
    }
  }

  String get statusLabel {
    switch (this) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'pending_acceptance':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      default:
        return replaceAll('_', ' ').toUpperCase();
    }
  }

  IconData get statusIcon {
    switch (this) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'in_progress':
        return Icons.directions_car_rounded;
      case 'pending_acceptance':
        return Icons.schedule_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }
}
