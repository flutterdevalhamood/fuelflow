import 'package:flutter/material.dart';
import 'package:sample/src/models/trip_customer_model.dart';
import 'package:sample/src/providers/trip_assignment_controller.dart';
import 'package:sample/src/screens/trips/widgets/action_btn_widget.dart';
import 'package:sample/src/screens/trips/widgets/schedule_row_widget.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/status_helper.dart';

class TripCard extends StatefulWidget {
  final Trip trip;
  final int index;
  final TripController controller;
  final VoidCallback onView;
  final VoidCallback onAssign;
  final VoidCallback onDelete;

  const TripCard({
    super.key,
    required this.trip,
    required this.index,
    required this.controller,
    required this.onView,
    required this.onAssign,
    required this.onDelete,
  });

  @override
  State<TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<TripCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeIn = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  String _fmt(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final statusColor = trip.status.statusColor;

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: GestureDetector(
          onTap: widget.onView,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Card Top ─────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.04),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    border: Border(
                      left: BorderSide(color: statusColor, width: 3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          trip.status.statusIcon,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Trip #${trip.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Color(0xFF1A1F36),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: trip.status.statusBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    trip.status.statusLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              trip.customer.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8F9BB3),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: const Color(0xFFD0D5E8),
                        size: 22,
                      ),
                    ],
                  ),
                ),

                // ── Schedule Info ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Column(
                    children: [
                      ScheduleRow(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Start',
                        time: _fmt(trip.scheduledStart),
                        color: const Color(0xFF3D7EFF),
                      ),
                      const SizedBox(height: 6),
                      ScheduleRow(
                        icon: Icons.stop_circle_outlined,
                        label: 'End',
                        time: _fmt(trip.scheduledEnd),
                        color: statusColor,
                      ),
                    ],
                  ),
                ),

                // ── Action Row ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    children: [
                      ActionBtn(
                        icon: Icons.visibility_outlined,

                        onTap: widget.onView,
                        bg: const Color(0xFF1A1F36),
                      ),
                      const SizedBox(width: 8),
                      ActionBtn(
                        icon: Icons.edit_outlined,
                        onTap: () {},
                        bg: const Color(0xFF6D5EFF),
                      ),
                      const SizedBox(width: 8),
                      ActionBtn(
                        icon: Icons.back_hand_outlined,
                        bg: const Color(0xFF6D5EFF),
                        onTap: () {
                          NavigationService().pushNavigation(
                            Screenroutes.addTripStopScreen,
                            arguments: {
                              'trip': widget.trip,
                              'controller': widget.controller,
                            },
                          );
                        },
                      ),

                      const SizedBox(width: 8),
                      ActionBtn(
                        icon: Icons.person_add_outlined,
                        // label: 'Assign',
                        onTap: widget.onAssign,
                        bg: const Color(0xFF00B8D9),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onDelete,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5C5C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFFF5C5C),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
