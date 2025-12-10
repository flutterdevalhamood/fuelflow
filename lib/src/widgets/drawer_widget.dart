// import 'package:flutter/material.dart';
// import 'package:sample/main.dart';
// import 'package:sample/src/util/app_colors.dart';
// import 'package:sample/src/util/app_navigation.dart';
// import 'package:sample/src/util/app_routes.dart';
//
// import '../repo/auth_repo.dart';
//
// class DrawerWidget extends StatefulWidget {
//   const DrawerWidget({super.key});
//
//   @override
//   State<DrawerWidget> createState() => _DrawerWidgetState();
// }
//
// class _DrawerWidgetState extends State<DrawerWidget> {
//   @override
//   void _logout() async {
//     // Show a confirmation dialog before logging out
//     bool confirmLogout =
//         await showDialog<bool>(
//           context: context,
//           builder: (context) {
//             return AlertDialog(
//               title: Text('Logout'),
//               content: Text('Are you sure you want to Logout?'),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   child: Text('Cancel'),
//                 ),
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, true),
//                   child: Text('Logout', style: TextStyle(color: Colors.red)),
//                 ),
//               ],
//             );
//           },
//         ) ??
//         false;
//
//     if (confirmLogout) {
//       // CRITICAL: Clear all authentication data before logout
//       await _clearAuthData();
//
//       // Navigate to login screen
//       NavigationService().pushAndRemoveUntilNavigation(Screenroutes.login);
//
//       // Show success message
//       Future.delayed(Duration(milliseconds: 500), () {
//         scaffoldMessengerKey.currentState?.showSnackBar(
//           SnackBar(content: Text('User logged out successfully!')),
//         );
//       });
//     }
//   }
//
//   // Clear all stored authentication data
//   Future<void> _clearAuthData() async {
//     try {
//       // Clear all AuthRepo data
//       AuthRepo.token = null;
//       AuthRepo.user = null;
//       AuthRepo.role = null;
//       AuthRepo.customerId = null;
//       AuthRepo.loginType = null;
//
//       // If you're using SharedPreferences, clear them too
//       // final prefs = await SharedPreferences.getInstance();
//       // await prefs.clear(); // Or remove specific keys
//       // await prefs.remove('token');
//       // await prefs.remove('user');
//       // await prefs.remove('role');
//       // await prefs.remove('customerId');
//
//       print('All authentication data cleared successfully');
//     } catch (e) {
//       print('Error clearing auth data: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: Column(
//         children: [
//           DrawerHeader(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF232526), Color(0xFF92FE9D)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.verified_user, size: 40, color: Colors.green),
//                 const SizedBox(width: 18),
//                 Expanded(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Hi  ${AuthRepo.user ?? ''}',
//                         style: Theme.of(context).textTheme.titleLarge!.copyWith(
//                           color: Appcolors.textWhiteColor(context),
//                         ),
//                       ),
//                       SizedBox(height: 4),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.green,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           '${AuthRepo.role}',
//                           style: Theme.of(
//                             context,
//                           ).textTheme.titleMedium!.copyWith(
//                             color: Appcolors.textWhiteColor(context),
//                             fontWeight: FontWeight.bold,
//                             fontSize: 10,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           ListTile(
//             leading: Icon(
//               Icons.dashboard,
//               size: 18,
//               color: Theme.of(context).colorScheme.onBackground,
//             ),
//             title: Text(
//               'Dashboard',
//               style: Theme.of(context).textTheme.titleSmall!.copyWith(
//                 color: Theme.of(context).colorScheme.onBackground,
//                 fontSize: 20,
//               ),
//             ),
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: Icon(
//               Icons.logout,
//               size: 18,
//               color: Theme.of(context).colorScheme.onBackground,
//             ),
//             title: Text(
//               'Logout',
//               style: Theme.of(context).textTheme.titleSmall!.copyWith(
//                 color: Theme.of(context).colorScheme.onBackground,
//                 fontSize: 20,
//               ),
//             ),
//             onTap: () {
//               _logout();
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:sample/main.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

import '../repo/auth_repo.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  void _logout() async {
    bool confirmLogout =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              content: Text(
                'Are you sure you want to logout?',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Logout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmLogout) {
      await _clearAuthData();
      NavigationService().pushAndRemoveUntilNavigation(Screenroutes.login);

      Future.delayed(Duration(milliseconds: 500), () {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('User logged out successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      });
    }
  }

  Future<void> _clearAuthData() async {
    try {
      AuthRepo.token = null;
      AuthRepo.user = null;
      AuthRepo.role = null;
      AuthRepo.customerId = null;
      AuthRepo.loginType = null;
      print('All authentication data cleared successfully');
    } catch (e) {
      print('Error clearing auth data: $e');
    }
  }

  String _getFormattedRole() {
    final role = AuthRepo.role?.toLowerCase() ?? '';
    switch (role) {
      case 'superadmin':
        return 'Super Admin';
      case 'customer':
        return 'Customer';
      case 'operator':
        return 'Operator';
      default:
        return role.isNotEmpty
            ? role[0].toUpperCase() + role.substring(1)
            : 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.grey[50],
        child: Column(
          children: [
            // Enhanced Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, 60, 24, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with gradient background
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  // User name
                  Text(
                    'Hi, ${AuthRepo.user ?? 'User'}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  // Role badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          _getFormattedRole(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(height: 4),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      // Add settings navigation
                    },
                  ),
                  SizedBox(height: 4),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      // Add help navigation
                    },
                  ),
                ],
              ),
            ),

            // Divider
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(thickness: 1, color: Colors.grey[300]),
            ),

            // Logout button
            Padding(
              padding: EdgeInsets.all(16),
              child: _buildLogoutButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF667eea).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: Color(0xFF667eea)),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.red[400]!, Colors.red[600]!]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _logout,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                SizedBox(width: 12),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
