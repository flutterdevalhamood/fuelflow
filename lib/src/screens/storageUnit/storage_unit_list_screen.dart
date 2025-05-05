import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/storage_unit_controller.dart';
import 'package:sample/src/screens/storageUnit/storage_unit_registration_screen.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/snack.dart';

import '../../util/app_colors.dart';

class StorageUnitListScreen extends StatefulWidget {
  const StorageUnitListScreen({super.key});

  @override
  State<StorageUnitListScreen> createState() => _StorageUnitListScreenState();
}

class _StorageUnitListScreenState extends State<StorageUnitListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool confirmLogout = false;
  late StorageUnitController _storageUnitController;
  final ScrollController _scrollController = ScrollController();
  bool isInitialLoad = true;
  int? _selectedCustomerId;
  final TextEditingController _customerController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollController();
      _storageUnitController = Provider.of<StorageUnitController>(
        context,
        listen: false,
      );
      _storageUnitController.getStorageUnitData().then((_) {
        setState(() {
          isInitialLoad = false;
        });
      });
      _storageUnitController.getFuelRefillDropdown();
    });
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange) {
        if (!_storageUnitController.isLoading &&
            _storageUnitController.hasMore) {
          _storageUnitController.loadMore();
          showInfoSnack('Loading more units...');
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _reasonController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  void _navigateToStorageUnitDetails(Map<String, dynamic> storageUnitData) {
    NavigationService()
        .pushNavigation(
          Screenroutes.storageUnitDetailScreen,
          arguments: storageUnitData,
        )
        .then((result) {
          if (result == true) {
            _storageUnitController.getStorageUnitData();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StorageUnitController>(
      builder: (context, storageUnitController, child) {
        final storageUnitData = storageUnitController.storageUnitData;

        final filteredUnits =
            storageUnitData != null
                ? storageUnitData
                    .where(
                      (unit) => (unit['vehicle']['plate_no'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()),
                    )
                    .toList()
                : [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Storage Units'),
            elevation: 0,
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
            child: Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: _buildStorageUnitList(
                    storageUnitController,
                    filteredUnits,
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StorageUnitRegistrationScreen(),
                ),
              ).then((_) => _storageUnitController.getStorageUnitData());
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Unit'),
            backgroundColor: Colors.blue.shade700,
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by vehicle number',
          hintStyle: TextStyle(color: Appcolors.textLightGrayColor(context)),
          prefixIcon: const Icon(Icons.search, color: Colors.blue),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                  : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildStorageUnitList(
    StorageUnitController controller,
    List<dynamic> units,
  ) {
    if (controller.isLoading && isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (units.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storage_outlined, size: 70, color: Colors.blue.shade200),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No storage units found'
                  : 'No results match your search',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await controller.getStorageUnitData();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: units.length + (controller.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == units.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.blue.shade700,
                ),
              ),
            );
          }

          final unit = units[index];
          return _buildStorageUnitCard(unit);
        },
      ),
    );
  }

  Widget _buildStorageUnitCard(Map<String, dynamic> unit) {
    final vehicleInfo = unit['vehicle'] ?? {};
    final plateNumber = vehicleInfo['plate_no'] ?? 'Unknown';
    final description = unit['description'] ?? 'No description';
    final capacity = unit['qty'] ?? 'N/A';
    final driverName = unit['driver']['Name'] ?? 'Unknown';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blue.shade100, width: 1),
        ),
        child: InkWell(
          onTap: () => _navigateToStorageUnitDetails(unit),
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.blue.shade100,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_shipping,
                        size: 28,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plateNumber,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem(
                      icon: Icons.local_gas_station,
                      label: 'Driver',
                      value: driverName,
                    ),
                    _buildInfoItem(
                      icon: Icons.storage,
                      label: 'Capacity',
                      value: '$capacity L',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
