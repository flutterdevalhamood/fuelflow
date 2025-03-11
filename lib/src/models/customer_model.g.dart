// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Customer _$CustomerFromJson(Map<String, dynamic> json) => _Customer(
  id: (json['id'] as num?)?.toInt(),
  Name: json['Name'] as String?,
  mobile: json['mobile'] as String?,
  representative: json['representative'] as String?,
  email: json['email'] as String?,
);

Map<String, dynamic> _$CustomerToJson(_Customer instance) => <String, dynamic>{
  'id': instance.id,
  'Name': instance.Name,
  'mobile': instance.mobile,
  'representative': instance.representative,
  'email': instance.email,
};
