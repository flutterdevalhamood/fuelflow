// lib/src/screens/trips/trip_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sample/src/models/trip_detail_model.dart';
import 'package:sample/src/providers/trip_assignment_controller.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late final TripController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TripController();
    _controller.addListener(() => setState(() {}));
    _controller.fetchTripDetail(widget.tripId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) return const _LoadingView();
    if (_controller.error != null) {
      return _ErrorView(
        message: _controller.error!,
        onRetry: () => _controller.fetchTripDetail(widget.tripId),
      );
    }
    if (_controller.tripDetail == null) return const SizedBox();
    return _TripDetailBody(detail: _controller.tripDetail!);
  }
}

// ─── Main body ────────────────────────────────────────────────────────────────

class _TripDetailBody extends StatelessWidget {
  final TripDetail detail;
  const _TripDetailBody({required this.detail});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              _TripHeaderCard(detail: detail),
              const SizedBox(height: 16),
              if (detail.assignments.isNotEmpty) ...[
                _AssignmentsSection(assignments: detail.assignments),
                const SizedBox(height: 16),
              ],
              _StopsSection(stops: detail.stops),
              const SizedBox(height: 16),
              if (detail.stockEvents.isNotEmpty) ...[
                _StockEventsSection(stockEvents: detail.stockEvents),
                const SizedBox(height: 16),
              ],
              if (detail.events.isNotEmpty) ...[
                _JourneyEventsSection(events: detail.events),
                const SizedBox(height: 16),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1A1F36),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1F36), Color(0xFF2D3561)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Trip #${detail.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatusPill(status: detail.status),
                ],
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'Trip #${detail.id}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ─── Trip Header Card ─────────────────────────────────────────────────────────

class _TripHeaderCard extends StatelessWidget {
  final TripDetail detail;
  const _TripHeaderCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D7EFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Color(0xFF3D7EFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.customer.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  if (detail.customer.representative != null)
                    Text(
                      detail.customer.representative!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8F9BB3),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              _StatusPill(status: detail.status),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF0F2F8), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.schedule_rounded,
                  label: 'Start',
                  value: _formatDateTime(detail.scheduledStart),
                  iconColor: const Color(0xFF00C48C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.flag_rounded,
                  label: 'End',
                  value: _formatDateTime(detail.scheduledEnd),
                  iconColor: const Color(0xFFFF5C5C),
                ),
              ),
            ],
          ),
          if (detail.customer.mobile != null ||
              detail.customer.email != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF0F2F8), height: 1),
            const SizedBox(height: 12),
            if (detail.customer.mobile != null)
              _ContactRow(
                icon: Icons.phone_rounded,
                value: detail.customer.mobile!,
              ),
            if (detail.customer.email != null) ...[
              const SizedBox(height: 6),
              _ContactRow(
                icon: Icons.email_rounded,
                value: detail.customer.email!,
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy\nhh:mm a').format(dt);
    } catch (_) {
      return raw;
    }
  }
}

// ─── Assignments Section ──────────────────────────────────────────────────────

class _AssignmentsSection extends StatelessWidget {
  final List<TripDetailAssignment> assignments;
  const _AssignmentsSection({required this.assignments});

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: 'Assignments',
      icon: Icons.assignment_ind_rounded,
      iconColor: const Color(0xFF6D5EFF),
      child: Column(
        children:
            assignments.map((a) => _AssignmentCard(assignment: a)).toList(),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final TripDetailAssignment assignment;
  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF0F7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _AvatarCircle(
                label: assignment.driver.name[0],
                gradientColors: const [Color(0xFF6D5EFF), Color(0xFF3D7EFF)],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.driver.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1F36),
                      ),
                    ),
                    if (assignment.driver.mobile != null)
                      Text(
                        assignment.driver.mobile!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8F9BB3),
                        ),
                      ),
                  ],
                ),
              ),
              _StatusPill(status: assignment.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniInfoChip(
                  icon: Icons.directions_car_rounded,
                  label: 'Plate',
                  value: assignment.vehicle.plateNo,
                ),
              ),
              const SizedBox(width: 8),
              if (assignment.vehicle.capacity != null)
                Expanded(
                  child: _MiniInfoChip(
                    icon: Icons.water_drop_rounded,
                    label: 'Capacity',
                    value: '${assignment.vehicle.capacity} IG',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stops Section ────────────────────────────────────────────────────────────

class _StopsSection extends StatelessWidget {
  final List<TripDetailStop> stops;
  const _StopsSection({required this.stops});

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: 'Trip Stops',
      icon: Icons.place_rounded,
      iconColor: const Color(0xFF00C48C),
      child: Column(
        children:
            stops.asMap().entries.map((entry) {
              return _StopCard(stop: entry.value, index: entry.key);
            }).toList(),
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final TripDetailStop stop;
  final int index;
  const _StopCard({required this.stop, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00C48C).withOpacity(0.08),
                  const Color(0xFF00C48C).withOpacity(0.02),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C48C),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  stop.site.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                const Spacer(),
                _StatusPill(status: stop.status),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.local_gas_station_rounded,
                        label: 'Expected Qty',
                        value: '${stop.expectedQuantity} IG',
                        iconColor: const Color(0xFF3D7EFF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.check_circle_rounded,
                        label: 'Delivered Qty',
                        value: '${stop.deliveredQty} IG',
                        iconColor: const Color(0xFF00C48C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.login_rounded,
                        label: 'Expected Arrival',
                        value: _formatDateTime(stop.expectedArrivalTime),
                        iconColor: const Color(0xFFFFAA00),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.logout_rounded,
                        label: 'Expected Done',
                        value: _formatDateTime(stop.expectedCompletedTime),
                        iconColor: const Color(0xFFFF5C5C),
                      ),
                    ),
                  ],
                ),
                if (stop.stopVehicles.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6FB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_car_rounded,
                              size: 14,
                              color: Color(0xFF8F9BB3),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Vehicles (${stop.stopVehicles.length})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8F9BB3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children:
                              stop.stopVehicles
                                  .map(
                                    (v) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF3D7EFF,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        v.plateNo,
                                        style: const TextStyle(
                                          color: Color(0xFF3D7EFF),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd MMM\nhh:mm a').format(dt);
    } catch (_) {
      return raw;
    }
  }
}

// ─── Stock Events Section ─────────────────────────────────────────────────────

class _StockEventsSection extends StatelessWidget {
  final List<TripDetailStockEvent> stockEvents;
  const _StockEventsSection({required this.stockEvents});

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: 'Stock Events',
      icon: Icons.water_drop_rounded,
      iconColor: const Color(0xFF3D7EFF),
      child: Column(
        children: stockEvents.map((e) => _StockEventCard(event: e)).toList(),
      ),
    );
  }
}

class _StockEventCard extends StatelessWidget {
  final TripDetailStockEvent event;
  const _StockEventCard({required this.event});

  bool get isInflow => event.type == 'inflow';

  @override
  Widget build(BuildContext context) {
    final color = isInflow ? const Color(0xFF00C48C) : const Color(0xFF3D7EFF);
    final bgColor = color.withOpacity(0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isInflow
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.type.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${event.quantity} IG',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.start_rounded,
                        label: 'Before',
                        value: '${event.beforeQuantity} IG',
                        iconColor: const Color(0xFF8F9BB3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Color(0xFF8F9BB3),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.flag_rounded,
                        label: 'After',
                        value: '${event.afterQuantity} IG',
                        iconColor: color,
                      ),
                    ),
                  ],
                ),
                if (event.meterReadings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...event.meterReadings.map(
                    (r) => _MeterReadingRow(reading: r),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeterReadingRow extends StatelessWidget {
  final TripDetailMeterReading reading;
  const _MeterReadingRow({required this.reading});

  String get _label {
    switch (reading.readingType) {
      case 'vehicle_tank_start':
        return 'Vehicle Tank Start';
      case 'vehicle_tank_end':
        return 'Vehicle Tank End';
      case 'customer_start_meter':
        return 'Customer Start Meter';
      case 'customer_end_meter':
        return 'Customer End Meter';
      default:
        return reading.readingType
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF3D7EFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.speed_rounded,
              color: Color(0xFF3D7EFF),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8F9BB3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reading.readingValue,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1F36),
                  ),
                ),
              ],
            ),
          ),
          if (reading.photoPath != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3D7EFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.photo_camera_rounded,
                    size: 12,
                    color: Color(0xFF3D7EFF),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Photo',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF3D7EFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Journey Events Section ───────────────────────────────────────────────────

class _JourneyEventsSection extends StatelessWidget {
  final List<TripDetailEvent> events;
  const _JourneyEventsSection({required this.events});

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: 'Journey Events',
      icon: Icons.timeline_rounded,
      iconColor: const Color(0xFFFFAA00),
      child: _EventTimeline(events: events),
    );
  }
}

class _EventTimeline extends StatelessWidget {
  final List<TripDetailEvent> events;
  const _EventTimeline({required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          events.asMap().entries.map((entry) {
            final isLast = entry.key == events.length - 1;
            return _EventTimelineItem(
              event: entry.value,
              isLast: isLast,
              previousEvent: entry.key > 0 ? events[entry.key - 1] : null,
            );
          }).toList(),
    );
  }
}

class _EventTimelineItem extends StatelessWidget {
  final TripDetailEvent event;
  final bool isLast;
  final TripDetailEvent? previousEvent;

  const _EventTimelineItem({
    required this.event,
    required this.isLast,
    this.previousEvent,
  });

  Color get _dotColor {
    switch (event.eventType) {
      case 'start_journey':
        return const Color(0xFF3D7EFF);
      case 'arrived_at_stop':
        return const Color(0xFF00C48C);
      case 'refuel_started':
      case 'customer_loading_started':
        return const Color(0xFFFFAA00);
      case 'refuel_completed':
      case 'customer_loading_completed':
        return const Color(0xFF00C48C);
      case 'departed_from_stop':
        return const Color(0xFF6D5EFF);
      case 'moving_towards_base':
        return const Color(0xFFFF9500);
      case 'returned_to_base':
        return const Color(0xFFFF5C5C);
      default:
        return const Color(0xFF8F9BB3);
    }
  }

  IconData get _icon {
    switch (event.eventType) {
      case 'start_journey':
        return Icons.play_circle_filled_rounded;
      case 'arrived_at_stop':
        return Icons.location_on_rounded;
      case 'refuel_started':
        return Icons.local_gas_station_rounded;
      case 'refuel_completed':
        return Icons.check_circle_rounded;
      case 'customer_loading_started':
        return Icons.download_rounded;
      case 'customer_loading_completed':
        return Icons.done_all_rounded;
      case 'departed_from_stop':
        return Icons.directions_car_rounded;
      case 'moving_towards_base':
        return Icons.home_work_rounded;
      case 'returned_to_base':
        return Icons.flag_rounded;
      default:
        return Icons.circle_rounded;
    }
  }

  String get _label {
    return event.eventType
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toUtc().add(const Duration(hours: 4));
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String? _timeSinceLast() {
    if (previousEvent == null) return null;
    try {
      final current = DateTime.parse(event.createdAt).toUtc();
      final previous = DateTime.parse(previousEvent!.createdAt).toUtc();
      final diff = current.difference(previous).inSeconds;
      return '$diff seconds since last event';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeDiff = _timeSinceLast();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _dotColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: _dotColor, width: 1.5),
                  ),
                  child: Icon(_icon, color: _dotColor, size: 14),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _dotColor.withOpacity(0.4),
                            const Color(0xFFEEF0F7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEF0F7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _dotColor,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(event.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8F9BB3),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (timeDiff != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeDiff,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8F9BB3),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Reusable Widgets ──────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionWrapper extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionWrapper({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1F36),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  Color get _bgColor {
    switch (status) {
      case 'completed':
        return const Color(0xFF00C48C);
      case 'in_progress':
        return const Color(0xFF3D7EFF);
      case 'pending_acceptance':
        return const Color(0xFFFFAA00);
      case 'delivered':
        return const Color(0xFF00C48C);
      case 'cancelled':
        return const Color(0xFFFF5C5C);
      default:
        return const Color(0xFF8F9BB3);
    }
  }

  String get _label {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'pending_acceptance':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status
            .split('_')
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _bgColor.withOpacity(0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _bgColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: iconColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8F9BB3),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1F36),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF8F9BB3)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF8F9BB3)),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F36),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String label;
  final List<Color> gradientColors;

  const _AvatarCircle({required this.label, required this.gradientColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ContactRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8F9BB3)),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF4A5578),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Loading & Error Views ────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F6FB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF3D7EFF), strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Loading trip details...',
              style: TextStyle(
                color: Color(0xFF8F9BB3),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5C5C).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFFF5C5C),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to Load',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1F36),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8F9BB3),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D7EFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
