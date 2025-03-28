// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserModel {

 bool? get IsSuccess; UserData? get Data; String? get Token; dynamic? get UserPrivileges; int? get StatusCode; String? get Message;
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserModelCopyWith<UserModel> get copyWith => _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserModel&&(identical(other.IsSuccess, IsSuccess) || other.IsSuccess == IsSuccess)&&(identical(other.Data, Data) || other.Data == Data)&&(identical(other.Token, Token) || other.Token == Token)&&const DeepCollectionEquality().equals(other.UserPrivileges, UserPrivileges)&&(identical(other.StatusCode, StatusCode) || other.StatusCode == StatusCode)&&(identical(other.Message, Message) || other.Message == Message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,IsSuccess,Data,Token,const DeepCollectionEquality().hash(UserPrivileges),StatusCode,Message);

@override
String toString() {
  return 'UserModel(IsSuccess: $IsSuccess, Data: $Data, Token: $Token, UserPrivileges: $UserPrivileges, StatusCode: $StatusCode, Message: $Message)';
}


}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res>  {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) = _$UserModelCopyWithImpl;
@useResult
$Res call({
 bool? IsSuccess, UserData? Data, String? Token, dynamic? UserPrivileges, int? StatusCode, String? Message
});


$UserDataCopyWith<$Res>? get Data;

}
/// @nodoc
class _$UserModelCopyWithImpl<$Res>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? IsSuccess = freezed,Object? Data = freezed,Object? Token = freezed,Object? UserPrivileges = freezed,Object? StatusCode = freezed,Object? Message = freezed,}) {
  return _then(_self.copyWith(
IsSuccess: freezed == IsSuccess ? _self.IsSuccess : IsSuccess // ignore: cast_nullable_to_non_nullable
as bool?,Data: freezed == Data ? _self.Data : Data // ignore: cast_nullable_to_non_nullable
as UserData?,Token: freezed == Token ? _self.Token : Token // ignore: cast_nullable_to_non_nullable
as String?,UserPrivileges: freezed == UserPrivileges ? _self.UserPrivileges : UserPrivileges // ignore: cast_nullable_to_non_nullable
as dynamic?,StatusCode: freezed == StatusCode ? _self.StatusCode : StatusCode // ignore: cast_nullable_to_non_nullable
as int?,Message: freezed == Message ? _self.Message : Message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserDataCopyWith<$Res>? get Data {
    if (_self.Data == null) {
    return null;
  }

  return $UserDataCopyWith<$Res>(_self.Data!, (value) {
    return _then(_self.copyWith(Data: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _UserModel implements UserModel {
  const _UserModel({this.IsSuccess, this.Data, this.Token, this.UserPrivileges, this.StatusCode, this.Message});
  factory _UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

@override final  bool? IsSuccess;
@override final  UserData? Data;
@override final  String? Token;
@override final  dynamic? UserPrivileges;
@override final  int? StatusCode;
@override final  String? Message;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserModelCopyWith<_UserModel> get copyWith => __$UserModelCopyWithImpl<_UserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserModel&&(identical(other.IsSuccess, IsSuccess) || other.IsSuccess == IsSuccess)&&(identical(other.Data, Data) || other.Data == Data)&&(identical(other.Token, Token) || other.Token == Token)&&const DeepCollectionEquality().equals(other.UserPrivileges, UserPrivileges)&&(identical(other.StatusCode, StatusCode) || other.StatusCode == StatusCode)&&(identical(other.Message, Message) || other.Message == Message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,IsSuccess,Data,Token,const DeepCollectionEquality().hash(UserPrivileges),StatusCode,Message);

@override
String toString() {
  return 'UserModel(IsSuccess: $IsSuccess, Data: $Data, Token: $Token, UserPrivileges: $UserPrivileges, StatusCode: $StatusCode, Message: $Message)';
}


}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res> implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(_UserModel value, $Res Function(_UserModel) _then) = __$UserModelCopyWithImpl;
@override @useResult
$Res call({
 bool? IsSuccess, UserData? Data, String? Token, dynamic? UserPrivileges, int? StatusCode, String? Message
});


@override $UserDataCopyWith<$Res>? get Data;

}
/// @nodoc
class __$UserModelCopyWithImpl<$Res>
    implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? IsSuccess = freezed,Object? Data = freezed,Object? Token = freezed,Object? UserPrivileges = freezed,Object? StatusCode = freezed,Object? Message = freezed,}) {
  return _then(_UserModel(
IsSuccess: freezed == IsSuccess ? _self.IsSuccess : IsSuccess // ignore: cast_nullable_to_non_nullable
as bool?,Data: freezed == Data ? _self.Data : Data // ignore: cast_nullable_to_non_nullable
as UserData?,Token: freezed == Token ? _self.Token : Token // ignore: cast_nullable_to_non_nullable
as String?,UserPrivileges: freezed == UserPrivileges ? _self.UserPrivileges : UserPrivileges // ignore: cast_nullable_to_non_nullable
as dynamic?,StatusCode: freezed == StatusCode ? _self.StatusCode : StatusCode // ignore: cast_nullable_to_non_nullable
as int?,Message: freezed == Message ? _self.Message : Message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserDataCopyWith<$Res>? get Data {
    if (_self.Data == null) {
    return null;
  }

  return $UserDataCopyWith<$Res>(_self.Data!, (value) {
    return _then(_self.copyWith(Data: value));
  });
}
}


/// @nodoc
mixin _$UserData {

 int? get id; String? get name; int? get role_id; String? get email; String? get imageUrl; int? get isActive; Roles? get roles; Customer? get customer;
/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDataCopyWith<UserData> get copyWith => _$UserDataCopyWithImpl<UserData>(this as UserData, _$identity);

  /// Serializes this UserData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserData&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.role_id, role_id) || other.role_id == role_id)&&(identical(other.email, email) || other.email == email)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.roles, roles) || other.roles == roles)&&(identical(other.customer, customer) || other.customer == customer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,role_id,email,imageUrl,isActive,roles,customer);

@override
String toString() {
  return 'UserData(id: $id, name: $name, role_id: $role_id, email: $email, imageUrl: $imageUrl, isActive: $isActive, roles: $roles, customer: $customer)';
}


}

/// @nodoc
abstract mixin class $UserDataCopyWith<$Res>  {
  factory $UserDataCopyWith(UserData value, $Res Function(UserData) _then) = _$UserDataCopyWithImpl;
@useResult
$Res call({
 int? id, String? name, int? role_id, String? email, String? imageUrl, int? isActive, Roles? roles, Customer? customer
});


$RolesCopyWith<$Res>? get roles;$CustomerCopyWith<$Res>? get customer;

}
/// @nodoc
class _$UserDataCopyWithImpl<$Res>
    implements $UserDataCopyWith<$Res> {
  _$UserDataCopyWithImpl(this._self, this._then);

  final UserData _self;
  final $Res Function(UserData) _then;

/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = freezed,Object? role_id = freezed,Object? email = freezed,Object? imageUrl = freezed,Object? isActive = freezed,Object? roles = freezed,Object? customer = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,role_id: freezed == role_id ? _self.role_id : role_id // ignore: cast_nullable_to_non_nullable
as int?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as int?,roles: freezed == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as Roles?,customer: freezed == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as Customer?,
  ));
}
/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RolesCopyWith<$Res>? get roles {
    if (_self.roles == null) {
    return null;
  }

  return $RolesCopyWith<$Res>(_self.roles!, (value) {
    return _then(_self.copyWith(roles: value));
  });
}/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerCopyWith<$Res>? get customer {
    if (_self.customer == null) {
    return null;
  }

  return $CustomerCopyWith<$Res>(_self.customer!, (value) {
    return _then(_self.copyWith(customer: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _UserData implements UserData {
  const _UserData({this.id, this.name, this.role_id, this.email, this.imageUrl, this.isActive, this.roles, this.customer});
  factory _UserData.fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);

@override final  int? id;
@override final  String? name;
@override final  int? role_id;
@override final  String? email;
@override final  String? imageUrl;
@override final  int? isActive;
@override final  Roles? roles;
@override final  Customer? customer;

/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserDataCopyWith<_UserData> get copyWith => __$UserDataCopyWithImpl<_UserData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserData&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.role_id, role_id) || other.role_id == role_id)&&(identical(other.email, email) || other.email == email)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.roles, roles) || other.roles == roles)&&(identical(other.customer, customer) || other.customer == customer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,role_id,email,imageUrl,isActive,roles,customer);

@override
String toString() {
  return 'UserData(id: $id, name: $name, role_id: $role_id, email: $email, imageUrl: $imageUrl, isActive: $isActive, roles: $roles, customer: $customer)';
}


}

/// @nodoc
abstract mixin class _$UserDataCopyWith<$Res> implements $UserDataCopyWith<$Res> {
  factory _$UserDataCopyWith(_UserData value, $Res Function(_UserData) _then) = __$UserDataCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? name, int? role_id, String? email, String? imageUrl, int? isActive, Roles? roles, Customer? customer
});


@override $RolesCopyWith<$Res>? get roles;@override $CustomerCopyWith<$Res>? get customer;

}
/// @nodoc
class __$UserDataCopyWithImpl<$Res>
    implements _$UserDataCopyWith<$Res> {
  __$UserDataCopyWithImpl(this._self, this._then);

  final _UserData _self;
  final $Res Function(_UserData) _then;

/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = freezed,Object? role_id = freezed,Object? email = freezed,Object? imageUrl = freezed,Object? isActive = freezed,Object? roles = freezed,Object? customer = freezed,}) {
  return _then(_UserData(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,role_id: freezed == role_id ? _self.role_id : role_id // ignore: cast_nullable_to_non_nullable
as int?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as int?,roles: freezed == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as Roles?,customer: freezed == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as Customer?,
  ));
}

/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RolesCopyWith<$Res>? get roles {
    if (_self.roles == null) {
    return null;
  }

  return $RolesCopyWith<$Res>(_self.roles!, (value) {
    return _then(_self.copyWith(roles: value));
  });
}/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerCopyWith<$Res>? get customer {
    if (_self.customer == null) {
    return null;
  }

  return $CustomerCopyWith<$Res>(_self.customer!, (value) {
    return _then(_self.copyWith(customer: value));
  });
}
}


/// @nodoc
mixin _$Roles {

 int get id; String get Name;
/// Create a copy of Roles
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RolesCopyWith<Roles> get copyWith => _$RolesCopyWithImpl<Roles>(this as Roles, _$identity);

  /// Serializes this Roles to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Roles&&(identical(other.id, id) || other.id == id)&&(identical(other.Name, Name) || other.Name == Name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,Name);

@override
String toString() {
  return 'Roles(id: $id, Name: $Name)';
}


}

/// @nodoc
abstract mixin class $RolesCopyWith<$Res>  {
  factory $RolesCopyWith(Roles value, $Res Function(Roles) _then) = _$RolesCopyWithImpl;
@useResult
$Res call({
 int id, String Name
});




}
/// @nodoc
class _$RolesCopyWithImpl<$Res>
    implements $RolesCopyWith<$Res> {
  _$RolesCopyWithImpl(this._self, this._then);

  final Roles _self;
  final $Res Function(Roles) _then;

/// Create a copy of Roles
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? Name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,Name: null == Name ? _self.Name : Name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Roles implements Roles {
  const _Roles({required this.id, required this.Name});
  factory _Roles.fromJson(Map<String, dynamic> json) => _$RolesFromJson(json);

@override final  int id;
@override final  String Name;

/// Create a copy of Roles
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RolesCopyWith<_Roles> get copyWith => __$RolesCopyWithImpl<_Roles>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RolesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Roles&&(identical(other.id, id) || other.id == id)&&(identical(other.Name, Name) || other.Name == Name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,Name);

@override
String toString() {
  return 'Roles(id: $id, Name: $Name)';
}


}

/// @nodoc
abstract mixin class _$RolesCopyWith<$Res> implements $RolesCopyWith<$Res> {
  factory _$RolesCopyWith(_Roles value, $Res Function(_Roles) _then) = __$RolesCopyWithImpl;
@override @useResult
$Res call({
 int id, String Name
});




}
/// @nodoc
class __$RolesCopyWithImpl<$Res>
    implements _$RolesCopyWith<$Res> {
  __$RolesCopyWithImpl(this._self, this._then);

  final _Roles _self;
  final $Res Function(_Roles) _then;

/// Create a copy of Roles
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? Name = null,}) {
  return _then(_Roles(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,Name: null == Name ? _self.Name : Name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Customer {

 int get id; String get Name;
/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerCopyWith<Customer> get copyWith => _$CustomerCopyWithImpl<Customer>(this as Customer, _$identity);

  /// Serializes this Customer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Customer&&(identical(other.id, id) || other.id == id)&&(identical(other.Name, Name) || other.Name == Name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,Name);

@override
String toString() {
  return 'Customer(id: $id, Name: $Name)';
}


}

/// @nodoc
abstract mixin class $CustomerCopyWith<$Res>  {
  factory $CustomerCopyWith(Customer value, $Res Function(Customer) _then) = _$CustomerCopyWithImpl;
@useResult
$Res call({
 int id, String Name
});




}
/// @nodoc
class _$CustomerCopyWithImpl<$Res>
    implements $CustomerCopyWith<$Res> {
  _$CustomerCopyWithImpl(this._self, this._then);

  final Customer _self;
  final $Res Function(Customer) _then;

/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? Name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,Name: null == Name ? _self.Name : Name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Customer implements Customer {
  const _Customer({required this.id, required this.Name});
  factory _Customer.fromJson(Map<String, dynamic> json) => _$CustomerFromJson(json);

@override final  int id;
@override final  String Name;

/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerCopyWith<_Customer> get copyWith => __$CustomerCopyWithImpl<_Customer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Customer&&(identical(other.id, id) || other.id == id)&&(identical(other.Name, Name) || other.Name == Name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,Name);

@override
String toString() {
  return 'Customer(id: $id, Name: $Name)';
}


}

/// @nodoc
abstract mixin class _$CustomerCopyWith<$Res> implements $CustomerCopyWith<$Res> {
  factory _$CustomerCopyWith(_Customer value, $Res Function(_Customer) _then) = __$CustomerCopyWithImpl;
@override @useResult
$Res call({
 int id, String Name
});




}
/// @nodoc
class __$CustomerCopyWithImpl<$Res>
    implements _$CustomerCopyWith<$Res> {
  __$CustomerCopyWithImpl(this._self, this._then);

  final _Customer _self;
  final $Res Function(_Customer) _then;

/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? Name = null,}) {
  return _then(_Customer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,Name: null == Name ? _self.Name : Name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
