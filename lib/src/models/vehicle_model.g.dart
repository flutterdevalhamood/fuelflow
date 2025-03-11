// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VehicleModel _$VehicleModelFromJson(Map<String, dynamic> json) =>
    _VehicleModel(
      StatusCode: (json['StatusCode'] as num?)?.toInt(),
      Message: json['Message'] as String?,
      IsSuccess: json['IsSuccess'] as bool?,
      Data:
          (json['Data'] as List<dynamic>?)
              ?.map((e) => VehicleData.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$VehicleModelToJson(_VehicleModel instance) =>
    <String, dynamic>{
      'StatusCode': instance.StatusCode,
      'Message': instance.Message,
      'IsSuccess': instance.IsSuccess,
      'Data': instance.Data,
    };

_VehicleData _$VehicleDataFromJson(Map<String, dynamic> json) => _VehicleData(
  id: (json['id'] as num?)?.toInt(),
  plate_no: json['plate_no'] as String?,
  vehicle_type_id: (json['vehicle_type_id'] as num?)?.toInt(),
  capacity: json['capacity'] as String?,
  capacity_unit_id: (json['capacity_unit_id'] as num?)?.toInt(),
  description: json['description'] as String?,
  customer_id: (json['customer_id'] as num?)?.toInt(),
  user_id: (json['user_id'] as num?)?.toInt(),
  updated_at: json['updated_at'] as String?,
  type:
      json['type'] == null
          ? null
          : VehicleType.fromJson(json['type'] as Map<String, dynamic>),
  vehicle_capacity_unit:
      json['vehicle_capacity_unit'] == null
          ? null
          : VehicleCapacityUnit.fromJson(
            json['vehicle_capacity_unit'] as Map<String, dynamic>,
          ),
  customer:
      json['customer'] == null
          ? null
          : Customer.fromJson(json['customer'] as Map<String, dynamic>),
  user:
      json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
  vehicle_images:
      (json['vehicle_images'] as List<dynamic>?)
          ?.map((e) => VehicleImage.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$VehicleDataToJson(_VehicleData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'plate_no': instance.plate_no,
      'vehicle_type_id': instance.vehicle_type_id,
      'capacity': instance.capacity,
      'capacity_unit_id': instance.capacity_unit_id,
      'description': instance.description,
      'customer_id': instance.customer_id,
      'user_id': instance.user_id,
      'updated_at': instance.updated_at,
      'type': instance.type,
      'vehicle_capacity_unit': instance.vehicle_capacity_unit,
      'customer': instance.customer,
      'user': instance.user,
      'vehicle_images': instance.vehicle_images,
    };

_Customer _$CustomerFromJson(Map<String, dynamic> json) =>
    _Customer(id: (json['id'] as num?)?.toInt(), Name: json['Name'] as String?);

Map<String, dynamic> _$CustomerToJson(_Customer instance) => <String, dynamic>{
  'id': instance.id,
  'Name': instance.Name,
};

_VehicleType _$VehicleTypeFromJson(Map<String, dynamic> json) => _VehicleType(
  id: (json['id'] as num?)?.toInt(),
  Name: json['Name'] as String?,
);

Map<String, dynamic> _$VehicleTypeToJson(_VehicleType instance) =>
    <String, dynamic>{'id': instance.id, 'Name': instance.Name};

_VehicleCapacityUnit _$VehicleCapacityUnitFromJson(Map<String, dynamic> json) =>
    _VehicleCapacityUnit(
      id: (json['id'] as num?)?.toInt(),
      Name: json['Name'] as String?,
    );

Map<String, dynamic> _$VehicleCapacityUnitToJson(
  _VehicleCapacityUnit instance,
) => <String, dynamic>{'id': instance.id, 'Name': instance.Name};

_User _$UserFromJson(Map<String, dynamic> json) =>
    _User(id: (json['id'] as num?)?.toInt(), name: json['name'] as String?);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

_VehicleImage _$VehicleImageFromJson(Map<String, dynamic> json) =>
    _VehicleImage(
      id: (json['id'] as num?)?.toInt(),
      Title: json['Title'] as String?,
      RelationId: (json['RelationId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$VehicleImageToJson(_VehicleImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'Title': instance.Title,
      'RelationId': instance.RelationId,
    };
