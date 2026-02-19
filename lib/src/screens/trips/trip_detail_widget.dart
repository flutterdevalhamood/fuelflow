import 'package:flutter/material.dart';
import 'package:sample/src/models/trip_customer_model.dart';
import 'package:sample/src/screens/trips/widgets/detail_stat_widget.dart';
import 'package:sample/src/screens/trips/widgets/timeline_row_widget.dart';
import 'package:sample/src/util/status_helper.dart';

class TripDetailSheet extends StatelessWidget {
  final Trip trip;
  const TripDetailSheet({required this.trip});

  String _fmt(DateTime dt) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $h:$m';
  }

  Duration get _duration => trip.scheduledEnd.difference(trip.scheduledStart);

  @override
  Widget build(BuildContext context) {
    final statusColor = trip.status.statusColor;
    final days = _duration.inDays;
    final hours = _duration.inHours.remainder(24);

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder:
          (_, sc) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0D5E8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: sc,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ── Hero ─────────────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusColor.withOpacity(0.1),
                              statusColor.withOpacity(0.04),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                trip.status.statusIcon,
                                color: statusColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trip #${trip.id}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1F36),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: trip.status.statusBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    trip.status.statusLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Duration card ─────────────────────────────────────────
                      Row(
                        children: [
                          DetailStat(
                            label: 'Duration',
                            value: '$days days',
                            sub: '$hours hrs',
                            icon: Icons.timer_outlined,
                            color: const Color(0xFF3D7EFF),
                          ),
                          const SizedBox(width: 12),
                          DetailStat(
                            label: 'Customer',
                            value: trip.customer.name,
                            sub: 'ID: ${trip.customer.id}',
                            icon: Icons.business_outlined,
                            color: const Color(0xFF6D5EFF),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Timeline ──────────────────────────────────────────────
                      const Text(
                        'Schedule',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1F36),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TimelineRow(
                        label: 'Scheduled Start',
                        time: _fmt(trip.scheduledStart),
                        color: const Color(0xFF3D7EFF),
                        icon: Icons.play_circle_rounded,
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 19),
                        width: 1,
                        height: 20,
                        color: const Color(0xFFD0D5E8),
                      ),
                      TimelineRow(
                        label: 'Scheduled End',
                        time: _fmt(trip.scheduledEnd),
                        color: statusColor,
                        icon: Icons.stop_circle_rounded,
                      ),
                      const SizedBox(height: 20),

                      if (trip.notes != null) ...[
                        const Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1F36),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            trip.notes!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF3A3F55),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Close ──────────────────────────────────────────────────
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6FB),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                              'Close',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8F9BB3),
                              ),
                            ),
                          ),
                        ),
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
