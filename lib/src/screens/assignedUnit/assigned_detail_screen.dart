import 'package:flutter/material.dart';
import 'package:sample/src/widgets/full_screen_image_widget.dart';

class AssignedUnitDetailScreen extends StatefulWidget {
  final Map<String, dynamic> unitData;

  const AssignedUnitDetailScreen({super.key, required this.unitData});

  @override
  State<AssignedUnitDetailScreen> createState() =>
      _AssignedUnitDetailScreenState();
}

class _AssignedUnitDetailScreenState extends State<AssignedUnitDetailScreen> {
  int _selectedImageIndex = 0;
  @override
  Widget build(BuildContext context) {
    final serialNo = widget.unitData['serial_no'] ?? 'Unknown';
    final code = widget.unitData['code'] ?? 'N/A';
    final type = widget.unitData['type'] ?? 'N/A';
    final productName = widget.unitData['product']?['Name'] ?? 'N/A';
    final capacityValue = widget.unitData['capacity'] ?? '0';
    final capacityUnit = widget.unitData['capacity_unit']?['Name'] ?? '';
    final currentStock = widget.unitData['current_stock'] ?? 0;
    final refillingUnitImages = widget.unitData['refiling_unit_images'] ?? '';

    // Additional fields from API
    final vehiclePlateNo = widget.unitData['vehicle']?['plate_no'] ?? 'N/A';
    final driverName = widget.unitData['driver']?['Name'] ?? 'N/A';
    final assignedCustomerName =
        widget.unitData['assigned_customer']?['Name'] ?? 'N/A';

    // Calculate stock percentage
    final capacity = double.tryParse(capacityValue) ?? 1;
    final stockPercentage =
        currentStock >= 0
            ? (currentStock / capacity).clamp(0.0, 1.0)
            : 0.0; // Handle negative stock

    return Scaffold(
      appBar: AppBar(title: Text('Refilling Unit Details'), elevation: 0),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card with Basic Info
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.gas_meter_outlined,
                                size: 50,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    serialNo,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Code: $code',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    'Type: $type',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Vehicle & Driver Information Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_shipping,
                              color: Colors.blue,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Vehicle & Driver Info',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildInfoRow('Vehicle Plate No', vehiclePlateNo),
                        _buildInfoRow('Driver Name', driverName),
                        _buildInfoRow(
                          'Assigned Customer',
                          assignedCustomerName,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Stock Level Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop,
                              color: Colors.blue,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Current Stock Level',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Show warning for negative stock
                        if (currentStock < 0)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: Colors.red.shade700,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Warning: Negative stock detected!',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 150,
                              width: 150,
                              child: CircularProgressIndicator(
                                value: stockPercentage,
                                strokeWidth: 15,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getColorForStock(
                                    currentStock,
                                    stockPercentage,
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  currentStock < 0
                                      ? '${currentStock.abs()}'
                                      : '${(stockPercentage * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: _getColorForStock(
                                      currentStock,
                                      stockPercentage,
                                    ),
                                  ),
                                ),
                                Text(
                                  currentStock < 0
                                      ? 'Overdraft'
                                      : '$currentStock $capacityUnit',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                if (currentStock >= 0)
                                  Text(
                                    'of $capacityValue $capacityUnit',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildInfoRow('Product Type', productName),
                        _buildInfoRow(
                          'Capacity',
                          '$capacityValue $capacityUnit',
                        ),
                        _buildInfoRow(
                          'Current Stock',
                          '$currentStock $capacityUnit',
                        ),
                        if (currentStock < 0)
                          _buildInfoRow(
                            'Stock Status',
                            'Overdraft by ${currentStock.abs()} $capacityUnit',
                            valueColor: Colors.red.shade700,
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                if (refillingUnitImages != null &&
                    refillingUnitImages.isNotEmpty)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.photo_library,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Unit Images',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (refillingUnitImages.length > 1)
                                Text(
                                  '${_selectedImageIndex + 1}/${refillingUnitImages.length}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Featured large image
                          GestureDetector(
                            onTap: () {
                              if (refillingUnitImages.isNotEmpty) {
                                showFullScreenImage(
                                  context,
                                  refillingUnitImages[_selectedImageIndex]['Title'],
                                );
                              }
                            },
                            child: Container(
                              height: 220,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    refillingUnitImages.isNotEmpty
                                        ? Image.network(
                                          refillingUnitImages[_selectedImageIndex]['Title'],
                                          fit: BoxFit.cover,
                                          loadingBuilder: (
                                            BuildContext context,
                                            Widget child,
                                            ImageChunkEvent? loadingProgress,
                                          ) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Container(
                                              color: Colors.grey[200],
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    CircularProgressIndicator(
                                                      value:
                                                          loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                              : null,
                                                      color: Colors.blue,
                                                    ),
                                                    SizedBox(height: 12),
                                                    Text(
                                                      'Loading image...',
                                                      style: TextStyle(
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade700,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .broken_image_rounded,
                                                      size: 50,
                                                      color: Colors.grey[500],
                                                    ),
                                                    SizedBox(height: 12),
                                                    Text(
                                                      'Image could not be loaded',
                                                      style: TextStyle(
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                        : Container(
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: Text('No images available'),
                                          ),
                                        ),
                              ),
                            ),
                          ),
                          // Thumbnail scrolling row
                          if (refillingUnitImages.length > 1)
                            Container(
                              margin: EdgeInsets.only(top: 16),
                              height: 70,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: refillingUnitImages.length,
                                itemBuilder: (context, index) {
                                  final bool isSelected =
                                      _selectedImageIndex == index;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImageIndex = index;
                                      });
                                    },
                                    child: Container(
                                      width: 70,
                                      margin: EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? Colors.blue
                                                  : Colors.transparent,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          if (isSelected)
                                            BoxShadow(
                                              color: Colors.blue.withOpacity(
                                                0.3,
                                              ),
                                              spreadRadius: 1,
                                              blurRadius: 3,
                                            ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          refillingUnitImages[index]['Title'],
                                          fit: BoxFit.cover,
                                          loadingBuilder: (
                                            BuildContext context,
                                            Widget child,
                                            ImageChunkEvent? loadingProgress,
                                          ) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Container(
                                              color: Colors.grey[200],
                                              child: Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    value:
                                                        loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 24,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (refillingUnitImages.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Center(
                                child: Text(
                                  'Tap image to view full screen',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$label:', style: TextStyle(color: Colors.grey.shade600)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForStock(int currentStock, double stockPercentage) {
    if (currentStock < 0) {
      return Colors.red; // Negative stock
    } else if (stockPercentage < 0.25) {
      return Colors.red; // Low stock
    } else if (stockPercentage < 0.5) {
      return Colors.orange; // Medium stock
    } else {
      return Colors.green; // Good stock
    }
  }
}
