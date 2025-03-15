import 'package:flutter/material.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/widgets/drawer_widget.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  final List<Map<String, dynamic>> gridItems = [
    {
      'title': 'Customers',
      'icon': Icons.people,
      'route': Screenroutes.customerList,
    },
    {
      'title': 'Vehicles',
      'icon': Icons.directions_car,
      'route': Screenroutes.vehicleList,
    },
    {'title': 'Drivers', 'icon': Icons.badge, 'route': Screenroutes.driverList},
    {
      'title': 'Products',
      'icon': Icons.production_quantity_limits,
      'route': Screenroutes.productList,
    },
    {'title': 'Tank Fuel Level', 'icon': Icons.gas_meter, 'route': ''},
    {
      'title': 'Fuel Refill',
      'icon': Icons.local_gas_station,
      'route': Screenroutes.fuelRefillListScreen,
    },
  ];

  _getBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white],
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
          return Card(
            elevation: 2.0,
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerWidget(),
      appBar: AppBar(title: Text('Dashboard')),
      body: _getBody(context),
    );
  }
}
