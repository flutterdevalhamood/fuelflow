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

  void _showAssignSheet(BuildContext context) async {
    final ctrl = widget.controller;
    await ctrl.fetchTripAssignmentOptions(widget.trip.id);
    if (!context.mounted) return;

    int? selectedVehicleId;
    int? selectedDriverId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListenableBuilder(
                  listenable: ctrl,
                  builder: (_, __) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Handle bar
                            Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0E3EF),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Header
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF00B8D9),
                                        Color(0xFF0096B7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF00B8D9,
                                        ).withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_add_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Assign Trip',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A1F36),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 3),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF3D7EFF,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Trip #${widget.trip.id}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF3D7EFF),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            if (ctrl.isLoadingAssignmentOptions) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40,
                                ),
                                child: const Column(
                                  children: [
                                    CircularProgressIndicator(
                                      color: Color(0xFF00B8D9),
                                      strokeWidth: 2.5,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Fetching available options…',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8F9BB3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              // Info strip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F6FA),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFEEF0F7),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _infoChip(
                                      icon: Icons.local_shipping_outlined,
                                      label:
                                          '${ctrl.availableVehicles.length} Vehicles',
                                      color: const Color(0xFF3D7EFF),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 28,
                                      color: const Color(0xFFEEF0F7),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                    ),
                                    _infoChip(
                                      icon: Icons.person_outlined,
                                      label:
                                          '${ctrl.availableDrivers.length} Drivers',
                                      color: const Color(0xFF00B8D9),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Vehicle section
                              _sectionLabel(
                                'Select Vehicle',
                                Icons.local_shipping_outlined,
                                const Color(0xFF3D7EFF),
                              ),
                              const SizedBox(height: 8),
                              if (ctrl.availableVehicles.isEmpty)
                                _emptyOption('No vehicles available')
                              else
                                ...ctrl.availableVehicles.map((v) {
                                  final id = v['id'] as int;
                                  final isSelected = selectedVehicleId == id;
                                  return _selectionTile(
                                    isSelected: isSelected,
                                    activeColor: const Color(0xFF3D7EFF),
                                    onTap:
                                        () => setSheetState(
                                          () =>
                                              selectedVehicleId =
                                                  isSelected ? null : id,
                                        ),
                                    leading: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? const Color(
                                                  0xFF3D7EFF,
                                                ).withOpacity(0.15)
                                                : const Color(0xFFF0F2F8),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.local_shipping_rounded,
                                        color:
                                            isSelected
                                                ? const Color(0xFF3D7EFF)
                                                : const Color(0xFF8F9BB3),
                                        size: 16,
                                      ),
                                    ),
                                    title: v['plate_no'] as String,
                                    subtitle:
                                        'Available Qty: ${v['available_qty']}',
                                  );
                                }),
                              const SizedBox(height: 20),

                              // Driver section
                              _sectionLabel(
                                'Select Driver',
                                Icons.person_outlined,
                                const Color(0xFF00B8D9),
                              ),
                              const SizedBox(height: 8),
                              if (ctrl.availableDrivers.isEmpty)
                                _emptyOption('No drivers available')
                              else
                                ...ctrl.availableDrivers.map((d) {
                                  final id = d['id'] as int;
                                  final isSelected = selectedDriverId == id;
                                  return _selectionTile(
                                    isSelected: isSelected,
                                    activeColor: const Color(0xFF00B8D9),
                                    onTap:
                                        () => setSheetState(
                                          () =>
                                              selectedDriverId =
                                                  isSelected ? null : id,
                                        ),
                                    leading: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? const Color(
                                                  0xFF00B8D9,
                                                ).withOpacity(0.15)
                                                : const Color(0xFFF0F2F8),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Icon(
                                        Icons.person_rounded,
                                        color:
                                            isSelected
                                                ? const Color(0xFF00B8D9)
                                                : const Color(0xFF8F9BB3),
                                        size: 18,
                                      ),
                                    ),
                                    title: d['name'] as String,
                                    subtitle: 'Driver ID: ${d['id']}',
                                  );
                                }),
                              const SizedBox(height: 24),

                              // Selection summary
                              if (selectedVehicleId != null ||
                                  selectedDriverId != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF00C48C,
                                    ).withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF00C48C,
                                      ).withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Color(0xFF00C48C),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          [
                                            if (selectedVehicleId != null)
                                              'Vehicle: ${ctrl.availableVehicles.firstWhere((v) => v['id'] == selectedVehicleId)['plate_no']}',
                                            if (selectedDriverId != null)
                                              'Driver: ${ctrl.availableDrivers.firstWhere((d) => d['id'] == selectedDriverId)['name']}',
                                          ].join('  •  '),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF00C48C),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          ctrl.isSavingAssignment
                                              ? null
                                              : () async {
                                                if (selectedVehicleId == null ||
                                                    selectedDriverId == null) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: const Text(
                                                        'Select both vehicle and driver',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          const Color(
                                                            0xFFFF9F43,
                                                          ),
                                                      behavior:
                                                          SnackBarBehavior
                                                              .floating,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                final success = await ctrl
                                                    .saveTripAssignment(
                                                      tripId: widget.trip.id,
                                                      vehicleId:
                                                          selectedVehicleId!,
                                                      driverId:
                                                          selectedDriverId!,
                                                    );
                                                if (!ctx.mounted) return;
                                                Navigator.pop(ctx);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      success
                                                          ? 'Trip assigned successfully!'
                                                          : (ctrl.saveAssignmentError ??
                                                              'Failed'),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        success
                                                            ? const Color(
                                                              0xFF00C48C,
                                                            )
                                                            : const Color(
                                                              0xFFFF5C5C,
                                                            ),
                                                    behavior:
                                                        SnackBarBehavior
                                                            .floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              },
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors:
                                                ctrl.isSavingAssignment
                                                    ? [
                                                      const Color(
                                                        0xFF00B8D9,
                                                      ).withOpacity(0.5),
                                                      const Color(
                                                        0xFF0096B7,
                                                      ).withOpacity(0.5),
                                                    ]
                                                    : [
                                                      const Color(0xFF00B8D9),
                                                      const Color(0xFF0096B7),
                                                    ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow:
                                              ctrl.isSavingAssignment
                                                  ? []
                                                  : [
                                                    BoxShadow(
                                                      color: const Color(
                                                        0xFF00B8D9,
                                                      ).withOpacity(0.35),
                                                      blurRadius: 12,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ],
                                        ),
                                        child: Center(
                                          child:
                                              ctrl.isSavingAssignment
                                                  ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                  : const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.check_rounded,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        'Confirm Assignment',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(ctx),
                                    child: Container(
                                      height: 50,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F6FA),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE8EAF2),
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: Color(0xFF8F9BB3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper widgets — add these inside _TripCardState

  Widget _sectionLabel(String text, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 12),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _emptyOption(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEF0F7)),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8F9BB3)),
        ),
      ),
    );
  }

  Widget _selectionTile({
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required Widget leading,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected
                    ? activeColor.withOpacity(0.4)
                    : const Color(0xFFEEF0F7),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? activeColor : const Color(0xFF1A1F36),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8F9BB3),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? activeColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? activeColor : const Color(0xFFD0D5E8),
                  width: isSelected ? 0 : 1.5,
                ),
              ),
              child:
                  isSelected
                      ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 12,
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
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
                        onTap: () => _showAssignSheet(context),
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
