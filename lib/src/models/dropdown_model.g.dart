// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dropdown_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DropdownModel _$DropdownModelFromJson(Map<String, dynamic> json) =>
    _DropdownModel(
      StatusCode: (json['StatusCode'] as num?)?.toInt(),
      Message: json['Message'] as String?,
      IsSuccess: json['IsSuccess'] as bool?,
      Data:
          json['Data'] == null
              ? null
              : DropdownData.fromJson(json['Data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DropdownModelToJson(_DropdownModel instance) =>
    <String, dynamic>{
      'StatusCode': instance.StatusCode,
      'Message': instance.Message,
      'IsSuccess': instance.IsSuccess,
      'Data': instance.Data,
    };

_DropdownData _$DropdownDataFromJson(Map<String, dynamic> json) =>
    _DropdownData(
      vehicle_type:
          (json['vehicle_type'] as List<dynamic>?)
              ?.map((e) => VehicleType.fromJson(e as Map<String, dynamic>))
              .toList(),
      unit:
          (json['unit'] as List<dynamic>?)
              ?.map((e) => Unit.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$DropdownDataToJson(_DropdownData instance) =>
    <String, dynamic>{
      'vehicle_type': instance.vehicle_type,
      'unit': instance.unit,
    };

_VehicleType _$VehicleTypeFromJson(Map<String, dynamic> json) => _VehicleType(
  id: (json['id'] as num?)?.toInt(),
  Name: json['Name'] as String?,
);

Map<String, dynamic> _$VehicleTypeToJson(_VehicleType instance) =>
    <String, dynamic>{'id': instance.id, 'Name': instance.Name};

_Unit _$UnitFromJson(Map<String, dynamic> json) =>
    _Unit(id: (json['id'] as num?)?.toInt(), Name: json['Name'] as String?);

Map<String, dynamic> _$UnitToJson(_Unit instance) => <String, dynamic>{
  'id': instance.id,
  'Name': instance.Name,
};

_Customer _$CustomerFromJson(Map<String, dynamic> json) =>
    _Customer(id: (json['id'] as num?)?.toInt(), Name: json['Name'] as String?);

Map<String, dynamic> _$CustomerToJson(_Customer instance) => <String, dynamic>{
  'id': instance.id,
  'Name': instance.Name,
};
