// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dropdown_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DropdownModel {

 int? get StatusCode; String? get Message; bool? get IsSuccess; DropdownData? get Data;
/// Create a copy of DropdownModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DropdownModelCopyWith<DropdownModel> get copyWith => _$DropdownModelCopyWithImpl<DropdownModel>(this as DropdownModel, _$identity);

  /// Serializes this DropdownModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DropdownModel&&(identical(other.StatusCode, StatusCode) || other.StatusCode == StatusCode)&&(identical(other.Message, Message) || other.Message == Message)&&(identical(other.IsSuccess, IsSuccess) || other.IsSuccess == IsSuccess)&&(identical(other.Data, Data) || other.Data == Data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,StatusCode,Message,IsSuccess,Data);

@override
String toString() {
  return 'DropdownModel(StatusCode: $StatusCode, Message: $Message, IsSuccess: $IsSuccess, Data: $Data)';
}


}

/// @nodoc
abstract mixin class $DropdownModelCopyWith<$Res>  {
  factory $DropdownModelCopyWith(DropdownModel value, $Res Function(DropdownModel) _then) = _$DropdownModelCopyWithImpl;
@useResult
$Res call({
 int? StatusCode, String? Message, bool? IsSuccess, DropdownData? Data
});


$DropdownDataCopyWith<$Res>? get Data;

}
/// @nodoc
class _$DropdownModelCopyWithImpl<$Res>
    implements $DropdownModelCopyWith<$Res> {
  _$DropdownModelCopyWithImpl(this._self, this._then);

  final DropdownModel _self;
  final $Res Function(DropdownModel) _then;

/// Create a copy of DropdownModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? StatusCode = freezed,Object? Message = freezed,Object? IsSuccess = freezed,Object? Data = freezed,}) {
  return _then(_self.copyWith(
StatusCode: freezed == StatusCode ? _self.StatusCode : StatusCode // ignore: cast_nullable_to_non_nullable
as int?,Message: freezed == Message ? _self.Message : Message // ignore: cast_nullable_to_non_nullable
as String?,IsSuccess: freezed == IsSuccess ? _self.IsSuccess : IsSuccess // ignore: cast_nullable_to_non_nullable
as bool?,Data: freezed == Data ? _self.Data : Data // ignore: cast_nullable_to_non_nullable
as DropdownData?,
  ));
}
/// Create a copy of DropdownModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DropdownDataCopyWith<$Res>? get Data {
    if (_self.Data == null) {
    return null;
  }

  return $DropdownDataCopyWith<$Res>(_self.Data!, (value) {
    return _then(_self.copyWith(Data: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _DropdownModel implements DropdownModel {
  const _DropdownModel({this.StatusCode, this.Message, this.IsSuccess, this.Data});
  factory _DropdownModel.fromJson(Map<String, dynamic> json) => _$DropdownModelFromJson(json);

@override final  int? StatusCode;
@override final  String? Message;
@override final  bool? IsSuccess;
@override final  DropdownData? Data;

/// Create a copy of DropdownModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DropdownModelCopyWith<_DropdownModel> get copyWith => __$DropdownModelCopyWithImpl<_DropdownModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DropdownModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DropdownModel&&(identical(other.StatusCode, StatusCode) || other.StatusCode == StatusCode)&&(identical(other.Message, Message) || other.Message == Message)&&(identical(other.IsSuccess, IsSuccess) || other.IsSuccess == IsSuccess)&&(identical(other.Data, Data) || other.Data == Data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,StatusCode,Message,IsSuccess,Data);

@override
String toString() {
  return 'DropdownModel(StatusCode: $StatusCode, Message: $Message, IsSuccess: $IsSuccess, Data: $Data)';
}


}

/// @nodoc
abstract mixin class _$DropdownModelCopyWith<$Res> implements $DropdownModelCopyWith<$Res> {
  factory _$DropdownModelCopyWith(_DropdownModel value, $Res Function(_DropdownModel) _then) = __$DropdownModelCopyWithImpl;
@override @useResult
$Res call({
 int? StatusCode, String? Message, bool? IsSuccess, DropdownData? Data
});


@override $DropdownDataCopyWith<$Res>? get Data;

}
/// @nodoc
class __$DropdownModelCopyWithImpl<$Res>
    implements _$DropdownModelCopyWith<$Res> {
  __$DropdownModelCopyWithImpl(this._self, this._then);

  final _DropdownModel _self;
  final $Res Function(_DropdownModel) _then;

/// Create a copy of DropdownModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? StatusCode = freezed,Object? Message = freezed,Object? IsSuccess = freezed,Object? Data = freezed,}) {
  return _then(_DropdownModel(
StatusCode: freezed == StatusCode ? _self.StatusCode : StatusCode // ignore: cast_nullable_to_non_nullable
as int?,Message: freezed == Message ? _self.Message : Message // ignore: cast_nullable_to_non_nullable
as String?,IsSuccess: freezed == IsSuccess ? _self.IsSuccess : IsSuccess // ignore: cast_nullable_to_non_nullable
as bool?,Data: freezed == Data ? _self.Data : Data // ignore: cast_nullable_to_non_nullable
as DropdownData?,
  ));
}

/// Create a copy of DropdownModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DropdownDataCopyWith<$Res>? get Data {
    if (_self.Data == null) {
    return null;
  }

  return $DropdownDataCopyWith<$Res>(_self.Data!, (value) {
    return _then(_self.copyWith(Data: value));
  });
}
}


/// @nodoc
mixin _$DropdownData {

 List<VehicleType>? get vehicle_type; List<Unit>? get unit;
/// Create a copy of DropdownData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DropdownDataCopyWith<DropdownData> get copyWith => _$DropdownDataCopyWithImpl<DropdownData>(this as DropdownData, _$identity);

  /// Serializes this DropdownData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DropdownData&&const DeepCollectionEquality().equals(other.vehicle_type, vehicle_type)&&const DeepCollectionEquality().equals(other.unit, unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(vehicle_type),const DeepCollectionEquality().hash(unit));

@override
String toString() {
  return 'DropdownData(vehicle_type: $vehicle_type, unit: $unit)';
}


}

/// @nodoc
abstract mixin class $DropdownDataCopyWith<$Res>  {
  factory $DropdownDataCopyWith(DropdownData value, $Res Function(DropdownData) _then) = _$DropdownDataCopyWithImpl;
@useResult
$Res call({
 List<VehicleType>? vehicle_type, List<Unit>? unit
});




}
/// @nodoc
class _$DropdownDataCopyWithImpl<$Res>
    implements $DropdownDataCopyWith<$Res> {
  _$DropdownDataCopyWithImpl(this._self, this._then);

  final DropdownData _self;
  final $Res Function(DropdownData) _then;

/// Create a copy of DropdownData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vehicle_type = freezed,Object? unit = freezed,}) {
  return _then(_self.copyWith(
vehicle_type: freezed == vehicle_type ? _self.vehicle_type : vehicle_type // ignore: cast_nullable_to_non_nullable
as List<VehicleType>?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as List<Unit>?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _DropdownData implements DropdownData {
  const _DropdownData({final  List<VehicleType>? vehicle_type, final  List<Unit>? unit}): _vehicle_type = vehicle_type,_unit = unit;
  factory _DropdownData.fromJson(Map<String, dynamic> json) => _$DropdownDataFromJson(json);

 final  List<VehicleType>? _vehicle_type;
@override List<VehicleType>? get vehicle_type {
  final value = _vehicle_type;
  if (value == null) return null;
  if (_vehicle_type is EqualUnmodifiableListView) return _vehicle_type;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<Unit>? _unit;
@override List<Unit>? get unit {
  final value = _unit;
  if (value == null) return null;
  if (_unit is EqualUnmodifiableListView) return _unit;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of DropdownData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DropdownDataCopyWith<_DropdownData> get copyWith => __$DropdownDataCopyWithImpl<_DropdownData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DropdownDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DropdownData&&const DeepCollectionEquality().equals(other._vehicle_type, _vehicle_type)&&const DeepCollectionEquality().equals(other._unit, _unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_vehicle_type),const DeepCollectionEquality().hash(_unit));

@override
String toString() {
  return 'DropdownData(vehicle_type: $vehicle_type, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$DropdownDataCopyWith<$Res> implements $DropdownDataCopyWith<$Res> {
  factory _$DropdownDataCopyWith(_DropdownData value, $Res Function(_DropdownData) _then) = __$DropdownDataCopyWithImpl;
@override @useResult
$Res call({
 List<VehicleType>? vehicle_type, List<Unit>? unit
});




}
/// @nodoc
class __$DropdownDataCopyWithImpl<$Res>
    implements _$DropdownDataCopyWith<$Res> {
  __$DropdownDataCopyWithImpl(this._self, this._then);

  final _DropdownData _self;
  final $Res Function(_DropdownData) _then;

/// Create a copy of DropdownData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vehicle_type = freezed,Object? unit = freezed,}) {
  return _then(_DropdownData(
vehicle_type: freezed == vehicle_type ? _self._vehicle_type : vehicle_type // ignore: cast_nullable_to_non_nullable
as List<VehicleType>?,unit: freezed == unit ? _self._unit : unit // ignore: cast_nullable_to_non_nullable
as List<Unit>?,
  ));
}


}


/// @nodoc
mixin _$VehicleType {

 int? get id; String? get Name;
/// Create a copy of VehicleType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleTypeCopyWith<VehicleType> get copyWith => _$VehicleTypeCopyWithImpl<VehicleType>(this as VehicleType, _$identity);

  /// Serializes this VehicleType to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VehicleType&&(identical(other.id, id) || other.id == id)&&(identical(other.Name, Name) || other.Name == Name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,Name);

@override
String toString() {
  return 'VehicleType(id: $id, Name: $Name)';
}


}

/// @nodoc
abstract mixin class $VehicleTypeCopyWith<$Res>  {
  factory $VehicleTypeCopyWith(VehicleType value, $Res Function(VehicleType) _then) = _$VehicleTypeCopyWithImpl;
@useResult
$Res call({
 int? id, String? Name
});




}
/// @nodoc
class _$VehicleTypeCopyWithImpl<$Res>
    implements $VehicleTypeCopyWith<$Res> {
  _$VehicleTypeCopyWithImpl(this._self, this._then);

  final VehicleType _self;
  final $Res Function(VehicleType) _then;

/// Create a copy of VehicleType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? Name = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,Name: freezed == Name ? _self.Name : Name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _VehicleType implements VehicleType {
  const _VehicleType({this.id, this.Name});
  factory _VehicleType.fromJson(Map<String, dynamic> json) => _$VehicleTypeFromJson(json);

@override final  int? id;
@override final  String? Name;

/// Create a copy of VehicleType
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleTypeCopyWith<_VehicleType> get copyWith => __$VehicleTypeCopyWithImpl<_VehicleType>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleTypeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VehicleType&&(identical(other.id, id) || other.id == id)&&(identical(other.Name, Name) || other.Name == Name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,Name);

@override
String toString() {
  return 'VehicleType(id: $id, Name: $Name)';
}


}

/// @nodoc
abstract mixin class _$VehicleTypeCopyWith<$Res> implements $VehicleTypeCopyWith<$Res> {
  factory _$VehicleTypeCopyWith(_VehicleType value, $Res Function(_VehicleType) _then) = __$VehicleTypeCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? Name
});




}
/// @nodoc
class __$VehicleTypeCopyWithImpl<$Res>
    implements _$VehicleTypeCopyWith<$Res> {
  __$VehicleTypeCopyWithImpl(this._self, this._then);

  final _VehicleType _self;
  final $Res Function(_VehicleType) _then;

/// Create a copy of VehicleType
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? Name = freezed,}) {
  return _then(_VehicleType(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,Name: freezed == Name ? _self.Name : Name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Unit {

 int? get id; String? get Name;
/// Create a copy of Unit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitCopyWith<Unit> get copyWith => _$UnitCopyWithImpl<Unit>(this as Unit, _$identity);

  /// Serializes this Unit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Unit&&(identical(other.id, id) || other.id == id)&&(identical(other.Name, Name) || other.Name == Name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,Name);

@override
String toString() {
  return 'Unit(id: $id, Name: $Name)';
}


}

/// @nodoc
abstract mixin class $UnitCopyWith<$Res>  {
  factory $UnitCopyWith(Unit value, $Res Function(Unit) _then) = _$UnitCopyWithImpl;
@useResult
$Res call({
 int? id, String? Name
});




}
/// @nodoc
class _$UnitCopyWithImpl<$Res>
    implements $UnitCopyWith<$Res> {
  _$UnitCopyWithImpl(this._self, this._then);

  final Unit _self;
  final $Res Function(Unit) _then;

/// Create a copy of Unit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? Name = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,Name: freezed == Name ? _self.Name : Name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Unit implements Unit {
  const _Unit({this.id, this.Name});
  factory _Unit.fromJson(Map<String, dynamic> json) => _$UnitFromJson(json);

@override final  int? id;
@override final  String? Name;

/// Create a copy of Unit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnitCopyWith<_Unit> get copyWith => __$UnitCopyWithImpl<_Unit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Unit&&(identical(other.id, id) || other.id == id)&&(identical(other.Name, Name) || other.Name == Name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,Name);

@override
String toString() {
  return 'Unit(id: $id, Name: $Name)';
}


}

/// @nodoc
abstract mixin class _$UnitCopyWith<$Res> implements $UnitCopyWith<$Res> {
  factory _$UnitCopyWith(_Unit value, $Res Function(_Unit) _then) = __$UnitCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? Name
});




}
/// @nodoc
class __$UnitCopyWithImpl<$Res>
    implements _$UnitCopyWith<$Res> {
  __$UnitCopyWithImpl(this._self, this._then);

  final _Unit _self;
  final $Res Function(_Unit) _then;

/// Create a copy of Unit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? Name = freezed,}) {
  return _then(_Unit(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,Name: freezed == Name ? _self.Name : Name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Customer {

 int? get id; String? get Name;
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
 int? id, String? Name
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? Name = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,Name: freezed == Name ? _self.Name : Name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Customer implements Customer {
  const _Customer({this.id, this.Name});
  factory _Customer.fromJson(Map<String, dynamic> json) => _$CustomerFromJson(json);

@override final  int? id;
@override final  String? Name;

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
 int? id, String? Name
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? Name = freezed,}) {
  return _then(_Customer(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,Name: freezed == Name ? _self.Name : Name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
