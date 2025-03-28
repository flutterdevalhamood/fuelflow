import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample/src/blocs/login_bloc.dart';
import 'package:sample/src/screens/customers/customer_detail_screen.dart';
import 'package:sample/src/screens/customers/customer_list_screen.dart';
import 'package:sample/src/screens/customers/customer_registration_screen.dart';
import 'package:sample/src/screens/customers/my_drivers_screen.dart';
import 'package:sample/src/screens/customers/my_vehicles_screen.dart';
import 'package:sample/src/screens/drivers/driver_detail_screen.dart';
import 'package:sample/src/screens/drivers/driver_edit_screen.dart';
import 'package:sample/src/screens/drivers/driver_list_screen.dart';
import 'package:sample/src/screens/drivers/driver_registration_screen.dart';
import 'package:sample/src/screens/forgot_password_screen.dart';
import 'package:sample/src/screens/fuelRefill/fuel_refill_data_screen.dart';
import 'package:sample/src/screens/fuelRefill/fuel_refill_detail_screen.dart';
import 'package:sample/src/screens/fuelRefill/fuel_refill_edit_screen.dart';
import 'package:sample/src/screens/products/product_edit_screen.dart';
import 'package:sample/src/screens/products/product_list_screen.dart';
import 'package:sample/src/screens/products/product_registration_screen.dart';
import 'package:sample/src/screens/refillingUnit/refilling_unit_detail_screen.dart';
import 'package:sample/src/screens/refillingUnit/refilling_unit_list_screen.dart';
import 'package:sample/src/screens/refillingUnit/refilling_unit_registration_screen.dart';
import 'package:sample/src/screens/refillingUnit/refilling_unit_update_screen.dart';

import '../constants/string_constants.dart';
import '../screens/customers/customer_edit_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/fuelRefill/fuel_refill__list_screen.dart';
import '../screens/login_screen.dart';
import '../screens/vehicles/edit_vehicle_screen.dart';
import '../screens/vehicles/vehicle_detail_screen.dart';
import '../screens/vehicles/vehicle_fuel_refill_screen.dart';
import '../screens/vehicles/vehicle_list_screen.dart';
import '../screens/vehicles/vehicle_registration_screen.dart';

class Screenroutes {
  static final RouteObserver<PageRoute> routeobserver =
      RouteObserver<PageRoute>();

  static const String login = "login";
  static const String forgotPassword = "forgotPassword";
  static const String vehicleRegistration = "vehicleRegistration";
  static const String vehicleDetail = "vehicleDetail";
  static const String vehicleList = "vehicleList";
  static const String editDetail = "EditDetail";
  static const String dashboard = "DashBoard";
  static const String customerList = "CustomerList";
  static const String customerRegistration = "CustomerRegistration";
  static const String customerDetail = "CustomerDetail";
  static const String customerEdit = "CustomerEdit";
  static const String myVehicles = "MyVehicles";
  static const String myDrivers = "MyDrivers";
  static const String vehicleRefill = "vehicleRefill";
  static const String driverList = "driverList";
  static const String driverRegistration = "driverRegistration";
  static const String driverDetail = "driverDetail";
  static const String driverEdit = "driverEdit";
  //product
  static const String productList = "productList";
  static const String productRegistration = "productRegistration";
  static const String productEdit = "productEdit";

  //fuelRefill
  static const String fuelRefillListScreen = "fuelRefillListScreen";
  static const String fuelRefillDataScreen = "fuelRefillDataScreen";
  static const String fuelRefillDetailScreen = 'fuelRefillDetailScreen';
  static const String fuelRefillEditScreen = "fuelRefillEditScreen";

  //refillingUnit
  static const String refillingUnitListScreen = "refillingUnitListScreen";
  static const String refillingUnitRegistrationScreen =
      "refillingUnitRegistrationScreen";
  static const String refillingUnitUpdateScreen = "refillingUnitUpdateScreen";
  static const String refillingUnitDetailScreen = "refillingUnitDetailScreen";

  static Route<dynamic>? routes(RouteSettings settings) {
    StringConstants.currentRoute = settings.name ?? "";

    switch (settings.name) {
      case Screenroutes.login:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.login),
          builder: (BuildContext context) {
            return BlocProvider(
              create: (context) => LoginBloc(),
              child: const LoginScreen(),
            );
          },
        );

      case Screenroutes.forgotPassword:
        final data = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.forgotPassword),
          builder: (BuildContext context) {
            return ForgotPasswordScreen();
          },
        );

      case Screenroutes.vehicleRegistration:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.vehicleRegistration),
          builder: (BuildContext context) {
            return VehicleRegistrationScreen();
          },
        );

      case Screenroutes.vehicleDetail:
        final vehicle = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.vehicleDetail),
          builder: (BuildContext context) {
            return VehicleDetailScreen(vehicle: vehicle ?? {});
          },
        );

      case Screenroutes.vehicleList:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.vehicleList),
          builder: (BuildContext context) {
            return VehicleListScreen();
          },
        );

      case Screenroutes.editDetail:
        final vehicle = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.editDetail),
          builder: (BuildContext context) {
            return EditVehicleScreen(data: vehicle ?? {});
          },
        );

      case Screenroutes.dashboard:
        final data = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.dashboard),
          builder: (BuildContext context) {
            return DashBoardScreen(userRole: data?['role']?.toString() ?? '');
          },
        );

      case Screenroutes.customerList:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.customerList),
          builder: (BuildContext context) {
            return CustomerListScreen();
          },
        );

      case Screenroutes.customerRegistration:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.customerRegistration,
          ),
          builder: (BuildContext context) {
            return CustomerRegistrationScreen();
          },
        );

      case Screenroutes.customerDetail:
        final customer = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.customerDetail),
          builder: (BuildContext context) {
            return CustomerDetailScreen(customer: customer ?? {});
          },
        );

      case Screenroutes.customerEdit:
        final customer = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.customerEdit),
          builder: (BuildContext context) {
            return CustomerEditScreen(data: customer ?? {});
          },
        );

      case Screenroutes.myVehicles:
        final data = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.myVehicles),
          builder: (BuildContext context) {
            return MyVehiclesScreen(data: data ?? {});
          },
        );

      case Screenroutes.myDrivers:
        final data = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.myDrivers),
          builder: (BuildContext context) {
            return MyDriversScreen(data: data ?? {});
          },
        );

      case Screenroutes.vehicleRefill:
        final vehicle = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.vehicleRefill),
          builder: (BuildContext context) {
            return FuelRefillingScreen(vehicle: vehicle ?? {});
          },
        );
      case Screenroutes.driverList:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.driverList),
          builder: (BuildContext context) {
            return DriverListScreen();
          },
        );

      case Screenroutes.driverRegistration:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.driverRegistration),
          builder: (BuildContext context) {
            return DriverRegistrationScreen();
          },
        );

      case Screenroutes.driverDetail:
        final driver = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.driverDetail),
          builder: (BuildContext context) {
            return DriverDetailScreen(driver: driver ?? {});
          },
        );

      case Screenroutes.driverEdit:
        final driver = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.driverEdit),
          builder: (BuildContext context) {
            return DriverEditScreen(data: driver ?? {});
          },
        );

      case Screenroutes.productList:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.productList),
          builder: (BuildContext context) {
            return ProductListScreen();
          },
        );

      case Screenroutes.productRegistration:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.productRegistration),
          builder: (BuildContext context) {
            return ProductRegistrationScreen();
          },
        );

      case Screenroutes.productEdit:
        final product = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.productEdit),
          builder: (BuildContext context) {
            return ProductEditScreen(data: product ?? {});
          },
        );

      case Screenroutes.fuelRefillListScreen:
        final data = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.fuelRefillListScreen,
          ),
          builder: (BuildContext context) {
            return FuelRefillListScreen();
          },
        );

      case Screenroutes.fuelRefillDataScreen:
        final data = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.fuelRefillDataScreen,
          ),
          builder: (BuildContext context) {
            return FuelRefillDataScreen();
          },
        );

      case Screenroutes.fuelRefillDetailScreen:
        final data = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.fuelRefillDetailScreen,
          ),
          builder: (BuildContext context) {
            return FuelRefillDetailScreen(data: data ?? {});
          },
        );

      case Screenroutes.fuelRefillEditScreen:
        final data = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.fuelRefillEditScreen,
          ),
          builder: (BuildContext context) {
            return EditFuelRefillScreen(data: data ?? {});
          },
        );

      case Screenroutes.refillingUnitListScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.refillingUnitListScreen,
          ),
          builder: (BuildContext context) {
            return RefillingUnitListScreen();
          },
        );

      case Screenroutes.refillingUnitRegistrationScreen:
        final data = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.refillingUnitRegistrationScreen,
          ),
          builder: (BuildContext context) {
            return RefillingUnitRegistrationScreen();
          },
        );

      case Screenroutes.refillingUnitUpdateScreen:
        final data = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.refillingUnitUpdateScreen,
          ),
          builder: (BuildContext context) {
            return RefillingUnitUpdateScreen(data: data ?? {});
          },
        );

      case Screenroutes.refillingUnitDetailScreen:
        final data = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.refillingUnitDetailScreen,
          ),
          builder: (BuildContext context) {
            return RefillingUnitDetailScreen(data: data ?? {});
          },
        );
    }
    return null;
  }
}
