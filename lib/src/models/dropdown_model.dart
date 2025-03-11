import 'package:freezed_annotation/freezed_annotation.dart';

part 'dropdown_model.freezed.dart';
part 'dropdown_model.g.dart';

@freezed
abstract class DropdownModel with _$DropdownModel {
  const factory DropdownModel({
    int? StatusCode,
    String? Message,
    bool? IsSuccess,
    DropdownData? Data,
  }) = _DropdownModel;

  factory DropdownModel.fromJson(Map<String, dynamic> json) =>
      _$DropdownModelFromJson(json);
}

@freezed
abstract class DropdownData with _$DropdownData {
  const factory DropdownData({
    List<VehicleType>? vehicle_type,
    List<Unit>? unit,
  }) = _DropdownData;

  factory DropdownData.fromJson(Map<String, dynamic> json) =>
      _$DropdownDataFromJson(json);
}

@freezed
abstract class VehicleType with _$VehicleType {
  const factory VehicleType({int? id, String? Name}) = _VehicleType;

  factory VehicleType.fromJson(Map<String, dynamic> json) =>
      _$VehicleTypeFromJson(json);
}

@freezed
abstract class Unit with _$Unit {
  const factory Unit({int? id, String? Name}) = _Unit;

  factory Unit.fromJson(Map<String, dynamic> json) => _$UnitFromJson(json);
}

@freezed
abstract class Customer with _$Customer {
  const factory Customer({int? id, String? Name}) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}
