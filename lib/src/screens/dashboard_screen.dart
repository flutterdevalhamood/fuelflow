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
  List<Map<String, dynamic>> getGridItems() {
    final allGridItems = [
      {
        'title': 'Customers',
        'icon': Icons.people,
        'route': Screenroutes.customerList,
        'color': Colors.purple,
        'gradient': [Colors.purple, Colors.purple.shade200],
        'description': 'Manage all customer profiles',
      },
      {
        'title': 'Vehicles',
        'icon': Icons.directions_car,
        'route': Screenroutes.vehicleList,
        'color': Colors.orange,
        'gradient': [Colors.orange, Colors.orange.shade200],
        'description': 'View and track fleet vehicles',
      },
      {
        'title': 'Drivers',
        'icon': Icons.badge,
        'route': Screenroutes.driverList,
        'color': Colors.red,
        'gradient': [Colors.red, Colors.red.shade200],
        'description': 'Manage driver information',
      },
      {
        'title': 'Products',
        'icon': Icons.production_quantity_limits,
        'route': Screenroutes.productList,
        'color': Colors.blue,
        'gradient': [Colors.blue, Colors.blue.shade200],
        'description': 'View and manage products',
      },
      {
        'title': 'Refilling Unit',
        'icon': Icons.gas_meter_outlined,
        'route': Screenroutes.refillingUnitListScreen,
        'color': Colors.brown,
        'gradient': [Colors.brown, Colors.brown.shade200],
        'description': 'Track refilling stations',
      },
      {
        'title': 'My Refilling Units',
        'icon': Icons.gas_meter_outlined,
        'route': Screenroutes.assignedRefillingUnitScreen,
        'color': Colors.indigo,
        'gradient': [Color(0xFF3F51B5), Color(0xFFC5CAE9)],
        'description': 'View your assigned refilling units',
      },
      {
        'title': 'Fuel Refill',
        'icon': Icons.local_gas_station,
        'route': Screenroutes.fuelRefillListScreen,
        'color': Colors.green,
        'gradient': [Colors.green, Colors.green.shade200],
        'description': 'Monitor fuel refill activity',
      },
      {
        'title': 'Storage Unit',
        'icon': Icons.storage,
        'route': Screenroutes.storageUnitListScreen,
        'color': Colors.lime,
        'gradient': [Colors.lime, Colors.lime.shade200],
        'description': 'Manage storage facilities',
      },
      {
        'title': 'Reports',
        'icon': Icons.insert_chart,
        'route': Screenroutes.reportsScreen,
        'color': Colors.teal,
        'gradient': [Colors.teal, Colors.teal.shade200],
        'description': 'View system analytics',
      },
    ];

    if (widget.userRole == "customer") {
      return allGridItems
          .where(
            (item) =>
                item['title'] == 'Vehicles' ||
                item['title'] == 'Drivers' ||
                item['title'] == 'Fuel Refill' ||
                item['title'] == 'My Refilling Units' ||
                item['title'] == 'Reports',
          )
          .toList();
    } else if (widget.userRole == "superadmin") {
      return allGridItems
          .where((item) => item['title'] != 'My Refilling Units')
          .toList();
    } else if (widget.userRole == "operator") {
      return allGridItems
          .where(
            (item) =>
                item['title'] == 'Vehicles' ||
                item['title'] == 'Drivers' ||
                item['title'] == 'Fuel Refill' ||
                item['title'] == 'Refilling Unit',
          )
          .toList();
    }
    return [];
  }

  Future<bool> _onWillPop() async {
    bool? shouldLogout = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Logout'),
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
    switch (widget.userRole) {
      case 'superadmin':
        return AuthRepo.user;
      case 'customer':
        return AuthRepo.user;
      case 'operator':
        return 'Operator';
      default:
        return AuthRepo.user;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gridItems = getGridItems();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        drawer: DrawerWidget(),
        appBar: AppBar(
          elevation: 0,
          title: Text(
            'Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, 20, 20, 30),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()},',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getRoleName().toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Welcome to your dashboard',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Dashboard items section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              // Grid items
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: GridView.builder(
                    physics: BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: gridItems.length,
                    itemBuilder: (context, index) {
                      final item = gridItems[index];
                      return _buildGridItem(item);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(Map<String, dynamic> item) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          NavigationService().pushNavigation(item['route']);
        },
        child: Stack(
          children: [
            // Background with gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [item['gradient'][0], item['gradient'][1]],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item['icon'], size: 30, color: Colors.white),
                  ),
                  SizedBox(height: 12),
                  Text(
                    item['title'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    item['description'],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
