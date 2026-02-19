import 'package:flutter/material.dart';
import 'package:sample/src/models/trip_customer_model.dart';
import 'package:sample/src/providers/trip_assignment_controller.dart';
import 'package:sample/src/screens/trips/trip_list_screen.dart';

class NewTripSheet extends StatefulWidget {
  final TripController controller;
  const NewTripSheet({required this.controller});

  @override
  State<NewTripSheet> createState() => NewTripSheetState();
}

class NewTripSheetState extends State<NewTripSheet> {
  TripCustomer? _selectedCustomer; // ← replaces _customerIdCtrl
  DateTime? _startDate;
  DateTime? _endDate;
  final _notesCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _customerTouched =
      false; // tracks if user tried to submit without selecting

  // ── date/time helpers (unchanged) ─────────────────────────────────────────

  String _toApiFormat(DateTime dt) {
    final y = dt.year.toString();
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi:00';
  }

  String _displayDate(DateTime? dt) {
    if (dt == null) return '';
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

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_startDate ?? now) : (_endDate ?? now);

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
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
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
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
      if (isStart) {
        _startDate = combined;
        if (_endDate != null && _endDate!.isBefore(combined)) _endDate = null;
      } else {
        _endDate = combined;
      }
    });
  }

  // ── submission ─────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() => _customerTouched = true);
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomer == null)
      return; // inline error shown via _customerTouched

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select both start and end date/time'),
          backgroundColor: const Color(0xFFFF9F43),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final success = await widget.controller.createTrip(
      customerId: _selectedCustomer!.id.toString(),
      scheduledStart: _toApiFormat(_startDate!),
      scheduledEnd: _toApiFormat(_endDate!),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Trip created successfully!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF00C48C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.createError ?? 'Something went wrong',
          ),
          backgroundColor: const Color(0xFFFF5C5C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.controller.isCreating;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) {
        final isLoadingCustomers = widget.controller.isLoadingCustomers;
        final customers = widget.controller.customers;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Handle ─────────────────────────────────────────────
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 20),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0D5E8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // ── Title ──────────────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3D7EFF), Color(0xFF6D5EFF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Trip',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1F36),
                              ),
                            ),
                            Text(
                              'Fill in the details below',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8F9BB3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Customer Dropdown ──────────────────────────────────
                    _label('Customer'),
                    const SizedBox(height: 6),
                    CustomerDropdown(
                      customers: customers,
                      selected: _selectedCustomer,
                      isLoading: isLoadingCustomers,
                      hasError: _customerTouched && _selectedCustomer == null,
                      onChanged:
                          (c) => setState(() {
                            _selectedCustomer = c;
                            _customerTouched = true;
                          }),
                    ),
                    const SizedBox(height: 16),

                    // ── Scheduled Start ────────────────────────────────────
                    _label('Scheduled Start'),
                    const SizedBox(height: 6),
                    DateTimeButton(
                      value: _displayDate(_startDate),
                      placeholder: 'Select start date & time',
                      hasError: false,
                      onTap: () => _pickDateTime(isStart: true),
                    ),
                    const SizedBox(height: 16),

                    // ── Scheduled End ──────────────────────────────────────
                    _label('Scheduled End'),
                    const SizedBox(height: 6),
                    DateTimeButton(
                      value: _displayDate(_endDate),
                      placeholder: 'Select end date & time',
                      hasError:
                          _startDate != null &&
                          _endDate != null &&
                          _endDate!.isBefore(_startDate!),
                      errorText: 'End must be after start',
                      onTap: () => _pickDateTime(isStart: false),
                    ),
                    const SizedBox(height: 16),

                    // ── Notes ──────────────────────────────────────────────
                    _label('Notes  (optional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1F36),
                      ),
                      decoration: _inputDecoration(
                        hint: 'Any additional information…',
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Submit ─────────────────────────────────────────────
                    GestureDetector(
                      onTap: isSubmitting ? null : _submit,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                isSubmitting
                                    ? [
                                      const Color(0xFF3D7EFF).withOpacity(0.6),
                                      const Color(0xFF6D5EFF).withOpacity(0.6),
                                    ]
                                    : const [
                                      Color(0xFF3D7EFF),
                                      Color(0xFF6D5EFF),
                                    ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow:
                              isSubmitting
                                  ? []
                                  : [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF3D7EFF,
                                      ).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                        ),
                        child: Center(
                          child:
                              isSubmitting
                                  ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text(
                                    'Create Trip',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── shared helpers (unchanged) ─────────────────────────────────────────────

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Color(0xFF8F9BB3),
      letterSpacing: 0.4,
    ),
  );

  InputDecoration _inputDecoration({required String hint, IconData? icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFB0BAD3)),
        filled: true,
        fillColor: const Color(0xFFF4F6FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEF0F7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEF0F7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3D7EFF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF5C5C), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF5C5C), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        suffixIcon:
            icon != null
                ? Icon(icon, color: const Color(0xFFB0BAD3), size: 18)
                : null,
      );
}
