import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/firebase_options.dart';
import 'package:sample/firebase_services.dart';
import 'package:sample/src/BaseScreen.dart';
import 'package:sample/src/providers/Product_controller.dart';
import 'package:sample/src/providers/customer_controller.dart';
import 'package:sample/src/providers/customer_site_controller.dart';
import 'package:sample/src/providers/customer_view_controller.dart';
import 'package:sample/src/providers/driver_controller.dart';
import 'package:sample/src/providers/fuel_refill_before_trip_controller.dart';
import 'package:sample/src/providers/fuel_refill_controller.dart';
import 'package:sample/src/providers/fuel_trip_controller.dart';
import 'package:sample/src/providers/login_controller.dart';
import 'package:sample/src/providers/reports_controller.dart';
import 'package:sample/src/providers/storage_unit_controller.dart';
import 'package:sample/src/providers/trip_tracking_controller.dart';
import 'package:sample/src/providers/vehicle_controller.dart';
import 'package:sample/src/providers/vehicle_provider.dart';
import 'package:sample/src/util/shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/providers/assigned_controller.dart';
import 'src/providers/refilling_unit_controller.dart';
import 'src/providers/user_registration_controller.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseService().initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthController()),
        ChangeNotifierProvider(create: (context) => VehicleProvider()),
        ChangeNotifierProvider(create: (context) => VehicleController()),
        ChangeNotifierProvider(create: (context) => CustomerController()),
        ChangeNotifierProvider(create: (context) => DriverController()),
        ChangeNotifierProvider(create: (context) => ProductController()),
        ChangeNotifierProvider(create: (context) => FuelRefillController()),
        ChangeNotifierProvider(create: (context) => RefillingUnitController()),
        ChangeNotifierProvider(create: (context) => ReportsController()),
        ChangeNotifierProvider(create: (context) => StorageUnitController()),
        ChangeNotifierProvider(
          create: (context) => AssignedRefillingUnitController(),
        ),
        ChangeNotifierProvider(create: (context) => FuelTripController()),
        ChangeNotifierProvider(
          create: (context) => FuelRefillBeforeTripController(),
        ),
        ChangeNotifierProvider(create: (context) => TripTrackingController()),
        ChangeNotifierProvider(
          create: (context) => UserRegistrationController(),
        ),
        ChangeNotifierProvider(create: (context) => CustomerSiteController()),
        ChangeNotifierProvider(create: (context) => CustomerViewController()),
      ],
      child: const BaseScreen(),
    ),
  );
}
