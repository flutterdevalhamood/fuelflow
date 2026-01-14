import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/fuel_trip_controller.dart';

class VehicleUnavailableScreen extends StatefulWidget {
  final int vehicleId;
  final String plateNo;
  final int tripStopId;
  final String customerName;
  final String siteName;

  const VehicleUnavailableScreen({
    Key? key,
    required this.vehicleId,
    required this.plateNo,
    required this.tripStopId,
    required this.customerName,
    required this.siteName,
  }) : super(key: key);

  @override
  State<VehicleUnavailableScreen> createState() =>
      _VehicleUnavailableScreenState();
}

class _VehicleUnavailableScreenState extends State<VehicleUnavailableScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.red}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitUnavailable() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final controller = context.read<FuelTripController>();

      final success = await controller.postVehicleNotAvailable(
        vehicleId: widget.vehicleId,
        description: _descriptionController.text.trim(),
        tripStopId: widget.tripStopId,
      );

      if (!mounted) return;

      if (success) {
        _showSnackBar(
          'Vehicle marked as unavailable successfully!',
          backgroundColor: Colors.green,
        );

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        final errorMsg =
            controller.errorMessage ?? 'Failed to mark vehicle as unavailable';
        _showSnackBar(errorMsg);
      }
    } catch (e) {
      debugPrint('❌ Error marking vehicle unavailable: $e');
      _showSnackBar('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSubmitting) return false;

        if (_descriptionController.text.trim().isNotEmpty) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Discard Changes?'),
                  content: const Text(
                    'You have unsaved changes. Are you sure you want to go back?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Yes, Discard'),
                    ),
                  ],
                ),
          );
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mark Vehicle Unavailable'),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Info Card
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
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.directions_car,
                                  color: Colors.red,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.plateNo,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Stop ID: ${widget.tripStopId}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.business,
                            'Customer',
                            widget.customerName,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.location_on,
                            'Site',
                            widget.siteName,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reason Section Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.red.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Why is this vehicle unavailable?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  const Text(
                    'Reason for Unavailability',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText:
                          'e.g., Vehicle breakdown, maintenance required, accident, etc.',
                      prefixIcon: const Icon(
                        Icons.edit_note,
                        color: Colors.red,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      helperText:
                          'Provide details about why this vehicle cannot be used',
                      helperMaxLines: 2,
                    ),
                    maxLines: 4,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please provide a reason';
                      }
                      if (value.trim().length < 10) {
                        return 'Reason must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Examples Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Example Reasons:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Engine failure or mechanical issues\n'
                          '• Scheduled maintenance in progress\n'
                          '• Accident or collision damage\n'
                          '• Tire puncture or brake problems\n'
                          '• Fuel system malfunction',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Warning Message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This vehicle will be excluded from this delivery stop.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitUnavailable,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        shadowColor: Colors.red.withOpacity(0.3),
                      ),
                      child:
                          _isSubmitting
                              ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.block, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'MARK AS UNAVAILABLE',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
