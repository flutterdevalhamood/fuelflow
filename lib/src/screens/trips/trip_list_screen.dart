import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sample/src/providers/trip_assignment_controller.dart';
import 'package:sample/src/screens/trips/new_trip_widget.dart';
import 'package:sample/src/screens/trips/trip_detail_widget.dart';
import 'package:sample/src/screens/trips/widgets/animated_fab_widget.dart';
import 'package:sample/src/screens/trips/widgets/empty_view_widget.dart';
import 'package:sample/src/screens/trips/widgets/error_view_widget.dart';
import 'package:sample/src/screens/trips/widgets/filter_chip_widget.dart';
import 'package:sample/src/screens/trips/widgets/header_widget.dart';
import 'package:sample/src/screens/trips/widgets/searchbar_widget.dart';
import 'package:sample/src/screens/trips/widgets/shimmer_list_widget.dart';
import 'package:sample/src/screens/trips/widgets/summary_row_widget.dart';
import 'package:sample/src/screens/trips/widgets/trip_card_widget.dart';

import '../../models/trip_customer_model.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen>
    with SingleTickerProviderStateMixin {
  late final TripController _controller;
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  late final AnimationController _fabAnimController;

  static const _filters = [
    ('all', 'All'),
    ('in_progress', 'In Progress'),
    ('pending_acceptance', 'Pending'),
    ('completed', 'Completed'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TripController();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _controller.addListener(() => setState(() {}));
    _controller.fetchTrips();
    Future.delayed(
      const Duration(milliseconds: 600),
      () => _fabAnimController.forward(),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 150) {
      _controller.loadMore();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeaderWidget(onNewTrip: () => _showNewTripSheet(context)),
            SearchBarWidget(
              controller: _searchController,
              onChanged: _controller.setSearch,
            ),
            FilterChips(
              filters: _filters,
              selected: _controller.filterStatus,
              onSelected: _controller.setFilter,
            ),
            SummaryRow(trips: _controller.trips),
            const SizedBox(height: 4),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: AnimatedFab(
        animation: _fabAnimController,
        onPressed: () => _showNewTripSheet(context),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading && _controller.trips.isEmpty) {
      return const ShimmerList();
    }
    if (_controller.error != null && _controller.trips.isEmpty) {
      return ErrorView(
        message: _controller.error!,
        onRetry: _controller.fetchTrips,
      );
    }
    if (_controller.filteredTrips.isEmpty) {
      return const EmptyView();
    }

    return RefreshIndicator(
      color: const Color(0xFF3D7EFF),
      onRefresh: _controller.fetchTrips,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: _controller.filteredTrips.length + 1,
        itemBuilder: (ctx, i) {
          if (i == _controller.filteredTrips.length) {
            return _controller.hasMore
                ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF3D7EFF),
                      ),
                    ),
                  ),
                )
                : const SizedBox(height: 8);
          }
          final trip = _controller.filteredTrips[i];
          return TripCard(
            key: ValueKey(trip.id),
            trip: trip,
            index: i,
            controller: _controller,
            onView: () => _showTripDetail(context, trip),
            onAssign: () => _showAssignSheet(context, trip),
            onDelete: () => _confirmDelete(context, trip),
          );
        },
      ),
    );
  }

  void _showNewTripSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    // Fetch fresh base list each time sheet opens
    _controller.fetchTripBaseList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewTripSheet(controller: _controller),
    );
  }

  void _showTripDetail(BuildContext context, Trip trip) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TripDetailSheet(trip: trip),
    );
  }

  void _showAssignSheet(BuildContext context, Trip trip) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignSheet(trip: trip),
    );
  }

  void _confirmDelete(BuildContext context, Trip trip) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Delete Trip?',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: Text('Trip #${trip.id} will be permanently removed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF8F9BB3)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Trip #${trip.id} deleted'),
                      backgroundColor: const Color(0xFFFF5C5C),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Color(0xFFFF5C5C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

// ─── Assign Sheet ─────────────────────────────────────────────────────────────

class _AssignSheet extends StatelessWidget {
  final Trip trip;
  const _AssignSheet({required this.trip});

  @override
  Widget build(BuildContext context) {
    final drivers = [
      'Ahmed Al-Rashidi',
      'Sara Mohammed',
      'Khalid Nasser',
      'Fatima Al-Zahra',
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD0D5E8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign Driver — Trip #${trip.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select a driver to assign to this trip',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8F9BB3)),
                ),
                const SizedBox(height: 16),
                ...drivers.map(
                  (d) => GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$d assigned to Trip #${trip.id}'),
                          backgroundColor: const Color(0xFF00C48C),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6FB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEEF0F7)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3D7EFF), Color(0xFF6D5EFF)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                d[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            d,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1F36),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Color(0xFFD0D5E8),
                          ),
                        ],
                      ),
                    ),
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

class DateTimeButton extends StatelessWidget {
  final String value;
  final String placeholder;
  final bool hasError;
  final String? errorText;
  final VoidCallback onTap;

  const DateTimeButton({
    required this.value,
    required this.placeholder,
    required this.hasError,
    required this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    hasError
                        ? const Color(0xFFFF5C5C)
                        : !isEmpty
                        ? const Color(0xFF3D7EFF).withOpacity(0.5)
                        : const Color(0xFFEEF0F7),
                width: hasError || !isEmpty ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color:
                      isEmpty
                          ? const Color(0xFFB0BAD3)
                          : const Color(0xFF3D7EFF),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEmpty ? placeholder : value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500,
                      color:
                          isEmpty
                              ? const Color(0xFFB0BAD3)
                              : const Color(0xFF1A1F36),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color:
                      isEmpty
                          ? const Color(0xFFB0BAD3)
                          : const Color(0xFF3D7EFF),
                ),
              ],
            ),
          ),
        ),
        if (hasError && errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFFF5C5C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class CustomerDropdown extends StatelessWidget {
  final List<TripCustomer> customers;
  final TripCustomer? selected;
  final bool isLoading;
  final bool hasError;
  final ValueChanged<TripCustomer?> onChanged;

  const CustomerDropdown({
    required this.customers,
    required this.selected,
    required this.isLoading,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  hasError
                      ? const Color(0xFFFF5C5C)
                      : selected != null
                      ? const Color(0xFF3D7EFF).withOpacity(0.5)
                      : const Color(0xFFEEF0F7),
              width: hasError || selected != null ? 1.5 : 1,
            ),
          ),
          child:
              isLoading
                  // ── skeleton while fetching ──────────────────────────────────
                  ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFB0BAD3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Loading customers…',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFB0BAD3),
                          ),
                        ),
                      ],
                    ),
                  )
                  : customers.isEmpty
                  // ── empty state ─────────────────────────────────────────
                  ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Color(0xFFB0BAD3),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'No customers available',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFB0BAD3),
                          ),
                        ),
                      ],
                    ),
                  )
                  // ── dropdown ─────────────────────────────────────────────
                  : DropdownButtonHideUnderline(
                    child: DropdownButton<TripCustomer>(
                      value: selected,
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color:
                            selected != null
                                ? const Color(0xFF3D7EFF)
                                : const Color(0xFFB0BAD3),
                      ),
                      hint: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'Select a customer',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFB0BAD3),
                          ),
                        ),
                      ),
                      selectedItemBuilder:
                          (_) =>
                              customers
                                  .map(
                                    (c) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          // avatar circle
                                          Container(
                                            width: 26,
                                            height: 26,
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFF3D7EFF),
                                                  Color(0xFF6D5EFF),
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                c.name[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            c.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A1F36),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                      items:
                          customers
                              .map(
                                (c) => DropdownMenuItem<TripCustomer>(
                                  value: c,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF3D7EFF,
                                            ).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              c.name[0].toUpperCase(),
                                              style: const TextStyle(
                                                color: Color(0xFF3D7EFF),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              c.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1A1F36),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: onChanged,
                    ),
                  ),
        ),
        // ── inline error ──────────────────────────────────────────────────
        if (hasError) ...[
          const SizedBox(height: 4),
          const Text(
            'Please select a customer',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFFFF5C5C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
