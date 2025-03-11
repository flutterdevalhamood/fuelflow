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
    int? user_id,
    String? updated_at,
    VehicleType? type,
    VehicleCapacityUnit? vehicle_capacity_unit,
    Customer? customer,
    User? user,
    List<VehicleImage>? vehicle_images,
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

@freezed
abstract class User with _$User {
  const factory User({int? id, String? name}) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
abstract class VehicleImage with _$VehicleImage {
  const factory VehicleImage({int? id, String? Title, int? RelationId}) =
      _VehicleImage;

  factory VehicleImage.fromJson(Map<String, dynamic> json) =>
      _$VehicleImageFromJson(json);
}
