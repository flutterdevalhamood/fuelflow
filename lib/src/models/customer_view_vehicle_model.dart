class CustomerViewVehicle {
  final int id;
  final String plateNo;
  final String vehicleTypeId;
  final String userId;
  final String updatedAt;
  final String capacity;
  final String capacityUnitId;
  final String description;
  final String customerId;
  final String isActive;
  final String vehicleOwnerType;
  final User user;
  final List<dynamic> vehicleImages;
  final VehicleType type;
  final CapacityUnit vehicleCapacityUnit;
  final Customer customer;

  CustomerViewVehicle({
    required this.id,
    required this.plateNo,
    required this.vehicleTypeId,
    required this.userId,
    required this.updatedAt,
    required this.capacity,
    required this.capacityUnitId,
    required this.description,
    required this.customerId,
    required this.isActive,
    required this.vehicleOwnerType,
    required this.user,
    required this.vehicleImages,
    required this.type,
    required this.vehicleCapacityUnit,
    required this.customer,
  });

  factory CustomerViewVehicle.fromJson(Map<String, dynamic> json) {
    return CustomerViewVehicle(
      id: json['id'] ?? 0,
      plateNo: json['plate_no'] ?? '',
      vehicleTypeId: json['vehicle_type_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      updatedAt: json['updated_at'] ?? '',
      capacity: json['capacity']?.toString() ?? '0',
      capacityUnitId: json['capacity_unit_id']?.toString() ?? '',
      description: json['description'] ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      isActive: json['is_active']?.toString() ?? '0',
      vehicleOwnerType: json['vehicle_owner_type'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
      vehicleImages: json['vehicle_images'] ?? [],
      type: VehicleType.fromJson(json['type'] ?? {}),
      vehicleCapacityUnit: CapacityUnit.fromJson(
        json['vehicle_capacity_unit'] ?? {},
      ),
      customer: Customer.fromJson(json['customer'] ?? {}),
    );
  }

  bool get isActiveVehicle => isActive == '1';
}

class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

class VehicleType {
  final int id;
  final String name;

  VehicleType({required this.id, required this.name});

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(id: json['id'] ?? 0, name: json['Name'] ?? '');
  }
}

class CapacityUnit {
  final int id;
  final String name;

  CapacityUnit({required this.id, required this.name});

  factory CapacityUnit.fromJson(Map<String, dynamic> json) {
    return CapacityUnit(id: json['id'] ?? 0, name: json['Name'] ?? '');
  }
}

class Customer {
  final int id;
  final String name;
  final String isAdmin;

  Customer({required this.id, required this.name, required this.isAdmin});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      name: json['Name'] ?? '',
      isAdmin: json['is_admin']?.toString() ?? '0',
    );
  }
}
