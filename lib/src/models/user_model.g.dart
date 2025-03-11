// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  IsSuccess: json['IsSuccess'] as bool?,
  Data:
      json['Data'] == null
          ? null
          : UserData.fromJson(json['Data'] as Map<String, dynamic>),
  Token: json['Token'] as String?,
  UserPrivileges: json['UserPrivileges'],
  StatusCode: (json['StatusCode'] as num?)?.toInt(),
  Message: json['Message'] as String?,
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'IsSuccess': instance.IsSuccess,
      'Data': instance.Data,
      'Token': instance.Token,
      'UserPrivileges': instance.UserPrivileges,
      'StatusCode': instance.StatusCode,
      'Message': instance.Message,
    };

_UserData _$UserDataFromJson(Map<String, dynamic> json) => _UserData(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  role_id: (json['role_id'] as num?)?.toInt(),
  email: json['email'] as String?,
  imageUrl: json['imageUrl'] as String?,
  isActive: (json['isActive'] as num?)?.toInt(),
  roles:
      json['roles'] == null
          ? null
          : Roles.fromJson(json['roles'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserDataToJson(_UserData instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'role_id': instance.role_id,
  'email': instance.email,
  'imageUrl': instance.imageUrl,
  'isActive': instance.isActive,
  'roles': instance.roles,
};

_Roles _$RolesFromJson(Map<String, dynamic> json) =>
    _Roles(id: (json['id'] as num).toInt(), Name: json['Name'] as String);

Map<String, dynamic> _$RolesToJson(_Roles instance) => <String, dynamic>{
  'id': instance.id,
  'Name': instance.Name,
};
