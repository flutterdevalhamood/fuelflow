import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/fuel_trip_controller.dart';

class CompletedAssignmentsScreen extends StatefulWidget {
  const CompletedAssignmentsScreen({Key? key}) : super(key: key);

  @override
  State<CompletedAssignmentsScreen> createState() =>
      _CompletedAssignmentsScreenState();
}

class _CompletedAssignmentsScreenState
    extends State<CompletedAssignmentsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load completed assignments on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FuelTripController>().getCompletedAssignments();
    });

    // Setup pagination listener
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<FuelTripController>().loadMoreCompletedAssignments();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Assignments'),
        // backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: Consumer<FuelTripController>(
        builder: (context, controller, child) {
          if (controller.isLoading &&
              controller.completedAssignmentsData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null &&
              controller.completedAssignmentsData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => controller.getCompletedAssignments(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (controller.completedAssignmentsData == null ||
              controller.completedAssignmentsData!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No completed assignments yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.getCompletedAssignments(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  controller.completedAssignmentsData!.length +
                  (controller.hasMoreCompleted ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == controller.completedAssignmentsData!.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final assignment = controller.completedAssignmentsData![index];
                return CompletedAssignmentCard(assignment: assignment);
              },
            ),
          );
        },
      ),
    );
  }
}

class CompletedAssignmentCard extends StatelessWidget {
  final Map<String, dynamic> assignment;

  const CompletedAssignmentCard({Key? key, required this.assignment})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tripStops = assignment['trip_stops'] as List<dynamic>? ?? [];
    final tripMedia = assignment['trip_media'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment['customer_name'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Trip ID: ${assignment['trip_id']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'COMPLETED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver and Vehicle Info
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow(
                        icon: Icons.person,
                        label: 'Driver',
                        value: assignment['driver'] ?? 'N/A',
                      ),
                    ),
                    Expanded(
                      child: _InfoRow(
                        icon: Icons.local_shipping,
                        label: 'Vehicle',
                        value: assignment['vehicle'] ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // // Dates
                // _InfoRow(
                //   icon: Icons.check_circle,
                //   label: 'Accepted At',
                //   value: _formatDateTime(assignment['accepted_at']),
                // ),
                // const SizedBox(height: 8),
                // _InfoRow(
                //   icon: Icons.calendar_today,
                //   label: 'Created At',
                //   value: _formatDateTime(assignment['created_at']),
                // ),
                const Divider(height: 24),

                // Trip Stops
                // if (tripStops.isNotEmpty) ...[
                //   Row(
                //     children: [
                //       Icon(
                //         Icons.location_on,
                //         size: 20,
                //         color: Colors.blue.shade700,
                //       ),
                //       const SizedBox(width: 8),
                //       const Text(
                //         'Trip Stops',
                //         style: TextStyle(
                //           fontSize: 16,
                //           fontWeight: FontWeight.bold,
                //         ),
                //       ),
                //     ],
                //   ),
                //   const SizedBox(height: 12),
                //   ...tripStops.asMap().entries.map((entry) {
                //     return TripStopWidget(
                //       stop: entry.value,
                //       index: entry.key,
                //       isLast: entry.key == tripStops.length - 1,
                //     );
                //   }).toList(),
                // ],

                // Trip Media/Images
                if (tripMedia.isNotEmpty) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.photo_library,
                        size: 20,
                        color: Colors.purple.shade700,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Trip Images',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TripMediaGallery(mediaList: tripMedia),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final date = DateTime.parse(dateTime);
      return DateFormat('MMM dd, yyyy hh:mm a').format(date);
    } catch (e) {
      return dateTime;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TripStopWidget extends StatelessWidget {
  final Map<String, dynamic> stop;
  final int index;
  final bool isLast;

  const TripStopWidget({
    Key? key,
    required this.stop,
    required this.index,
    required this.isLast,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stopVehicles = stop['stop_vehicles'] as List<dynamic>? ?? [];
    final status = stop['status'] ?? 'pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: status == 'delivered' ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(width: 2, height: 40, color: Colors.grey.shade300),
            ],
          ),
          const SizedBox(width: 12),

          // Stop details
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          stop['site_name'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 15,
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
                          color:
                              status == 'delivered'
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color:
                                status == 'delivered'
                                    ? Colors.green.shade800
                                    : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Qty: ${stop['expected_qty']} L',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Arrival: ${_formatTime(stop['expected_arrival_time'])}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  // Stop Vehicles
                  if (stopVehicles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          stopVehicles.map((vehicle) {
                            final vehicleStatus = vehicle['status'] ?? '0';
                            final isAvailable = vehicleStatus == '1';

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isAvailable
                                        ? Colors.blue.shade50
                                        : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      isAvailable
                                          ? Colors.blue.shade200
                                          : Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAvailable
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 14,
                                    color:
                                        isAvailable ? Colors.blue : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    vehicle['plate_no'] ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isAvailable
                                              ? Colors.blue.shade900
                                              : Colors.red.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? time) {
    if (time == null) return 'N/A';
    try {
      final date = DateTime.parse(time);
      return DateFormat('MMM dd, hh:mm a').format(date);
    } catch (e) {
      return time;
    }
  }
}

class TripMediaGallery extends StatelessWidget {
  final List<dynamic> mediaList;

  const TripMediaGallery({Key? key, required this.mediaList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mediaList.length,
        itemBuilder: (context, index) {
          final media = mediaList[index];
          final imageUrl = media['url'] ?? media['image_url'] ?? '';

          return GestureDetector(
            onTap: () {
              // Show full-screen image
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => FullScreenImage(
                        imageUrl: imageUrl,
                        tag: 'image_$index',
                      ),
                ),
              );
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 8),
              child: Hero(
                tag: 'image_$index',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const FullScreenImage({Key? key, required this.imageUrl, required this.tag})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: tag,
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 100,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
