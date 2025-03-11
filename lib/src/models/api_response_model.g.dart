// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApiResponse _$ApiResponseFromJson(Map<String, dynamic> json) => _ApiResponse(
  StatusCode: (json['StatusCode'] as num?)?.toInt(),
  Message: json['Message'] as String?,
  IsSuccess: json['IsSuccess'] as bool?,
  Data:
      (json['Data'] as List<dynamic>?)
          ?.map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$ApiResponseToJson(_ApiResponse instance) =>
    <String, dynamic>{
      'StatusCode': instance.StatusCode,
      'Message': instance.Message,
      'IsSuccess': instance.IsSuccess,
      'Data': instance.Data,
    };
