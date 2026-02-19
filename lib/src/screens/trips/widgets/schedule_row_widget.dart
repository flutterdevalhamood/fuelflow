import 'package:flutter/material.dart';

class ScheduleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const ScheduleRow({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          '$label  ',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8F9BB3),
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF3A3F55),
          ),
        ),
      ],
    );
  }
}
