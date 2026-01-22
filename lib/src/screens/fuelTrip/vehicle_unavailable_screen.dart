import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/fuel_trip_controller.dart';

class BulkVehicleUnavailableScreen extends StatefulWidget {
  final List<int> vehicleIds;
  final List<Map<String, dynamic>> vehicles;
  final int tripStopId;
  final String customerName;
  final String siteName;

  const BulkVehicleUnavailableScreen({
    Key? key,
    required this.vehicleIds,
    required this.vehicles,
    required this.tripStopId,
    required this.customerName,
    required this.siteName,
  }) : super(key: key);

  @override
  State<BulkVehicleUnavailableScreen> createState() =>
      _BulkVehicleUnavailableScreenState();
}

class _BulkVehicleUnavailableScreenState
    extends State<BulkVehicleUnavailableScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitBulkUnavailable() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final controller = context.read<FuelTripController>();

      final success = await controller.postVehicleNotAvailable(
        vehicleId: widget.vehicleIds, // ✅ ARRAY
        description: _descriptionController.text.trim(),
        tripStopId: widget.tripStopId,
      );

      if (!mounted) return;

      if (success) {
        _showSnackBar(
          '${widget.vehicleIds.length} vehicles marked as unavailable',
          color: Colors.green,
        );

        await Future.delayed(const Duration(milliseconds: 600));
        Navigator.pop(context, true);
      } else {
        _showSnackBar(
          controller.errorMessage ?? 'Failed to mark vehicles as unavailable',
        );
      }
    } catch (e) {
      debugPrint('❌ Bulk unavailable error: $e');
      _showSnackBar('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Vehicles Unavailable'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_car,
                              color: Colors.red,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${widget.vehicleIds.length} Vehicles Selected',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),

                        ...widget.vehicles.map(
                          (v) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  v['plate_no']?.toString() ?? 'N/A',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Reason for Unavailability',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'e.g., Breakdown, maintenance, accident, etc.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a reason';
                    }
                    if (value.trim().length < 10) {
                      return 'Minimum 10 characters required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitBulkUnavailable,
                    icon:
                        _isSubmitting
                            ? const SizedBox.shrink()
                            : const Icon(Icons.block),
                    label:
                        _isSubmitting
                            ? const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            )
                            : const Text(
                              'MARK ALL AS UNAVAILABLE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
  }
}
