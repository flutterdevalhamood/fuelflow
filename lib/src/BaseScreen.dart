import 'package:flutter/material.dart';
import 'package:sample/src/repo/auth_repo.dart';
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
  String _getInitialRoute() {
    if (AuthRepo.isAuthenticated && AuthRepo.token != null) {
      return Screenroutes.dashboard;
    }
    return Screenroutes.login;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      onGenerateRoute: Screenroutes.routes,
      initialRoute: _getInitialRoute(),
      navigatorObservers: [Screenroutes.routeobserver],
      navigatorKey: NavigationService().navigatorKey,
    );
  }
}
