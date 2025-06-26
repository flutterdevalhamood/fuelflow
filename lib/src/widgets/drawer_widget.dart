import 'package:flutter/material.dart';
import 'package:sample/main.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

import '../repo/auth_repo.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  @override
  void _logout() async {
    // Show a confirmation dialog before logging out
    bool confirmLogout =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Logout'),
              content: Text('Are you sure you want to Logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmLogout) {
      // CRITICAL: Clear all authentication data before logout
      await _clearAuthData();

      // Navigate to login screen
      NavigationService().pushAndRemoveUntilNavigation(Screenroutes.login);

      // Show success message
      Future.delayed(Duration(milliseconds: 500), () {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('User logged out successfully!')),
        );
      });
    }
  }

  // Clear all stored authentication data
  Future<void> _clearAuthData() async {
    try {
      // Clear all AuthRepo data
      AuthRepo.token = null;
      AuthRepo.user = null;
      AuthRepo.role = null;
      AuthRepo.customerId = null;
      AuthRepo.loginType = null;

      // If you're using SharedPreferences, clear them too
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.clear(); // Or remove specific keys
      // await prefs.remove('token');
      // await prefs.remove('user');
      // await prefs.remove('role');
      // await prefs.remove('customerId');

      print('All authentication data cleared successfully');
    } catch (e) {
      print('Error clearing auth data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF232526), Color(0xFF92FE9D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, size: 40, color: Colors.green),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi  ${AuthRepo.user ?? ''}',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: Appcolors.textWhiteColor(context),
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${AuthRepo.role}',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium!.copyWith(
                            color: Appcolors.textWhiteColor(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.dashboard,
              size: 18,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            title: Text(
              'Dashboard',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: 20,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              size: 18,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            title: Text(
              'Logout',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: 20,
              ),
            ),
            onTap: () {
              _logout();
            },
          ),
        ],
      ),
    );
  }
}
