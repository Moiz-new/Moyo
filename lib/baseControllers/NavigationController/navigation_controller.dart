import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Push a new screen onto the navigation stack
  Future<void> pushNamed(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!
        .pushNamed(routeName, arguments: arguments);
  }

  // Pop the current screen
  void pop() {
    navigatorKey.currentState!.pop();
  }

  // Replace the current screen with a new one
  Future<void> pushReplacementNamed(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!
        .pushReplacementNamed(routeName, arguments: arguments);
  }

  // Set a new root screen and clear the stack
  Future<void> pushAndRemoveUntil(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false, // This clears all previous routes
      arguments: arguments,
    );
  }
}

final NavigationService navigationService = NavigationService();
