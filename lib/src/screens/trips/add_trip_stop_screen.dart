import 'package:flutter/material.dart';
import 'package:sample/src/models/customer_site_model.dart';
import 'package:sample/src/models/stop_entry_model.dart';
import 'package:sample/src/models/trip_customer_model.dart';
import 'package:sample/src/models/trip_stop_model.dart';
import 'package:sample/src/providers/trip_assignment_controller.dart';

class AddTripStopsScreen extends StatefulWidget {
  final Trip trip;
  final TripController controller;

  const AddTripStopsScreen({
    super.key,
    required this.trip,
    required this.controller,
  });

  @override
  State<AddTripStopsScreen> createState() => _AddTripStopsScreenState();
}

class _AddTripStopsScreenState extends State<AddTripStopsScreen> {
  final List<StopEntry> _stops = [];
  int _idCounter = 0;
  bool _submitted = false;
  bool _isInitialLoad = true;

  Trip get trip => widget.trip;
  TripController get ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.fetchCustomerSites(int.parse(trip.customerId));
      ctrl.fetchTripStops(trip.id); // ← fetch existing stops
      ctrl.addListener(_rebuild);
    });
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
      // Populate stops after both sites and stops are loaded
      if (_isInitialLoad &&
          !ctrl.isLoadingSites &&
          !ctrl.isLoadingStops &&
          ctrl.customerSites.isNotEmpty) {
        _populateExistingStops();
        _isInitialLoad = false;
      }
    }
  }

  void _populateExistingStops() {
    if (ctrl.tripStops.isEmpty) {
      _addStop();
      return;
    }

    for (final tripStop in ctrl.tripStops) {
      final matchingSite =
          ctrl.customerSites
              .where((s) => s.id.toString() == tripStop.siteId)
              .firstOrNull;

      // Extract selected vehicle IDs from the API response
      final selectedIds =
          (tripStop.selectedVehicleIds)
              .map((id) => id is int ? id : int.tryParse(id.toString()))
              .whereType<int>()
              .toSet();

      final stop = StopEntry(
        id: 'stop_${_idCounter++}',
        site: matchingSite,
        qty: tripStop.expectedQuantity,
        arrivalTime: tripStop.expectedArrivalTime,
        completedTime: tripStop.expectedCompletedTime,
        availableVehicles: tripStop.vehicles,
        selectedVehicleIds: selectedIds, // ← pre-select from API
        existingStopId: tripStop.id,
      );
      _stops.add(stop);
    }
    setState(() {});
  }

  @override
  void dispose() {
    ctrl.removeListener(_rebuild);
    for (final s in _stops) {
      s.dispose();
    }
    super.dispose();
  }

  void _addStop() {
    setState(() => _stops.add(StopEntry(id: 'stop_${_idCounter++}')));
  }

  void _removeStop(int index) {
    setState(() {
      _stops[index].dispose();
      _stops.removeAt(index);
    });
  }

  void _moveUp(int index) {
    if (index == 0) return;
    setState(() {
      final item = _stops.removeAt(index);
      _stops.insert(index - 1, item);
    });
  }

  void _moveDown(int index) {
    if (index == _stops.length - 1) return;
    setState(() {
      final item = _stops.removeAt(index);
      _stops.insert(index + 1, item);
    });
  }

  Future<void> _pickDateTime({
    required StopEntry stop,
    required bool isArrival,
  }) async {
    final now = DateTime.now();
    final initial =
        isArrival
            ? (stop.arrivalTime ?? trip.scheduledStart)
            : (stop.completedTime ?? trip.scheduledStart);

    final safeInitial =
        initial.isBefore(trip.scheduledStart)
            ? trip.scheduledStart
            : initial.isAfter(trip.scheduledEnd)
            ? trip.scheduledEnd
            : initial;

    final date = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: trip.scheduledStart,
      lastDate: trip.scheduledEnd,
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF3D7EFF),
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(safeInitial),
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFF3D7EFF)),
            ),
            child: child!,
          ),
    );
    if (time == null) return;

    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isArrival) {
        stop.arrivalTime = combined;
        if (stop.completedTime != null &&
            stop.completedTime!.isBefore(combined)) {
          stop.completedTime = null;
        }
      } else {
        stop.completedTime = combined;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _submitted = true);

    if (_stops.isEmpty) {
      _snack('Add at least one stop', const Color(0xFFFF9F43));
      return;
    }
    if (_stops.any((s) => !s.isValid)) {
      _snack('Please complete all fields correctly', const Color(0xFFFF9F43));
      return;
    }

    final success = await ctrl.saveStops(
      tripId: trip.id,
      stops: _stops.map((s) => s.toJson()).toList(),
    );

    if (!mounted) return;

    if (success) {
      _snack('Stops saved!', const Color(0xFF00C48C));
      Navigator.pop(context);
    } else {
      _snack(
        ctrl.saveStopsError ?? 'Something went wrong',
        const Color(0xFFFF5C5C),
      );
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _fmtDisplay(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m';
  }

  String _fmtBanner(DateTime dt) {
    const months = [
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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while fetching initial data
    if (ctrl.isLoadingSites || (ctrl.isLoadingStops && _isInitialLoad)) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Color(0xFF1A1F36),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Add Trip Stops',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1F36),
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF3D7EFF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF1A1F36),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Trip Stops',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1F36),
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Trip #${trip.id}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3D7EFF),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Trip window banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF3D7EFF),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Stops must be between  ${_fmtBanner(trip.scheduledStart)}  –  ${_fmtBanner(trip.scheduledEnd)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Header row
                Row(
                  children: [
                    const Text(
                      'Stop Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1F36),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _addStop,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D7EFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Add Stop',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '* Add multiple stops and use arrows to reorder',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFFF5C5C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Stop cards
                if (_stops.isEmpty)
                  _buildEmptyHint()
                else
                  ...List.generate(_stops.length, (i) => _buildStopCard(i)),
              ],
            ),
          ),
        ],
      ),

      // Bottom bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: ctrl.isSavingStops ? null : _save,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        ctrl.isSavingStops
                            ? const Color(0xFF00C48C).withOpacity(0.5)
                            : const Color(0xFF00C48C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child:
                        ctrl.isSavingStops
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                            : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Save Stops',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
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
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5C5C).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFF5C5C).withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.close_rounded,
                      color: Color(0xFFFF5C5C),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFFFF5C5C),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHint() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F7)),
      ),
      child: const Column(
        children: [
          Icon(Icons.place_outlined, size: 40, color: Color(0xFFD0D5E8)),
          SizedBox(height: 10),
          Text(
            'No stops added',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8F9BB3),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap "Add Stop" to begin',
            style: TextStyle(fontSize: 11, color: Color(0xFFB0BAD3)),
          ),
        ],
      ),
    );
  }

  Widget _buildStopCard(int i) {
    final stop = _stops[i];
    final sites = ctrl.customerSites;
    final isLoadingSites = ctrl.isLoadingSites;

    final siteError = _submitted && stop.site == null;
    final qtyError =
        _submitted &&
        (stop.qtyCtrl.text.trim().isEmpty ||
            double.tryParse(stop.qtyCtrl.text.trim()) == null);
    final arrivalError = _submitted && stop.arrivalTime == null;
    final completedError =
        _submitted &&
        (stop.completedTime == null ||
            (stop.arrivalTime != null &&
                stop.completedTime!.isBefore(stop.arrivalTime!)));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _submitted && !stop.isValid
                  ? const Color(0xFFFF5C5C).withOpacity(0.25)
                  : const Color(0xFFEEF0F7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D7EFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3D7EFF),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Stop',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                const Spacer(),
                _iconBtn(
                  icon: Icons.keyboard_arrow_up_rounded,
                  enabled: i > 0,
                  onTap: () => _moveUp(i),
                ),
                const SizedBox(width: 4),
                _iconBtn(
                  icon: Icons.keyboard_arrow_down_rounded,
                  enabled: i < _stops.length - 1,
                  onTap: () => _moveDown(i),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _removeStop(i),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5C5C).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFFF5C5C),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F2F8)),
            const SizedBox(height: 12),

            // Site dropdown
            _label('Site'),
            const SizedBox(height: 6),
            _buildSiteDropdown(
              stop: stop,
              sites: sites,
              isLoading: isLoadingSites,
              hasError: siteError,
              index: i,
            ),
            if (siteError) _errorText('Please select a site'),
            const SizedBox(height: 12),

            // Expected Quantity
            _label('Expected Quantity'),
            const SizedBox(height: 6),
            TextField(
              controller: stop.qtyCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1F36),
              ),
              decoration: _fieldDeco(
                hint: 'Enter quantity',
                hasError: qtyError,
              ),
            ),
            if (qtyError) _errorText('Enter a valid number'),
            const SizedBox(height: 12),

            // Arrival + Completed
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Arrival Time'),
                      const SizedBox(height: 6),
                      _dateBtn(
                        value: _fmtDisplay(stop.arrivalTime),
                        placeholder: 'Select',
                        hasError: arrivalError,
                        onTap: () => _pickDateTime(stop: stop, isArrival: true),
                      ),
                      if (arrivalError) _errorText('Required'),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Completed Time'),
                      const SizedBox(height: 6),
                      _dateBtn(
                        value: _fmtDisplay(stop.completedTime),
                        placeholder: 'Select',
                        hasError: completedError,
                        onTap:
                            () => _pickDateTime(stop: stop, isArrival: false),
                      ),
                      if (completedError)
                        _errorText(
                          stop.completedTime != null
                              ? 'Must be after arrival'
                              : 'Required',
                        ),
                    ],
                  ),
                ),
              ],
            ),

            if (stop.availableVehicles.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF0F2F8)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B8D9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      color: Color(0xFF00B8D9),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Select Vehicles',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8F9BB3),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          stop.selectedVehicleIds.isEmpty
                              ? const Color(0xFF8F9BB3).withOpacity(0.1)
                              : const Color(0xFF00C48C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${stop.selectedVehicleIds.length}/${stop.availableVehicles.length} selected',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color:
                            stop.selectedVehicleIds.isEmpty
                                ? const Color(0xFF8F9BB3)
                                : const Color(0xFF00C48C),
                      ),
                    ),
                  ),
                  if (stop.existingStopId != null &&
                      stop.selectedVehicleIds.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _saveVehicles(stop),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D7EFF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child:
                            ctrl.isSavingVehicles
                                ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.save_outlined,
                                      color: Colors.white,
                                      size: 11,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Save',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    stop.availableVehicles
                        .map((v) => _vehicleChip(v, stop, i))
                        .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveVehicles(StopEntry stop) async {
    if (stop.existingStopId == null) {
      _snack(
        'Save the stop first before assigning vehicles',
        const Color(0xFFFF9F43),
      );
      return;
    }

    if (stop.selectedVehicleIds.isEmpty) {
      _snack('Select at least one vehicle', const Color(0xFFFF9F43));
      return;
    }

    final success = await ctrl.saveTripStopVehicles(
      stopId: stop.existingStopId!,
      vehicleIds: stop.selectedVehicleIds.toList(),
    );

    if (!mounted) return;

    if (success) {
      _snack('Vehicles assigned successfully!', const Color(0xFF00C48C));
      // Refresh the stops to get updated selected_vehicles
      await ctrl.fetchTripStops(trip.id);
    } else {
      _snack(
        ctrl.saveVehiclesError ?? 'Failed to assign vehicles',
        const Color(0xFFFF5C5C),
      );
    }
  }

  Widget _vehicleChip(TripVehicle vehicle, StopEntry stop, int stopIndex) {
    final isSelected = stop.selectedVehicleIds.contains(vehicle.id);

    return GestureDetector(
      onTap: () {
        setState(() {
          stop.toggleVehicle(vehicle.id);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF00B8D9).withOpacity(0.12)
                  : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF00B8D9) : const Color(0xFFE8EAF2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00B8D9) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected
                          ? const Color(0xFF00B8D9)
                          : const Color(0xFFD0D5E8),
                  width: isSelected ? 1 : 1.5,
                ),
              ),
              child:
                  isSelected
                      ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 10,
                      )
                      : null,
            ),
            const SizedBox(width: 6),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF00B8D9).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Color(0xFF00B8D9),
                size: 10,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              vehicle.plateNo,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    isSelected
                        ? const Color(0xFF00B8D9)
                        : const Color(0xFF1A1F36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteDropdown({
    required StopEntry stop,
    required List<CustomerSite> sites,
    required bool isLoading,
    required bool hasError,
    required int index,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              hasError
                  ? const Color(0xFFFF5C5C)
                  : stop.site != null
                  ? const Color(0xFF3D7EFF).withOpacity(0.4)
                  : const Color(0xFFE8EAF2),
          width: hasError || stop.site != null ? 1.5 : 1,
        ),
      ),
      child:
          isLoading
              ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFB0BAD3),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Loading sites…',
                      style: TextStyle(fontSize: 13, color: Color(0xFFB0BAD3)),
                    ),
                  ],
                ),
              )
              : sites.isEmpty
              ? GestureDetector(
                onTap:
                    () => ctrl.fetchCustomerSites(int.parse(trip.customerId)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: Color(0xFF3D7EFF),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Tap to reload sites',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF3D7EFF),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : DropdownButtonHideUnderline(
                child: DropdownButton<CustomerSite>(
                  value: stop.site,
                  isExpanded: true,
                  isDense: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color:
                        stop.site != null
                            ? const Color(0xFF3D7EFF)
                            : const Color(0xFFB0BAD3),
                  ),
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Select Site',
                      style: TextStyle(fontSize: 13, color: Color(0xFFB0BAD3)),
                    ),
                  ),
                  selectedItemBuilder:
                      (_) =>
                          sites
                              .map(
                                (s) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      s.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1F36),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                  items:
                      sites
                          .map(
                            (s) => DropdownMenuItem<CustomerSite>(
                              value: s,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF00B8D9,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.place_outlined,
                                        color: Color(0xFF00B8D9),
                                        size: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          s.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1A1F36),
                                          ),
                                        ),
                                        Text(
                                          'ID: ${s.id}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF8F9BB3),
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
                  onChanged:
                      (site) => setState(() => _stops[index].site = site),
                ),
              ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Color(0xFF8F9BB3),
      letterSpacing: 0.3,
    ),
  );

  Widget _errorText(String text) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        color: Color(0xFFFF5C5C),
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _iconBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color:
              enabled
                  ? const Color(0xFFF0F2F8)
                  : const Color(0xFFF0F2F8).withOpacity(0.4),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF8F9BB3) : const Color(0xFFD0D5E8),
        ),
      ),
    );
  }

  InputDecoration _fieldDeco({required String hint, required bool hasError}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB0BAD3)),
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFFF5C5C) : const Color(0xFFE8EAF2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFFF5C5C) : const Color(0xFFE8EAF2),
            width: hasError ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFFF5C5C) : const Color(0xFF3D7EFF),
            width: 1.5,
          ),
        ),
      );

  Widget _dateBtn({
    required String value,
    required String placeholder,
    required bool hasError,
    required VoidCallback onTap,
  }) {
    final isEmpty = value.isEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                hasError
                    ? const Color(0xFFFF5C5C)
                    : !isEmpty
                    ? const Color(0xFF3D7EFF).withOpacity(0.4)
                    : const Color(0xFFE8EAF2),
            width: hasError || !isEmpty ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 12,
              color:
                  isEmpty ? const Color(0xFFB0BAD3) : const Color(0xFF3D7EFF),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isEmpty ? placeholder : value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w600,
                  color:
                      isEmpty
                          ? const Color(0xFFB0BAD3)
                          : const Color(0xFF1A1F36),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
