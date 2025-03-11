import 'package:flutter/material.dart';

enum NAVIGATION {
  pushNamedRemoveUntil,
  pop,
  push,
  pushReplacement,
  popUntil,
  popAndPush,
}

class NavigationService {
  static final NavigationService _navigationService = NavigationService._();

  factory NavigationService() => _navigationService;
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  NavigationService._();

  BuildContext get context => navigatorKey.currentContext!;

  dynamic pushAndRemoveUntilNavigation(
    String pageName, {
    dynamic arguments,
    String? removeUntilPageName,
  }) {
    final NavigationServiceModel pageDetails = NavigationServiceModel(
      pageName: pageName,
      arguments: arguments,
      removeUntilPageName: removeUntilPageName,
    );
    return pageNavigation(NAVIGATION.pushNamedRemoveUntil, pageDetails);
  }

  dynamic pushNavigation(String pageName, {dynamic arguments}) {
    final NavigationServiceModel pageDetails = NavigationServiceModel(
      pageName: pageName,
      arguments: arguments,
    );
    return pageNavigation(NAVIGATION.push, pageDetails);
  }

  dynamic popNavigation({dynamic arguments}) {
    final NavigationServiceModel pageDetails = NavigationServiceModel(
      arguments: arguments,
    );
    return pageNavigation(NAVIGATION.pop, pageDetails);
  }

  dynamic pushReplaceNavigation(String pageName, {dynamic arguments}) {
    final NavigationServiceModel pageDetails = NavigationServiceModel(
      pageName: pageName,
      arguments: arguments,
    );
    return pageNavigation(NAVIGATION.pushReplacement, pageDetails);
  }

  dynamic navigateToUntil(String pageName, {dynamic arguments}) {
    final NavigationServiceModel pageDetails = NavigationServiceModel(
      pageName: pageName,
      arguments: arguments,
    );
    return pageNavigation(NAVIGATION.popUntil, pageDetails);
  }

  dynamic pageNavigation(
    NAVIGATION type,
    NavigationServiceModel pageDetails,
  ) async {
    final NavigatorState? navigator = navigatorKey.currentState;
    final dynamic arguments = pageDetails.arguments;
    if (type == NAVIGATION.pop) {
      return navigator!.pop(arguments);
    } else {
      final String pageName = pageDetails.pageName ?? '';
      if (pageName.isNotEmpty) {
        if (type == NAVIGATION.pushNamedRemoveUntil) {
          final dynamic data = await navigator?.pushNamedAndRemoveUntil(
            pageName,
            pageDetails.removeUntilPageName != null
                ? ModalRoute.withName(pageDetails.removeUntilPageName!)
                : (Route<dynamic> route) => false,
            arguments: arguments,
          );
          return data;
        } else if (type == NAVIGATION.push) {
          final dynamic data = await navigator?.pushNamed(
            pageName,
            arguments: arguments,
          );
          return data;
        } else if (type == NAVIGATION.pushReplacement) {
          final dynamic data = await navigator?.pushReplacementNamed(
            pageName,
            arguments: arguments,
          );
          return data;
        } else if (type == NAVIGATION.popUntil) {
          return navigator?.popUntil(ModalRoute.withName(pageName));
        } else if (type == NAVIGATION.popAndPush) {
          final dynamic data = await navigator?.popAndPushNamed(
            pageName,
            arguments: arguments,
          );
          return data;
        }
      } else {
        return false;
      }
    }
  }
}

final navService = NavigationService();

class NavigationServiceModel {
  String? pageName;
  dynamic arguments;
  String? removeUntilPageName;

  NavigationServiceModel({
    this.pageName,
    this.arguments,
    this.removeUntilPageName,
  });

  NavigationServiceModel.fromJson(Map<String, dynamic> json) {
    pageName = json['pageName'];
    arguments = json['arguments'];
    removeUntilPageName = json['removeUntilPageName'];
  }
}
