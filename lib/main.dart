import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/BaseScreen.dart';
import 'package:sample/src/providers/Product_controller.dart';
import 'package:sample/src/providers/customer_controller.dart';
import 'package:sample/src/providers/driver_controller.dart';
import 'package:sample/src/providers/login_controller.dart';
import 'package:sample/src/providers/vehicle_controller.dart';
import 'package:sample/src/providers/vehicle_provider.dart';
import 'package:sample/src/util/shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthController()),
        ChangeNotifierProvider(create: (context) => VehicleProvider()),
        ChangeNotifierProvider(create: (context) => VehicleController()),
        ChangeNotifierProvider(create: (context) => CustomerController()),
        ChangeNotifierProvider(create: (context) => DriverController()),
        ChangeNotifierProvider(create: (context) => ProductController()),
      ],
      child: const BaseScreen(),
    ),
  );
}
