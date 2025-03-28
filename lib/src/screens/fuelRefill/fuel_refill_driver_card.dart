import 'dart:async';

import 'package:flutter/material.dart';

class FuelRefillDriverCard extends StatefulWidget {
  final List<Map<String, dynamic>> drivers;

  const FuelRefillDriverCard({super.key, required this.drivers});

  @override
  State<FuelRefillDriverCard> createState() => _FuelRefillVehicleCardState();
}

class _FuelRefillVehicleCardState extends State<FuelRefillDriverCard> {
  Timer? _debounceTimer;
  String _searchQuery = '';

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicles =
        widget.drivers.isNotEmpty
            ? (widget.drivers ?? [])
                .where(
                  (vehicle) => (vehicle['plate_no'] ?? '')
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()),
                )
                .toList()
            : [];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Select Driver', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[900],
                  hintText: 'Search vehicles...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: _onSearchChanged,
                style: TextStyle(color: Colors.white),
              ),
            ),

            // Vehicle list
            Expanded(
              child:
                  vehicles.isEmpty
                      ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No customers registered yet.'
                              : 'No results found.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                        ),
                      )
                      : ListView.builder(
                        physics: BouncingScrollPhysics(),
                        itemCount: widget.drivers.length,
                        itemBuilder: (context, index) {
                          final driver = widget.drivers[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.pop(context, driver),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Vehicle icon
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withOpacity(
                                          0.2,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.directions_car,
                                        color: Colors.blueAccent,
                                      ),
                                    ),

                                    SizedBox(width: 16),

                                    // Vehicle details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            driver['Name'] ??
                                                'No Drivers Registered',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            driver['model'] ?? 'Company Name',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Selection indicator
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[600],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
