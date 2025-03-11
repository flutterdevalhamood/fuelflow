import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_model.freezed.dart';
part 'vehicle_model.g.dart';

@freezed
abstract class VehicleModel with _$VehicleModel {
  const factory VehicleModel({
    int? StatusCode,
    String? Message,
    bool? IsSuccess,
    List<VehicleData>? Data,
  }) = _VehicleModel;

  factory VehicleModel.fromJson(Map<String, dynamic> json) =>
      _$VehicleModelFromJson(json);
}

@freezed
abstract class VehicleData with _$VehicleData {
  const factory VehicleData({
    int? id,
    String? plate_no,
    int? vehicle_type_id,
    String? capacity,
    int? capacity_unit_id,
    String? description,
    int? customer_id,
    VehicleType? type,
    VehicleCapacityUnit? vehicle_capacity_unit,
    Customer? customer,
  }) = _VehicleData;

  factory VehicleData.fromJson(Map<String, dynamic> json) =>
      _$VehicleDataFromJson(json);
}

@freezed
abstract class Customer with _$Customer {
  const factory Customer({int? id, String? Name}) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}

@freezed
abstract class VehicleType with _$VehicleType {
  const factory VehicleType({int? id, String? Name}) = _VehicleType;

  factory VehicleType.fromJson(Map<String, dynamic> json) =>
      _$VehicleTypeFromJson(json);
}

@freezed
abstract class VehicleCapacityUnit with _$VehicleCapacityUnit {
  const factory VehicleCapacityUnit({int? id, String? Name}) =
      _VehicleCapacityUnit;

  factory VehicleCapacityUnit.fromJson(Map<String, dynamic> json) =>
      _$VehicleCapacityUnitFromJson(json);
}
