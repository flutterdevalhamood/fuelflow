import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    bool? IsSuccess,
    UserData? Data,
    String? Token,
    dynamic? UserPrivileges,
    int? StatusCode,
    String? Message,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

@freezed
abstract class UserData with _$UserData {
  const factory UserData({
    int? id,
    String? name,
    String? role_id,
    String? email,
    String? imageUrl,
    String? isActive,
    Roles? roles,
    Customer? customer,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
}

@freezed
abstract class Roles with _$Roles {
  const factory Roles({required int id, required String Name}) = _Roles;

  factory Roles.fromJson(Map<String, dynamic> json) => _$RolesFromJson(json);
}

@freezed
abstract class Customer with _$Customer {
  const factory Customer({required int id, required String Name}) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}
