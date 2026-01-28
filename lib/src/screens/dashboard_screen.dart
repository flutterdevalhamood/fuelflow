import 'package:flutter/material.dart';
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

class _DashBoardScreenState extends State<DashBoardScreen> {
  late String? _effectiveUserRole;

  @override
  void initState() {
    super.initState();
    // Use passed userRole or fall back to AuthRepo role
    _effectiveUserRole = widget.userRole ?? AuthRepo.role?.toLowerCase();
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
        'route': Screenroutes.notificationScreen,
        'color': Colors.deepOrange,
        'gradient': [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
        'description': 'Go to Your Assignment Trips',
      },
      {
        'title': 'Fuel Trip',
        'icon': Icons.local_shipping_rounded,
        'route':
            Screenroutes
                .fuelTripScreen, // Add this route to your app_routes.dart
        'color': Colors.deepOrange,
        'gradient': [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
        'description': 'Manage fuel delivery trips',
      },
      {
        'title': 'Accepted Trips',
        'icon': Icons.local_shipping_rounded,
        'route':
            Screenroutes
                .acceptedAssignmentScreen, // Add this route to your app_routes.dart
        'color': Colors.green,
        'gradient': [Color(0xFF11998e), Color(0xFF38ef7d)],
        'description': 'View active accepted trips',
      },
      {
        'title': 'Completed Trips',
        'icon': Icons.storage_rounded,
        'route': '',
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
    ];

    if (_effectiveUserRole == "customer") {
      return allGridItems
          .where(
            (item) =>
                item['title'] == 'Vehicles' ||
                item['title'] == 'Drivers' ||
                item['title'] == 'Fuel Refill' ||
                item['title'] == 'My Refilling Units' ||
                item['title'] == 'Fuel Trip' ||
                item['title'] == 'Fuel Refill For Trip' ||
                item['title'] == 'Reports',
          )
          .toList();
    } else if (_effectiveUserRole == "superadmin") {
      return allGridItems
          .where((item) => item['title'] != 'My Refilling Units')
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
              child: Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_outlined),
                    onPressed: () {
                      NavigationService().pushNavigation(
                        Screenroutes.notificationScreen,
                      );
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section with gradient
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
              // Section header
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
              // Grid items
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    physics: BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: MediaQuery.of(context).size.width,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 3.2, // wide card look
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
    return Container(
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
          onTap: () {
            // Special handling for driver-specific routes
            if (item['route'] == Screenroutes.acceptedAssignmentScreen) {
              NavigationService().pushNavigation(
                item['route'],
                arguments: AuthRepo.driverId,
              );
            } else if (item['route'] == Screenroutes.notificationScreen) {
              NavigationService().pushNavigation(
                item['route'],
                arguments: AuthRepo.driverId,
              );
            } else {
              NavigationService().pushNavigation(item['route']);
            }
          },
          child: Ink(
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
                  // ICON + TITLE ROW
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

                  // DESCRIPTION ROW
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
        ),
      ),
    );
  }
}
