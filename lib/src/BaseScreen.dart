import 'package:flutter/material.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/app_theme.dart';

import '../main.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

GlobalKey<NavigatorState>? navigatorKey = GlobalKey();

class _BaseScreenState extends State<BaseScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      onGenerateRoute: Screenroutes.routes,
      initialRoute: Screenroutes.login,
      navigatorObservers: [Screenroutes.routeobserver],
      navigatorKey: NavigationService().navigatorKey,
    );
  }
}
