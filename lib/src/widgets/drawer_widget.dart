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
    // Show a confirmation dialog before deleting
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
      NavigationService().pushAndRemoveUntilNavigation(Screenroutes.login);
      Future.delayed(Duration(milliseconds: 500), () {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('User Logged out successfully!')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const SizedBox(height: 75),
          Column(
            children: [
              // Container(
              //   width: 80,
              //   height: 80,
              //   clipBehavior: Clip.hardEdge,
              //   decoration: BoxDecoration(shape: BoxShape.circle),
              //   child: Image.network(
              //     AuthRepo.user?.imagePath ?? '',
              //     fit: BoxFit.cover,
              //     errorBuilder:
              //         (context, error, stackTrace) =>
              //             Center(child: const Icon(Icons.person, size: 80)),
              //   ),
              // ),
              // const SizedBox(height: 10),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
              //   child: Text(
              //     {
              //           LoginType.candidate: AuthRepo.user?.fullName,
              //           LoginType.company: AuthRepo.user?.name,
              //           LoginType.volunteer: AuthRepo.user?.name,
              //         }[AuthRepo.loginType]?.toCapitalized() ??
              //         '',
              //     style: const TextStyle(
              //       fontWeight: FontWeight.w700,
              //       fontSize: 30,
              //     ),
              //     textAlign: TextAlign.center,
              //   ),
              // ),
              Text(
                'Hi ${AuthRepo.user ?? ''}',
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 50),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: const Text(
              'Dashboard',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context); // Closes the drawer
            },
          ),
          // if (AuthRepo.loginType == LoginType.candidate)
          //   ListTile(
          //     leading: SvgPicture.asset('assets/svg/candidatesvg.svg'),
          //     title: const Text(
          //       'Profile',
          //       style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          //     ),
          //     onTap: () {
          //       navigatorKey?.currentState?.popAndPushNamed(
          //         ProfileEditScreen.routeName,
          //       );
          //
          //       // Navigator.of(context).push(
          //       //     MaterialPageRoute(builder: (context) => ProfileEditScreen()));
          //     },
          //   ),
          ListTile(
            leading: Icon(Icons.logout),
            title: const Text(
              'Logout',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            onTap: _logout,

            // AuthRepo.logOut();
          ),
          const SizedBox(height: 250),
          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: Text(
          //     "${AuthRepo.loginType?.name.toCapitalized() ?? ''} Profile",
          //   ),
          // ),
          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: Text(
          //     "Version ${packageInfo?.version ?? ''}",
          //     style: TextStyle(fontSize: 12),
          //   ),
          // ),
        ],
      ),
    );
  }
}
