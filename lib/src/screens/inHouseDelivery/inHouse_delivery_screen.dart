import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/inHouse_controller.dart';
import 'package:sample/src/util/app_routes.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const primary = Color(0xFF2563EB); // strong blue
  static const primaryDark = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFFEFF6FF);
  static const accent = Color(0xFF0EA5E9); // sky blue accent
  static const success = Color(0xFF16A34A);
  static const successBg = Color(0xFFF0FDF4);
  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEF2F2);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textHint = Color(0xFFCBD5E1);
  static const divider = Color(0xFFE2E8F0);
  static const shadow = Color(0x0D2563EB);
}

class InHouseDeliveryScreen extends StatefulWidget {
  const InHouseDeliveryScreen({super.key});

  @override
  State<InHouseDeliveryScreen> createState() => _InHouseDeliveryScreenState();
}

class _InHouseDeliveryScreenState extends State<InHouseDeliveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InHouseDeliveryController>().getAdminVehicles();
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<InHouseDeliveryController>().loadMore();
      }
    });
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              _buildSliverHeader(innerBoxIsScrolled),
            ],
        body: Consumer<InHouseDeliveryController>(
          builder: (context, controller, _) {
            if (controller.isLoading &&
                controller.filteredVehicleData == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _C.primary,
                  strokeWidth: 2.5,
                ),
              );
            }

            final vehicles = controller.filteredVehicleData ?? [];

            if (vehicles.isEmpty) {
              return _buildEmptyState(controller.searchQuery.isNotEmpty);
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: vehicles.length + (controller.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == vehicles.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _C.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }
                return _buildVehicleCard(vehicles[index]);
              },
            );
          },
        ),
      ),
    );
  }

  // ── Sliver App Bar ──────────────────────────────────────────────────────────
  Widget _buildSliverHeader(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: innerBoxIsScrolled ? 1 : 0,
      backgroundColor: _C.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      title: AnimatedOpacity(
        opacity: innerBoxIsScrolled ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: const Text(
          'In-House Delivery',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(background: _buildHeaderBackground()),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _buildSearchBar(),
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), _C.primary, _C.accent],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 60,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.home_work_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Fleet Management',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'In-House Delivery',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a vehicle to initiate refill',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _C.primary,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            context.read<InHouseDeliveryController>().searchVehicles(val);
          },
          style: const TextStyle(
            fontSize: 14,
            color: _C.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search plate number or customer...',
            hintStyle: const TextStyle(
              color: _C.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _C.primary,
              size: 20,
            ),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: _C.textSecondary,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        context.read<InHouseDeliveryController>().clearSearch();
                      },
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _C.primaryLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                size: 44,
                color: _C.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching ? 'No results found' : 'No vehicles available',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try a different plate number or customer name'
                  : 'Vehicles will appear here once added',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _C.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Vehicle Card ────────────────────────────────────────────────────────────
  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final plateNo = vehicle['plate_no'] ?? 'N/A';
    final customerName = vehicle['customer']?['Name'] ?? 'N/A';
    final vehicleType = vehicle['type']?['Name'] ?? 'N/A';
    final capacity = vehicle['capacity'] ?? 'N/A';
    final capacityUnit = vehicle['vehicle_capacity_unit']?['Name'] ?? '';
    final isActive = vehicle['is_active'] == '1' || vehicle['is_active'] == 1;

    void navigateToRefill() {
      final vehicleId = vehicle['id'] as int? ?? 0;
      final availableQty =
          double.tryParse(vehicle['capacity']?.toString() ?? '0') ?? 0.0;
      Navigator.pushNamed(
        context,
        Screenroutes.inHouseFuelRefillScreen,
        arguments: {
          'vehicleId': vehicleId,
          'vehicleName': plateNo,
          'availableQty': availableQty,
          'customerName': customerName,
        },
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: _C.shadow,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: navigateToRefill,
          splashColor: _C.primaryLight,
          highlightColor: _C.primaryLight.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row ────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _C.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: _C.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Plate + customer
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  plateNo,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: _C.textPrimary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              _buildStatusBadge(isActive),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.business_rounded,
                                size: 13,
                                color: _C.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  customerName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _C.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Divider ────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  height: 1,
                  color: _C.divider,
                ),

                // ── Info chips row ─────────────────────────────────────
                Row(
                  children: [
                    _buildTag(
                      Icons.category_rounded,
                      vehicleType,
                      _C.primaryLight,
                      _C.primary,
                    ),
                    const SizedBox(width: 8),
                    _buildTag(
                      Icons.water_drop_rounded,
                      '$capacity $capacityUnit',
                      const Color(0xFFE0F2FE),
                      _C.accent,
                    ),
                    const Spacer(),
                    // ── Refill button ──────────────────────────────────
                    _buildRefillButton(navigateToRefill),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRefillButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: _C.primary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_gas_station_rounded,
              color: Colors.white,
              size: 15,
            ),
            SizedBox(width: 6),
            Text(
              'Refill',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? _C.successBg : _C.errorBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isActive
                  ? _C.success.withOpacity(0.3)
                  : _C.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? _C.success : _C.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive ? _C.success : _C.error,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String label, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
