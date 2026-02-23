import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/fuel_trip_controller.dart';
import 'package:sample/src/repo/auth_repo.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/widgets/drawer_widget.dart';

class DashBoardScreen extends StatefulWidget {
  final String? userRole;
  const DashBoardScreen({super.key, this.userRole});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen>
    with SingleTickerProviderStateMixin {
  late String? _effectiveUserRole;
  String? _customerName;
  String? _customerEmail;
  String? _customerMobile;
  String? _customerRepresentative;
  String? _customerSecondaryMobile;
  int _pendingTripsCount = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _effectiveUserRole = widget.userRole ?? AuthRepo.role?.toLowerCase();
    _loadCustomerData();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 900), // faster = more urgent feel
      vsync: this,
    );

    // Scale animation - more dramatic
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Pulse animation for the glow effect
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start repeating animation
    _animationController.repeat(reverse: true);

    // Load pending trips count for drivers
    if (_effectiveUserRole == "driver") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPendingTripsCount();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh count when returning to this screen
    if (_effectiveUserRole == "driver") {
      _loadPendingTripsCount();
    }
  }

  Future<void> _loadPendingTripsCount() async {
    try {
      final controller = context.read<FuelTripController>();
      await controller.getAssignedTrips();

      if (controller.assignedTripsData != null) {
        final pendingTrips =
            controller.assignedTripsData!
                .where((trip) => trip['status'] == 'pending')
                .toList();

        if (mounted) {
          setState(() {
            _pendingTripsCount = pendingTrips.length;
          });
        }
      }
    } catch (e) {
      print('Error loading pending trips count: $e');
    }
  }

  void _loadCustomerData() {
    _customerName = AuthRepo.customerName;
    _customerEmail = AuthRepo.customerEmail;
    _customerMobile = AuthRepo.customerMobile;
    _customerRepresentative = AuthRepo.customerRepresentative;
    _customerSecondaryMobile = AuthRepo.customerSecondaryMobile;
  }

  List<Map<String, dynamic>> getGridItems() {
    final allGridItems = [
      {
        'title': 'Customers',
        'icon': Icons.people_rounded,
        'route': Screenroutes.customerList,
        'color': Colors.purple,
        'gradient': [Color(0xFF667eea), Color(0xFF764ba2)],
        'description': 'Manage all customer profiles',
      },
      {
        'title': 'Vehicles',
        'icon': Icons.directions_car_rounded,
        'route': Screenroutes.vehicleList,
        'color': Colors.orange,
        'gradient': [Color(0xFFf093fb), Color(0xFFf5576c)],
        'description': 'View and track fleet vehicles',
      },
      {
        'title': 'Drivers',
        'icon': Icons.badge_rounded,
        'route': Screenroutes.driverList,
        'color': Colors.red,
        'gradient': [Color(0xFFfa709a), Color(0xFFfee140)],
        'description': 'Manage driver information',
      },

      {
        'title': 'Trips',
        'icon': Icons.trip_origin,
        'route': Screenroutes.tripListScreen,
        'color': Colors.green,
        'gradient': [Color(0xFF11998e), Color(0xFF38ef7d)],
        'description': 'View Refilled Data',
      },
      {
        'title': 'Products',
        'icon': Icons.inventory_2_rounded,
        'route': Screenroutes.productList,
        'color': Colors.blue,
        'gradient': [Color(0xFF4facfe), Color(0xFF00f2fe)],
        'description': 'View and manage products',
      },
      {
        'title': 'Refilling Unit',
        'icon': Icons.gas_meter_rounded,
        'route': Screenroutes.refillingUnitListScreen,
        'color': Colors.brown,
        'gradient': [Color(0xFF43e97b), Color(0xFF38f9d7)],
        'description': 'Track refilling stations',
      },
      {
        'title': 'My Refilling Units',
        'icon': Icons.gas_meter_rounded,
        'route': Screenroutes.assignedRefillingUnitScreen,
        'color': Colors.indigo,
        'gradient': [Color(0xFF6a11cb), Color(0xFF2575fc)],
        'description': 'View your assigned refilling units',
      },
      {
        'title': 'Fuel Refill',
        'icon': Icons.local_gas_station_rounded,
        'route': Screenroutes.fuelRefillListScreen,
        'color': Colors.green,
        'gradient': [Color(0xFF11998e), Color(0xFF38ef7d)],
        'description': 'Monitor fuel refill activity',
      },
      {
        'title': 'Storage Refill',
        'icon': Icons.storage_rounded,
        'route': Screenroutes.storageUnitListScreen,
        'color': Colors.lime,
        'gradient': [Color(0xFFee0979), Color(0xFFff6a00)],
        'description': 'Manage storage facilities',
      },
      {
        'title': 'Assigned Trips',
        'icon': Icons.local_shipping_rounded,
        'route': Screenroutes.assignedTripScreen,
        'color': Colors.deepOrange,
        'gradient': [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
        'description': 'Go to Your Assignment Trips',
        'showBadge': true, // Enable badge
        'badgeCount': _pendingTripsCount, // Show count
      },
      {
        'title': 'Accepted Trips',
        'icon': Icons.local_shipping_rounded,
        'route': Screenroutes.acceptedAssignmentScreen,
        'color': Colors.green,
        'gradient': [Color(0xFF11998e), Color(0xFF38ef7d)],
        'description': 'View active accepted trips',
      },
      {
        'title': 'Completed Trips',
        'icon': Icons.storage_rounded,
        'route': Screenroutes.completedAssignmentScreen,
        'color': Colors.lime,
        'gradient': [Color(0xFFee0979), Color(0xFFff6a00)],
        'description': 'View Completed Trips',
      },
      {
        'title': 'Reports',
        'icon': Icons.insert_chart_rounded,
        'route': Screenroutes.reportsScreen,
        'color': Colors.teal,
        'gradient': [Color(0xFF3f5efb), Color(0xFFfc466b)],
        'description': 'View system analytics',
      },
      {
        'title': 'User Registration',
        'icon': Icons.verified_user,
        'route': Screenroutes.userViewScreen,
        'color': Colors.grey,
        'gradient': [Color(0xFFf093fb), Color(0xFFf5576c)],
        'description': 'Register the user',
      },
      {
        'title': 'Customer Sites',
        'icon': Icons.location_on_rounded,
        'route': Screenroutes.customerSitesList,
        'color': Colors.cyan,
        'gradient': [Color(0xFF36d1dc), Color(0xFF5b86e5)],
        'description': 'Manage customer site locations',
      },
      {
        'title': 'View My Vehicles',
        'icon': Icons.directions_car_rounded,
        'route': Screenroutes.customerViewVehicleScreen,
        'color': Colors.orange,
        'gradient': [Color(0xFFf093fb), Color(0xFFf5576c)],
        'description': 'View my vehicles',
      },
      {
        'title': 'Refilled Data View',
        'icon': Icons.local_gas_station_rounded,
        'route': Screenroutes.customerViewRefilledDataScreen,
        'color': Colors.green,
        'gradient': [Color(0xFF11998e), Color(0xFF38ef7d)],
        'description': 'View Refilled Data',
      },
    ];

    if (_effectiveUserRole == "customer") {
      return allGridItems
          .where(
            (item) =>
                item['title'] == 'View My Vehicles' ||
                item['title'] == 'Refilled Data View',
          )
          .toList();
    } else if (_effectiveUserRole == "superadmin") {
      return allGridItems
          .where(
            (item) =>
                item['title'] != 'My Refilling Units' &&
                item['title'] != 'Assigned Trips' &&
                item['title'] != 'Accepted Trips' &&
                item['title'] != 'Completed Trips' &&
                item['title'] != 'My Profile',
          )
          .toList();
    } else if (_effectiveUserRole == "operator") {
      return allGridItems
          .where(
            (item) =>
                item['title'] == 'Vehicles' ||
                item['title'] == 'Drivers' ||
                item['title'] == 'Fuel Refill' ||
                item['title'] == 'Fuel Refill For Trip' ||
                item['title'] == 'Refilling Unit',
          )
          .toList();
    } else if (_effectiveUserRole == "driver") {
      return allGridItems
          .where(
            (item) =>
                item['title'] == 'Assigned Trips' ||
                item['title'] == 'Accepted Trips' ||
                item['title'] == 'Completed Trips',
          )
          .toList();
    }
    return [];
  }

  Future<bool> _onWillPop() async {
    bool? shouldLogout = await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );

    if (shouldLogout ?? false) {
      Navigator.of(context).pushReplacementNamed(Screenroutes.login);
      return true;
    }
    return false;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String? _getRoleName() {
    return AuthRepo.user;
  }

  String _getFormattedRole() {
    switch (_effectiveUserRole) {
      case 'superadmin':
        return 'Super Admin';
      case 'customer':
        return 'Customer';
      case 'operator':
        return 'Operator';
      case 'driver':
        return 'Driver';
      default:
        return 'User';
    }
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      return Icons.wb_cloudy_rounded;
    } else {
      return Icons.nightlight_round;
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Profile Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 24),
                  if (_customerName != null && _customerName!.isNotEmpty)
                    _buildDialogInfoRow(
                      Icons.person_outline,
                      'Name',
                      _customerName!,
                      Color(0xFF667eea),
                    ),
                  if (_customerName != null && _customerName!.isNotEmpty)
                    SizedBox(height: 16),
                  if (_customerEmail != null && _customerEmail!.isNotEmpty)
                    _buildDialogInfoRow(
                      Icons.email_outlined,
                      'Email',
                      _customerEmail!,
                      Color(0xFF4facfe),
                    ),
                  if (_customerEmail != null && _customerEmail!.isNotEmpty)
                    SizedBox(height: 16),
                  if (_customerMobile != null && _customerMobile!.isNotEmpty)
                    _buildDialogInfoRow(
                      Icons.phone_outlined,
                      'Mobile',
                      _customerMobile!,
                      Color(0xFF11998e),
                    ),
                  if (_customerMobile != null && _customerMobile!.isNotEmpty)
                    SizedBox(height: 16),
                  if (_customerSecondaryMobile != null &&
                      _customerSecondaryMobile!.isNotEmpty)
                    _buildDialogInfoRow(
                      Icons.phone_android_outlined,
                      'Secondary Mobile',
                      _customerSecondaryMobile!,
                      Color(0xFF43e97b),
                    ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDialogInfoRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gridItems = getGridItems();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        drawer: DrawerWidget(),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.grey[800]),
          title: Text(
            'Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontSize: 20,
            ),
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 8),
              child: // Replace the existing bell icon Stack with this:
                  Consumer<FuelTripController>(
                builder: (context, controller, _) {
                  return Container(
                    margin: EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_outlined),
                          onPressed: () {
                            NavigationService().pushNavigation(
                              Screenroutes.notificationsScreen,
                            );
                          },
                        ),
                        if (controller.unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                controller.unreadCount > 9
                                    ? '9+'
                                    : '${controller.unreadCount}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF667eea).withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_getGreetingIcon(), color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '${_getGreeting()}!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getRoleName().toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_user_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      _getFormattedRole(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_effectiveUserRole == "customer" &&
                            (_customerName != null ||
                                _customerEmail != null ||
                                _customerMobile != null))
                          InkWell(
                            onTap: _showProfileDialog,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.account_circle_outlined,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'View Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(0xFF667eea),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    physics: BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: MediaQuery.of(context).size.width,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 3.2,
                    ),
                    itemCount: gridItems.length,
                    itemBuilder: (context, index) {
                      final item = gridItems[index];
                      return _buildGridItem(item);
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(Map<String, dynamic> item) {
    final showBadge = item['showBadge'] == true;
    final badgeCount = item['badgeCount'] as int? ?? 0;
    final shouldAnimate = showBadge && badgeCount > 0;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (item['gradient'][0] as Color).withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            if (item['route'] == Screenroutes.acceptedAssignmentScreen) {
              NavigationService().pushNavigation(
                item['route'],
                arguments: AuthRepo.driverId,
              );
            } else if (item['route'] == Screenroutes.acceptedAssignmentScreen) {
              final result = await NavigationService().pushNavigation(
                item['route'],
                arguments: AuthRepo.driverId,
              );

              // Reload count when returning from notification screen
              if (result != null && _effectiveUserRole == "driver") {
                _loadPendingTripsCount();
              }
            } else {
              NavigationService().pushNavigation(item['route']);
            }
          },
          child: Stack(
            children: [
              Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [item['gradient'][0], item['gradient'][1]],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item['icon'],
                              size: 26,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['description'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
              // Badge overlay
              if (showBadge && badgeCount > 0)
                Positioned(
                  top: 12,
                  right: 12,
                  child: TweenAnimationBuilder(
                    duration: Duration(milliseconds: 500),
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    builder: (context, double scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notification_important,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                badgeCount > 99 ? '99+' : '$badgeCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (shouldAnimate) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  // Strong pulsing red glow
                  BoxShadow(
                    color: Colors.red.withOpacity(0.55 * _pulseAnimation.value),
                    blurRadius: 28 + (18 * _pulseAnimation.value),
                    spreadRadius: 4 * _pulseAnimation.value,
                    offset: Offset(0, 0),
                  ),
                  // Orange outer glow layer
                  BoxShadow(
                    color: Colors.orange.withOpacity(
                      0.35 * _pulseAnimation.value,
                    ),
                    blurRadius: 40 + (20 * _pulseAnimation.value),
                    spreadRadius: 6 * _pulseAnimation.value,
                    offset: Offset(0, 0),
                  ),
                  // Base shadow
                  BoxShadow(
                    color: (item['gradient'][0] as Color).withOpacity(0.25),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  cardContent,
                  // Animated glowing border overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, _) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.red.withOpacity(
                                  0.3 + 0.7 * _pulseAnimation.value,
                                ),
                                width: 2.5,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(
                                    0.12 * _pulseAnimation.value,
                                  ),
                                  Colors.transparent,
                                  Colors.white.withOpacity(
                                    0.08 * _pulseAnimation.value,
                                  ),
                                ],
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
        },
      );
    }

    return cardContent;
  }
}
