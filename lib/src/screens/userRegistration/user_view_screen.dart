import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/user_registration_controller.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

class UserDisplayScreen extends StatefulWidget {
  const UserDisplayScreen({Key? key}) : super(key: key);

  @override
  State<UserDisplayScreen> createState() => _UserDisplayScreenState();
}

class _UserDisplayScreenState extends State<UserDisplayScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserRegistrationController>().getUsersData();
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<UserRegistrationController>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshUsers() async {
    await context.read<UserRegistrationController>().getUsersData();
  }

  void _navigateToRegistration() async {
    final result = await NavigationService().pushNavigation(
      Screenroutes.userRegistrationScreen,
    );

    if (result == true && mounted) {
      _refreshUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Users'), elevation: 0),
      body: Consumer<UserRegistrationController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.userData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshUsers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (controller.userData == null || controller.userData!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No users found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _navigateToRegistration,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First User'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshUsers,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount:
                  controller.userData!.length + (controller.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == controller.userData!.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final user = controller.userData![index];
                return _UserCard(user: user);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToRegistration,
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const _UserCard({required this.user});

  String _getRoleColor(String? roleId) {
    switch (roleId) {
      case '3':
        return 'Sales';
      case '4':
        return 'Customer';
      case '5':
        return 'Driver';
      default:
        return 'Unknown';
    }
  }

  Color _getRoleBadgeColor(String? roleId) {
    switch (roleId) {
      case '3':
        return Colors.blue;
      case '4':
        return Colors.green;
      case '5':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = user['isActive'] == '1';
    final driver = user['driver'];
    final customer = user['customer'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleBadgeColor(user['role_id']),
                  child: Text(
                    user['name']?[0]?.toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleBadgeColor(
                                user['role_id'],
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getRoleBadgeColor(user['role_id']),
                              ),
                            ),
                            child: Text(
                              _getRoleColor(user['role_id']),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getRoleBadgeColor(user['role_id']),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user['email'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (driver != null || customer != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 4),
            ],
            if (driver != null)
              Row(
                children: [
                  const Icon(
                    Icons.local_shipping,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Driver: ${driver['Name'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            if (customer != null)
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Customer: ${customer['Name'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isActive ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: isActive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
