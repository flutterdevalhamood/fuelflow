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
      },
      {
        'title': 'Vehicles',
        'icon': Icons.directions_car,
        'route': Screenroutes.vehicleList,
        'color': Colors.orange,
      },
      {
        'title': 'Drivers',
        'icon': Icons.badge,
        'route': Screenroutes.driverList,
        'color': Colors.red,
      },
      {
        'title': 'Products',
        'icon': Icons.production_quantity_limits,
        'route': Screenroutes.productList,
        'color': Colors.blue,
      },
      {
        'title': 'Fuel Refill',
        'icon': Icons.local_gas_station,
        'route': Screenroutes.fuelRefillListScreen,
        'color': Colors.green,
      },
      {
        'title': 'Refilling Unit',
        'icon': Icons.gas_meter_outlined,
        'route': Screenroutes.refillingUnitListScreen,
        'color': Colors.brown,
      },
    ];

    if (widget.userRole == "customer") {
      return allGridItems
          .where(
            (item) =>
                item['title'] == 'Vehicles' ||
                item['title'] == 'Drivers' ||
                item['title'] == 'Fuel Refill',
          )
          .toList();
    } else if (widget.userRole == "superadmin") {
      return allGridItems;
    }
    return [];
  }

  Future<bool> _onWillPop() async {
    bool? shouldLogout = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
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

  _getBody(BuildContext context) {
    final gridItems = getGridItems();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blueGrey, Colors.blueAccent],
        ),
      ),
      child: GridView.builder(
        padding: EdgeInsets.all(16.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Number of columns in the grid
          crossAxisSpacing: 10.0, // Spacing between columns
          mainAxisSpacing: 10.0, // Spacing between rows
          childAspectRatio: 1.8, // Aspect ratio of the grid items
        ),
        itemCount: gridItems.length,
        itemBuilder: (context, index) {
          final color = gridItems[index]['color'] ?? Colors.grey;
          return Card(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.55), color.withOpacity(0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: InkWell(
                onTap: () {
                  NavigationService().pushNavigation(gridItems[index]['route']);
                  // print('${gridItems[index]['title']} tapped');
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(gridItems[index]['icon'], size: 35.0),
                    SizedBox(height: 8.0),
                    Text(
                      gridItems[index]['title'],
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        drawer: DrawerWidget(),
        appBar: AppBar(title: Text('Dashboard')),
        body: _getBody(context),
      ),
    );
  }
}
