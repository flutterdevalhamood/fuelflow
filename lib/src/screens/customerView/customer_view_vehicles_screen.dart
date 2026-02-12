import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/customer_view_controller.dart';

import '../../models/customer_view_vehicle_model.dart';

class CustomerViewVehiclesScreen extends StatefulWidget {
  const CustomerViewVehiclesScreen({Key? key}) : super(key: key);

  @override
  State<CustomerViewVehiclesScreen> createState() =>
      _CustomerViewVehiclesScreenState();
}

class _CustomerViewVehiclesScreenState
    extends State<CustomerViewVehiclesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerViewController>().getCustomerViewVehiclesData();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<CustomerViewController>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<CustomerViewVehicle> _filterVehicles(
    List<CustomerViewVehicle>? vehicles,
  ) {
    if (vehicles == null) return [];
    if (_searchQuery.isEmpty) return vehicles;

    return vehicles
        .where(
          (vehicle) => vehicle.plateNo.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicles')),
      body: Consumer<CustomerViewController>(
        builder: (context, controller, child) {
          if (controller.isLoading &&
              controller.customerViewVehiclesData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null &&
              (controller.customerViewVehiclesData == null ||
                  controller.customerViewVehiclesData!.isEmpty)) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final filteredVehicles = _filterVehicles(
            controller.customerViewVehiclesData,
          );

          return Column(
            children: [
              // Search Box
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by plate number...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              // Vehicle List
              Expanded(
                child:
                    filteredVehicles.isEmpty
                        ? RefreshIndicator(
                          onRefresh: () async {
                            await controller.refresh();
                          },
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _searchQuery.isEmpty
                                          ? Icons.local_shipping_outlined
                                          : Icons.search_off,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchQuery.isEmpty
                                          ? 'No vehicles found'
                                          : 'No results found for "$_searchQuery"',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: () async {
                            await controller.refresh();
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount:
                                filteredVehicles.length +
                                (controller.hasMore && _searchQuery.isEmpty
                                    ? 1
                                    : 0),
                            itemBuilder: (context, index) {
                              if (index == filteredVehicles.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final vehicle = filteredVehicles[index];
                              return VehicleListItem(vehicle: vehicle);
                            },
                          ),
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Simplified ListTile design with plate number and type in the same row
class VehicleListItem extends StatelessWidget {
  final CustomerViewVehicle vehicle;

  const VehicleListItem({Key? key, required this.vehicle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.local_shipping, color: Colors.blue[700], size: 32),
      title: Row(
        children: [
          Text(
            vehicle.plateNo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Text(
            '- ${vehicle.type.name}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
      onTap: () {
        // Add navigation or action here if needed
      },
    );
  }
}
