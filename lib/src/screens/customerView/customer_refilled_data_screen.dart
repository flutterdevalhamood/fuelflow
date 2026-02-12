import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/models/customer_view_my_refillings_model.dart';
import 'package:sample/src/providers/customer_view_controller.dart';
import 'package:sample/src/screens/customerView/pdf_viewer_screen.dart';

class CustomerViewMyRefillingsScreen extends StatefulWidget {
  const CustomerViewMyRefillingsScreen({super.key});

  @override
  State<CustomerViewMyRefillingsScreen> createState() =>
      _CustomerViewMyRefillingsScreenState();
}

class _CustomerViewMyRefillingsScreenState
    extends State<CustomerViewMyRefillingsScreen> {
  bool _showVehicleDropdown = false;
  bool _isFilterExpanded = true;
  String _vehicleSearchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerViewController>().getCustomerViewVehiclesData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Refillings'), elevation: 0),
      body: Consumer<CustomerViewController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              // Collapsible Filter Card
              _buildCollapsibleFilterCard(controller),

              // Divider
              const Divider(height: 1, thickness: 1),

              // Results Section - Now has more space
              Expanded(child: _buildResultsSection(controller)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCollapsibleFilterCard(CustomerViewController controller) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Always visible header
          InkWell(
            onTap: () {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
                if (!_isFilterExpanded) {
                  _showVehicleDropdown = false;
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Filter Refillings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (controller.filterFromDate != null ||
                      controller.filterToDate != null ||
                      !controller.isAllVehiclesSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _isFilterExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),

          // Expandable filter content
          if (_isFilterExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Clear filters button
                  if (controller.filterFromDate != null ||
                      controller.filterToDate != null ||
                      !controller.isAllVehiclesSelected)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          controller.clearFilters();
                          setState(() {
                            _showVehicleDropdown = false;
                          });
                        },
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear All'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),

                  // Date Fields Row - More compact
                  Row(
                    children: [
                      // From Date
                      Expanded(
                        child: _buildCompactDateField(
                          label: 'From Date *',
                          value: controller.filterFromDate,
                          onTap: () => _selectDate(context, controller, true),
                          icon: Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // To Date
                      Expanded(
                        child: _buildCompactDateField(
                          label: 'To Date',
                          value: controller.filterToDate,
                          onTap: () => _selectDate(context, controller, false),
                          icon: Icons.event,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Vehicle Dropdown - More compact
                  _buildCompactVehicleDropdown(controller),
                  const SizedBox(height: 16),

                  // Search Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed:
                          controller.isLoadingRefillings ||
                                  controller.filterFromDate == null
                              ? null
                              : () {
                                controller.filterMyRefillings();
                                // Collapse filter after search
                                setState(() {
                                  _isFilterExpanded = false;
                                  _showVehicleDropdown = false;
                                });
                              },
                      icon:
                          controller.isLoadingRefillings
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.search, size: 20),
                      label: Text(
                        controller.isLoadingRefillings
                            ? 'Searching...'
                            : 'Search Refillings',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                  // Error message
                  if (controller.refillingErrorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.refillingErrorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
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

  Widget _buildCompactDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color:
                  value != null
                      ? Colors.blue.withOpacity(0.05)
                      : Colors.grey[50],
              border: Border.all(
                color: value != null ? Colors.blue : Colors.grey[300]!,
                width: value != null ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value != null ? _formatDate(value) : 'Select',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          value != null ? FontWeight.w500 : FontWeight.normal,
                      color: value != null ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(
                  icon,
                  size: 16,
                  color: value != null ? Colors.blue : Colors.grey[500],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactVehicleDropdown(CustomerViewController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () {
            setState(() {
              _showVehicleDropdown = !_showVehicleDropdown;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(
                color:
                    controller.selectedVehicleIds.isNotEmpty
                        ? Colors.blue
                        : Colors.grey[300]!,
                width: controller.selectedVehicleIds.isNotEmpty ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    controller.selectedVehicleIds.isEmpty
                        ? 'Select Vehicles'
                        : controller.selectedVehicleIds.length ==
                            (controller.customerViewVehiclesData?.length ?? 0)
                        ? 'All Vehicles Selected'
                        : '${controller.selectedVehicleIds.length} vehicle(s) selected',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          controller.selectedVehicleIds.isNotEmpty
                              ? FontWeight.w500
                              : FontWeight.normal,
                      color:
                          controller.selectedVehicleIds.isNotEmpty
                              ? Colors.black87
                              : Colors.grey[700],
                    ),
                  ),
                ),
                Icon(
                  _showVehicleDropdown
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),

        // Dropdown List with Search
        if (_showVehicleDropdown) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Select/Deselect All Vehicles Option
                  InkWell(
                    onTap: () {
                      final allVehicleIds =
                          controller.customerViewVehiclesData
                              ?.map((v) => v.id)
                              .toList() ??
                          [];

                      if (controller.selectedVehicleIds.length ==
                          allVehicleIds.length) {
                        // Deselect all
                        controller.clearVehicleSelection();
                      } else {
                        // Select all
                        controller.selectAllVehicles(allVehicleIds);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            controller.selectedVehicleIds.length ==
                                        (controller
                                                .customerViewVehiclesData
                                                ?.length ??
                                            0) &&
                                    controller.selectedVehicleIds.isNotEmpty
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            controller.selectedVehicleIds.length ==
                                        (controller
                                                .customerViewVehiclesData
                                                ?.length ??
                                            0) &&
                                    controller.selectedVehicleIds.isNotEmpty
                                ? Icons.check_box
                                : controller.selectedVehicleIds.isEmpty
                                ? Icons.check_box_outline_blank
                                : Icons.indeterminate_check_box,
                            color:
                                controller.selectedVehicleIds.isNotEmpty
                                    ? Colors.blue
                                    : Colors.grey[400],
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'All Vehicles',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _vehicleSearchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search vehicles...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        suffixIcon:
                            _vehicleSearchQuery.isNotEmpty
                                ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    size: 18,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _vehicleSearchQuery = '';
                                    });
                                  },
                                )
                                : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),

                  // Specific Vehicles Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Specific Vehicles',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (controller.selectedVehicleIds.isNotEmpty)
                          Text(
                            '${controller.selectedVehicleIds.length} selected',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[700],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Vehicle List with Search Filter
                  Flexible(
                    child:
                        controller.isLoading
                            ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                            : controller.customerViewVehiclesData == null ||
                                controller.customerViewVehiclesData!.isEmpty
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No vehicles available',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            : Builder(
                              builder: (context) {
                                // Filter vehicles based on search query
                                final filteredVehicles =
                                    controller.customerViewVehiclesData!.where((
                                      vehicle,
                                    ) {
                                      final searchLower =
                                          _vehicleSearchQuery.toLowerCase();
                                      return vehicle.plateNo
                                              .toLowerCase()
                                              .contains(searchLower) ||
                                          vehicle.type.name
                                              .toLowerCase()
                                              .contains(searchLower);
                                    }).toList();

                                if (filteredVehicles.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'No vehicles found',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.only(bottom: 8),
                                  itemCount: filteredVehicles.length,
                                  itemBuilder: (context, index) {
                                    final vehicle = filteredVehicles[index];
                                    final isSelected = controller
                                        .selectedVehicleIds
                                        .contains(vehicle.id);

                                    return InkWell(
                                      onTap: () {
                                        controller.toggleVehicleSelection(
                                          vehicle.id,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? Colors.blue.withOpacity(
                                                    0.05,
                                                  )
                                                  : Colors.transparent,
                                        ),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: isSelected,
                                              onChanged: (bool? value) {
                                                controller
                                                    .toggleVehicleSelection(
                                                      vehicle.id,
                                                    );
                                              },
                                              activeColor: Colors.blue,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    vehicle.plateNo,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  if (vehicle
                                                      .type
                                                      .name
                                                      .isNotEmpty)
                                                    Text(
                                                      '${vehicle.type.name} - ${vehicle.capacity} ${vehicle.vehicleCapacityUnit.name}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultsSection(CustomerViewController controller) {
    // Show empty state if no search has been performed
    if (controller.refillingData == null && !controller.isLoadingRefillings) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 70, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Set filters and search',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select date range and vehicle to view refillings',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Show loading
    if (controller.isLoadingRefillings && controller.refillingData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error with retry (only if no data)
    if (controller.refillingErrorMessage != null &&
        (controller.refillingData == null ||
            controller.refillingData!.isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                controller.refillingErrorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => controller.filterMyRefillings(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty results
    if (controller.refillingData!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_gas_station_outlined,
                size: 70,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No refillings found',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate total quantity - NEW CODE
    double totalQuantity = controller.refillingData!.fold(
      0.0,
      (sum, refilling) => sum + refilling.quantityValue,
    );

    // Show results with header
    return Column(
      children: [
        // Results Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.list_alt, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${controller.refillingData!.length} Result(s) Found',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () => controller.filterMyRefillings(),
                    tooltip: 'Refresh',
                    color: Colors.blue[700],
                  ),
                ],
              ),
            ],
          ),
        ),

        // NEW: Total Quantity Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.blue.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.local_gas_station,
                      color: Colors.blue[700],
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Total Quantity',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                '${totalQuantity.toStringAsFixed(2)} G',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),

        // Results List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: controller.refillingData!.length,
            itemBuilder: (context, index) {
              final refilling = controller.refillingData![index];
              return RefillingCard(refilling: refilling);
            },
          ),
        ),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    controller.isGeneratingPDF
                        ? null
                        : () async {
                          final pdfUrl =
                              await controller.generateFilteredRefillingsPDF();
                          if (pdfUrl != null && context.mounted) {
                            // Navigate to PDF viewer
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        PDFViewerScreen(pdfUrl: pdfUrl),
                              ),
                            );
                          } else if (controller.pdfErrorMessage != null &&
                              context.mounted) {
                            // Show error
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  controller.pdfErrorMessage ?? 'Error',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                icon:
                    controller.isGeneratingPDF
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.picture_as_pdf),
                label: Text(
                  controller.isGeneratingPDF
                      ? 'Generating PDF...'
                      : 'Generate PDF Report',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate(
    BuildContext context,
    CustomerViewController controller,
    bool isStartDate,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.grey[800]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isStartDate) {
        controller.setFilterDates(picked, controller.filterToDate);
      } else {
        controller.setFilterDates(controller.filterFromDate, picked);
      }
    }
  }
}

// Reusing existing RefillingCard, RefillingDetailsSheet, and MeterReadingDetailItem

class RefillingCard extends StatelessWidget {
  final CustomerViewMyRefillingsModel refilling;

  const RefillingCard({Key? key, required this.refilling}) : super(key: key);

  void _showRefillingDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RefillingDetailsSheet(refilling: refilling),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showRefillingDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            refilling.isInflow
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color:
                            refilling.isInflow
                                ? Colors.green[700]
                                : Colors.orange[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            refilling.customerVehicle ?? 'No Vehicle',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  refilling.formattedDate,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${refilling.quantityValue.toStringAsFixed(2)} G',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          refilling.isInflow
                              ? Colors.green[700]
                              : Colors.orange[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class RefillingDetailsSheet extends StatelessWidget {
  final CustomerViewMyRefillingsModel refilling;

  const RefillingDetailsSheet({Key? key, required this.refilling})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Refilling Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Trip ${refilling.tripId}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  _buildInfoCard(
                    icon: Icons.directions_car,
                    label: 'Vehicle',
                    value: refilling.customerVehicle ?? 'Not specified',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    label: 'Date & Time',
                    value: refilling.formattedDate,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.local_gas_station,
                    label: 'Quantity',
                    value: '${refilling.quantityValue.toStringAsFixed(2)} G',
                    color: Colors.red,
                  ),
                  if (refilling.meterReadings.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Meter Readings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...refilling.meterReadings.map(
                      (reading) => MeterReadingDetailItem(reading: reading),
                    ),
                  ],
                  if (refilling.startMeterReading != null &&
                      refilling.endMeterReading != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.1),
                            Colors.blue.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics, color: Colors.blue[700]),
                              const SizedBox(width: 12),
                              const Text(
                                'Total Consumed',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${(refilling.endMeterReading!.value - refilling.startMeterReading!.value).toStringAsFixed(2)} G',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MeterReadingDetailItem extends StatelessWidget {
  final MeterReading reading;

  const MeterReadingDetailItem({Key? key, required this.reading})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reading.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${reading.value.toStringAsFixed(2)} G',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (reading.photo.isNotEmpty)
                  Icon(Icons.image, color: Colors.blue[700], size: 28),
              ],
            ),
          ),
          if (reading.photo.isNotEmpty)
            GestureDetector(
              onTap: () {
                _showImageDialog(context, reading.photo, reading.displayName);
              },
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        reading.photo,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[400],
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.zoom_in,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Tap to view',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.black,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(title),
                  backgroundColor: Colors.black,
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Flexible(
                  child: InteractiveViewer(
                    child: Image.network(
                      imageUrl,
                      errorBuilder: (context, error, stackTrace) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
