class TripVehicle {
  final int id;
  final String plateNo;

  const TripVehicle({required this.id, required this.plateNo});

  factory TripVehicle.fromJson(Map<String, dynamic> json) =>
      TripVehicle(id: json['id'] as int, plateNo: json['plate_no'] as String);
}

class TripStop {
  final int id;
  final String siteId;
  final String siteName;
  final String expectedQuantity;
  final DateTime expectedArrivalTime;
  final DateTime expectedCompletedTime;
  final String stopOrder;
  final List<TripVehicle> vehicles;
  final List<dynamic> selectedVehicleIds;
  final List<dynamic> selectedVehicles;
  final int selectedCount;

  const TripStop({
    required this.id,
    required this.siteId,
    required this.siteName,
    required this.expectedQuantity,
    required this.expectedArrivalTime,
    required this.expectedCompletedTime,
    required this.stopOrder,
    required this.vehicles,
    required this.selectedVehicleIds,
    required this.selectedVehicles,
    required this.selectedCount,
  });

  factory TripStop.fromJson(Map<String, dynamic> json) => TripStop(
    id: json['id'] as int,
    siteId: json['site_id'] as String,
    siteName: json['site_name'] as String,
    expectedQuantity: json['expected_quantity'] as String,
    expectedArrivalTime: DateTime.parse(
      json['expected_arrival_time'] as String,
    ),
    expectedCompletedTime: DateTime.parse(
      json['expected_completed_time'] as String,
    ),
    stopOrder: json['stop_order'] as String,
    vehicles:
        (json['vehicles'] as List)
            .map((v) => TripVehicle.fromJson(v as Map<String, dynamic>))
            .toList(),
    selectedVehicleIds: json['selected_vehicle_ids'] as List,
    selectedVehicles: json['selected_vehicles'] as List,
    selectedCount: json['selected_count'] as int,
  );
}
