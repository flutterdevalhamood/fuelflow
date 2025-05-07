// import 'package:flutter/material.dart';
// import 'package:sample/src/util/app_navigation.dart';
// import 'package:sample/src/util/app_routes.dart';
// import 'package:sample/src/widgets/drawer_widget.dart';
//
// class DashBoardScreen extends StatefulWidget {
//   final String? userRole;
//   const DashBoardScreen({super.key, this.userRole});
//
//   @override
//   State<DashBoardScreen> createState() => _DashBoardScreenState();
// }
//
// class _DashBoardScreenState extends State<DashBoardScreen> {
//   List<Map<String, dynamic>> getGridItems() {
//     final allGridItems = [
//       {
//         'title': 'Customers',
//         'icon': Icons.people,
//         'route': Screenroutes.customerList,
//         'color': Colors.purple,
//       },
//       {
//         'title': 'Vehicles',
//         'icon': Icons.directions_car,
//         'route': Screenroutes.vehicleList,
//         'color': Colors.orange,
//       },
//       {
//         'title': 'Drivers',
//         'icon': Icons.badge,
//         'route': Screenroutes.driverList,
//         'color': Colors.red,
//       },
//       {
//         'title': 'Products',
//         'icon': Icons.production_quantity_limits,
//         'route': Screenroutes.productList,
//         'color': Colors.blue,
//       },
//       {
//         'title': 'Refilling Unit',
//         'icon': Icons.gas_meter_outlined,
//         'route': Screenroutes.refillingUnitListScreen,
//         'color': Colors.brown,
//       },
//       {
//         'title': 'Fuel Refill',
//         'icon': Icons.local_gas_station,
//         'route': Screenroutes.fuelRefillListScreen,
//         'color': Colors.green,
//       },
//       {
//         'title': 'Storage Unit',
//         'icon': Icons.storage,
//         'route': Screenroutes.storageUnitListScreen,
//         'color': Colors.lime,
//       },
//
//       {
//         'title': 'Reports',
//         'icon': Icons.insert_chart,
//         'route': Screenroutes.reportsScreen,
//         'color': Colors.teal,
//       },
//     ];
//
//     if (widget.userRole == "customer") {
//       return allGridItems
//           .where(
//             (item) =>
//                 item['title'] == 'Vehicles' ||
//                 item['title'] == 'Drivers' ||
//                 item['title'] == 'Fuel Refill' ||
//                 item['title'] == 'Reports',
//           )
//           .toList();
//     } else if (widget.userRole == "superadmin") {
//       return allGridItems;
//     } else if (widget.userRole == "operator") {
//       return allGridItems
//           .where(
//             (item) =>
//                 item['title'] == 'Vehicles' ||
//                 item['title'] == 'Drivers' ||
//                 item['title'] == 'Fuel Refill' ||
//                 item['title'] == 'Refilling Unit',
//           )
//           .toList();
//     }
//     return [];
//   }
//
//   Future<bool> _onWillPop() async {
//     bool? shouldLogout = await showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('Logout'),
//             content: const Text('Are you sure you want to logout?'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(false),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(true),
//                 child: const Text(
//                   'Logout',
//                   style: TextStyle(color: Colors.red),
//                 ),
//               ),
//             ],
//           ),
//     );
//
//     if (shouldLogout ?? false) {
//       Navigator.of(context).pushReplacementNamed(Screenroutes.login);
//       return true;
//     }
//     return false;
//   }
//
//   _getBody(BuildContext context) {
//     final gridItems = getGridItems();
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [Colors.blueGrey, Colors.blueAccent],
//         ),
//       ),
//       child: GridView.builder(
//         padding: EdgeInsets.all(16.0),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2, // Number of columns in the grid
//           crossAxisSpacing: 10.0, // Spacing between columns
//           mainAxisSpacing: 10.0, // Spacing between rows
//           childAspectRatio: 1.8, // Aspect ratio of the grid items
//         ),
//         itemCount: gridItems.length,
//         itemBuilder: (context, index) {
//           final color = gridItems[index]['color'] ?? Colors.grey;
//           return Card(
//             elevation: 2.0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 gradient: LinearGradient(
//                   colors: [color.withOpacity(0.55), color.withOpacity(0.9)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: InkWell(
//                 onTap: () {
//                   NavigationService().pushNavigation(gridItems[index]['route']);
//                   // print('${gridItems[index]['title']} tapped');
//                 },
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(gridItems[index]['icon'], size: 35.0),
//                     SizedBox(height: 8.0),
//                     Text(
//                       gridItems[index]['title'],
//                       style: TextStyle(fontSize: 14.0),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         drawer: DrawerWidget(),
//         appBar: AppBar(title: Text('Dashboard')),
//         body: _getBody(context),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
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
        'gradient': [Color(0xFF9C27B0), Color(0xFFE1BEE7)],
        'description': 'Manage all customer profiles',
      },
      {
        'title': 'Vehicles',
        'icon': Icons.directions_car,
        'route': Screenroutes.vehicleList,
        'color': Colors.orange,
        'gradient': [Color(0xFFFF9800), Color(0xFFFFE0B2)],
        'description': 'View and track fleet vehicles',
      },
      {
        'title': 'Drivers',
        'icon': Icons.badge,
        'route': Screenroutes.driverList,
        'color': Colors.red,
        'gradient': [Color(0xFFF44336), Color(0xFFFFCDD2)],
        'description': 'Manage driver information',
      },
      {
        'title': 'Products',
        'icon': Icons.production_quantity_limits,
        'route': Screenroutes.productList,
        'color': Colors.blue,
        'gradient': [Color(0xFF2196F3), Color(0xFFBBDEFB)],
        'description': 'View and manage products',
      },
      {
        'title': 'Refilling Unit',
        'icon': Icons.gas_meter_outlined,
        'route': Screenroutes.refillingUnitListScreen,
        'color': Colors.brown,
        'gradient': [Color(0xFF795548), Color(0xFFD7CCC8)],
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
        'gradient': [Color(0xFF4CAF50), Color(0xFFC8E6C9)],
        'description': 'Monitor fuel refill activity',
      },
      {
        'title': 'Storage Unit',
        'icon': Icons.storage,
        'route': Screenroutes.storageUnitListScreen,
        'color': Colors.lime,
        'gradient': [Color(0xFFCDDC39), Color(0xFFF0F4C3)],
        'description': 'Manage storage facilities',
      },
      {
        'title': 'Reports',
        'icon': Icons.insert_chart,
        'route': Screenroutes.reportsScreen,
        'color': Colors.teal,
        'gradient': [Color(0xFF009688), Color(0xFFB2DFDB)],
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
      return allGridItems;
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
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
                ],
              ),
            ),
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
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item['gradient'][0].withOpacity(0.8),
                item['gradient'][1].withOpacity(0.5),
              ],
            ),
          ),
          child: Padding(
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
        ),
      ),
    );
  }
}
