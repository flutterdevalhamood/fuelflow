// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VehicleModel {

 int? get StatusCode; String? get Message; bool? get IsSuccess; List<VehicleData>? get Data;
/// Create a copy of VehicleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleModelCopyWith<VehicleModel> get copyWith => _$VehicleModelCopyWithImpl<VehicleModel>(this as VehicleModel, _$identity);

  /// Serializes this VehicleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VehicleModel&&(identical(other.StatusCode, StatusCode) || other.StatusCode == StatusCode)&&(identical(other.Message, Message) || other.Message == Message)&&(identical(other.IsSuccess, IsSuccess) || other.IsSuccess == IsSuccess)&&const DeepCollectionEquality().equals(other.Data, Data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,StatusCode,Message,IsSuccess,const DeepCollectionEquality().hash(Data));

@override
String toString() {
  return 'VehicleModel(StatusCode: $StatusCode, Message: $Message, IsSuccess: $IsSuccess, Data: $Data)';
}


}

/// @nodoc
abstract mixin class $VehicleModelCopyWith<$Res>  {
  factory $VehicleModelCopyWith(VehicleModel value, $Res Function(VehicleModel) _then) = _$VehicleModelCopyWithImpl;
@useResult
$Res call({
 int? StatusCode, String? Message, bool? IsSuccess, List<VehicleData>? Data
});




}
/// @nodoc
class _$VehicleModelCopyWithImpl<$Res>
    implements $VehicleModelCopyWith<$Res> {
  _$VehicleModelCopyWithImpl(this._self, this._then);

  final VehicleModel _self;
  final $Res Function(VehicleModel) _then;

/// Create a copy of VehicleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? StatusCode = freezed,Object? Message = freezed,Object? IsSuccess = freezed,Object? Data = freezed,}) {
  return _then(_self.copyWith(
StatusCode: freezed == StatusCode ? _self.StatusCode : StatusCode // ignore: cast_nullable_to_non_nullable
as int?,Message: freezed == Message ? _self.Message : Message // ignore: cast_nullable_to_non_nullable
as String?,IsSuccess: freezed == IsSuccess ? _self.IsSuccess : IsSuccess // ignore: cast_nullable_to_non_nullable
as bool?,Data: freezed == Data ? _self.Data : Data // ignore: cast_nullable_to_non_nullable
as List<VehicleData>?,
  ));
}

}


/// Adds pattern-matching-related methods to [VehicleModel].
extension VehicleModelPatterns on VehicleModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VehicleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VehicleModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VehicleModel value)  $default,){
final _that = this;
switch (_that) {
case _VehicleModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VehicleModel value)?  $default,){
final _that = this;
switch (_that) {
case _VehicleModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? StatusCode,  String? Message,  bool? IsSuccess,  List<VehicleData>? Data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VehicleModel() when $default != null:
return $default(_that.StatusCode,_that.Message,_that.IsSuccess,_that.Data);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? StatusCode,  String? Message,  bool? IsSuccess,  List<VehicleData>? Data)  $default,) {final _that = this;
switch (_that) {
case _VehicleModel():
return $default(_that.StatusCode,_that.Message,_that.IsSuccess,_that.Data);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? StatusCode,  String? Message,  bool? IsSuccess,  List<VehicleData>? Data)?  $default,) {final _that = this;
switch (_that) {
case _VehicleModel() when $default != null:
return $default(_that.StatusCode,_that.Message,_that.IsSuccess,_that.Data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VehicleModel implements VehicleModel {
  const _VehicleModel({this.StatusCode, this.Message, this.IsSuccess, final  List<VehicleData>? Data}): _Data = Data;
  factory _VehicleModel.fromJson(Map<String, dynamic> json) => _$VehicleModelFromJson(json);

@override final  int? StatusCode;
@override final  String? Message;
@override final  bool? IsSuccess;
 final  List<VehicleData>? _Data;
@override List<VehicleData>? get Data {
  final value = _Data;
  if (value == null) return null;
  if (_Data is EqualUnmodifiableListView) return _Data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of VehicleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleModelCopyWith<_VehicleModel> get copyWith => __$VehicleModelCopyWithImpl<_VehicleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VehicleModel&&(identical(other.StatusCode, StatusCode) || other.StatusCode == StatusCode)&&(identical(other.Message, Message) || other.Message == Message)&&(identical(other.IsSuccess, IsSuccess) || other.IsSuccess == IsSuccess)&&const DeepCollectionEquality().equals(other._Data, _Data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,StatusCode,Message,IsSuccess,const DeepCollectionEquality().hash(_Data));

@override
String toString() {
  return 'VehicleModel(StatusCode: $StatusCode, Message: $Message, IsSuccess: $IsSuccess, Data: $Data)';
}


}

/// @nodoc
abstract mixin class _$VehicleModelCopyWith<$Res> implements $VehicleModelCopyWith<$Res> {
  factory _$VehicleModelCopyWith(_VehicleModel value, $Res Function(_VehicleModel) _then) = __$VehicleModelCopyWithImpl;
@override @useResult
$Res call({
 int? StatusCode, String? Message, bool? IsSuccess, List<VehicleData>? Data
});




}
/// @nodoc
class __$VehicleModelCopyWithImpl<$Res>
    implements _$VehicleModelCopyWith<$Res> {
  __$VehicleModelCopyWithImpl(this._self, this._then);

  final _VehicleModel _self;
  final $Res Function(_VehicleModel) _then;

/// Create a copy of VehicleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? StatusCode = freezed,Object? Message = freezed,Object? IsSuccess = freezed,Object? Data = freezed,}) {
  return _then(_VehicleModel(
StatusCode: freezed == StatusCode ? _self.StatusCode : StatusCode // ignore: cast_nullable_to_non_nullable
as int?,Message: freezed == Message ? _self.Message : Message // ignore: cast_nullable_to_non_nullable
as String?,IsSuccess: freezed == IsSuccess ? _self.IsSuccess : IsSuccess // ignore: cast_nullable_to_non_nullable
as bool?,Data: freezed == Data ? _self._Data : Data // ignore: cast_nullable_to_non_nullable
as List<VehicleData>?,
  ));
}


}


/// @nodoc
mixin _$VehicleData {

 int? get id; String? get plate_no; int? get vehicle_type_id; String? get capacity; int? get capacity_unit_id; String? get description; int? get customer_id; int? get user_id; String? get updated_at; VehicleType? get type; VehicleCapacityUnit? get vehicle_capacity_unit; Customer? get customer; User? get user; List<VehicleImage>? get vehicle_images;
/// Create a copy of VehicleData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleDataCopyWith<VehicleData> get copyWith => _$VehicleDataCopyWithImpl<VehicleData>(this as VehicleData, _$identity);

  /// Serializes this VehicleData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VehicleData&&(identical(other.id, id) || other.id == id)&&(identical(other.plate_no, plate_no) || other.plate_no == plate_no)&&(identical(other.vehicle_type_id, vehicle_type_id) || other.vehicle_type_id == vehicle_type_id)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.capacity_unit_id, capacity_unit_id) || other.capacity_unit_id == capacity_unit_id)&&(identical(other.description, description) || other.description == description)&&(identical(other.customer_id, customer_id) || other.customer_id == customer_id)&&(identical(other.user_id, user_id) || other.user_id == user_id)&&(identical(other.updated_at, updated_at) || other.updated_at == updated_at)&&(identical(other.type, type) || other.type == type)&&(identical(other.vehicle_capacity_unit, vehicle_capacity_unit) || other.vehicle_capacity_unit == vehicle_capacity_unit)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.user, user) || other.user == user)&&const DeepCollectionEquality().equals(other.vehicle_images, vehicle_images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,plate_no,vehicle_type_id,capacity,capacity_unit_id,description,customer_id,user_id,updated_at,type,vehicle_capacity_unit,customer,user,const DeepCollectionEquality().hash(vehicle_images));

@override
String toString() {
  return 'VehicleData(id: $id, plate_no: $plate_no, vehicle_type_id: $vehicle_type_id, capacity: $capacity, capacity_unit_id: $capacity_unit_id, description: $description, customer_id: $customer_id, user_id: $user_id, updated_at: $updated_at, type: $type, vehicle_capacity_unit: $vehicle_capacity_unit, customer: $customer, user: $user, vehicle_images: $vehicle_images)';
}


}

/// @nodoc
abstract mixin class $VehicleDataCopyWith<$Res>  {
  factory $VehicleDataCopyWith(VehicleData value, $Res Function(VehicleData) _then) = _$VehicleDataCopyWithImpl;
@useResult
$Res call({
 int? id, String? plate_no, int? vehicle_type_id, String? capacity, int? capacity_unit_id, String? description, int? customer_id, int? user_id, String? updated_at, VehicleType? type, VehicleCapacityUnit? vehicle_capacity_unit, Customer? customer, User? user, List<VehicleImage>? vehicle_images
});


$VehicleTypeCopyWith<$Res>? get type;$VehicleCapacityUnitCopyWith<$Res>? get vehicle_capacity_unit;$CustomerCopyWith<$Res>? get customer;$UserCopyWith<$Res>? get user;

}
/// @nodoc
class _$VehicleDataCopyWithImpl<$Res>
    implements $VehicleDataCopyWith<$Res> {
  _$VehicleDataCopyWithImpl(this._self, this._then);

  final VehicleData _self;
  final $Res Function(VehicleData) _then;

/// Create a copy of VehicleData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? plate_no = freezed,Object? vehicle_type_id = freezed,Object? capacity = freezed,Object? capacity_unit_id = freezed,Object? description = freezed,Object? customer_id = freezed,Object? user_id = freezed,Object? updated_at = freezed,Object? type = freezed,Object? vehicle_capacity_unit = freezed,Object? customer = freezed,Object? user = freezed,Object? vehicle_images = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,plate_no: freezed == plate_no ? _self.plate_no : plate_no // ignore: cast_nullable_to_non_nullable
as String?,vehicle_type_id: freezed == vehicle_type_id ? _self.vehicle_type_id : vehicle_type_id // ignore: cast_nullable_to_non_nullable
as int?,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as String?,capacity_unit_id: freezed == capacity_unit_id ? _self.capacity_unit_id : capacity_unit_id // ignore: cast_nullable_to_non_nullable
as int?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,customer_id: freezed == customer_id ? _self.customer_id : customer_id // ignore: cast_nullable_to_non_nullable
as int?,user_id: freezed == user_id ? _self.user_id : user_id // ignore: cast_nullable_to_non_nullable
as int?,updated_at: freezed == updated_at ? _self.updated_at : updated_at // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as VehicleType?,vehicle_capacity_unit: freezed == vehicle_capacity_unit ? _self.vehicle_capacity_unit : vehicle_capacity_unit // ignore: cast_nullable_to_non_nullable
as VehicleCapacityUnit?,customer: freezed == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as Customer?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User?,vehicle_images: freezed == vehicle_images ? _self.vehicle_images : vehicle_images // ignore: cast_nullable_to_non_nullable
as List<VehicleImage>?,
  ));
}
/// Create a copy of VehicleData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VehicleTypeCopyWith<$Res>? get type {
    if (_self.type == null) {
    return null;
  }

  return $VehicleTypeCopyWith<$Res>(_self.type!, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of VehicleData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VehicleCapacityUnitCopyWith<$Res>? get vehicle_capacity_unit {
    if (_self.vehicle_capacity_unit == null) {
    return null;
  }

  return $VehicleCapacityUnitCopyWith<$Res>(_self.vehicle_capacity_unit!, (value) {
    return _then(_self.copyWith(vehicle_capacity_unit: value));
  });
}/// Create a copy of VehicleData
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
}/// Create a copy of VehicleData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [VehicleData].
extension VehicleDataPatterns on VehicleData {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VehicleData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VehicleData() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VehicleData value)  $default,){
final _that = this;
switch (_that) {
case _VehicleData():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VehicleData value)?  $default,){
final _that = this;
switch (_that) {
case _VehicleData() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? plate_no,  int? vehicle_type_id,  String? capacity,  int? capacity_unit_id,  String? description,  int? customer_id,  int? user_id,  String? updated_at,  VehicleType? type,  VehicleCapacityUnit? vehicle_capacity_unit,  Customer? customer,  User? user,  List<VehicleImage>? vehicle_images)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VehicleData() when $default != null:
return $default(_that.id,_that.plate_no,_that.vehicle_type_id,_that.capacity,_that.capacity_unit_id,_that.description,_that.customer_id,_that.user_id,_that.updated_at,_that.type,_that.vehicle_capacity_unit,_that.customer,_that.user,_that.vehicle_images);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? plate_no,  int? vehicle_type_id,  String? capacity,  int? capacity_unit_id,  String? description,  int? customer_id,  int? user_id,  String? updated_at,  VehicleType? type,  VehicleCapacityUnit? vehicle_capacity_unit,  Customer? customer,  User? user,  List<VehicleImage>? vehicle_images)  $default,) {final _that = this;
switch (_that) {
case _VehicleData():
return $default(_that.id,_that.plate_no,_that.vehicle_type_id,_that.capacity,_that.capacity_unit_id,_that.description,_that.customer_id,_that.user_id,_that.updated_at,_that.type,_that.vehicle_capacity_unit,_that.customer,_that.user,_that.vehicle_images);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? plate_no,  int? vehicle_type_id,  String? capacity,  int? capacity_unit_id,  String? description,  int? customer_id,  int? user_id,  String? updated_at,  VehicleType? type,  VehicleCapacityUnit? vehicle_capacity_unit,  Customer? customer,  User? user,  List<VehicleImage>? vehicle_images)?  $default,) {final _that = this;
switch (_that) {
case _VehicleData() when $default != null:
return $default(_that.id,_that.plate_no,_that.vehicle_type_id,_that.capacity,_that.capacity_unit_id,_that.description,_that.customer_id,_that.user_id,_that.updated_at,_that.type,_that.vehicle_capacity_unit,_that.customer,_that.user,_that.vehicle_images);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VehicleData implements VehicleData {
  const _VehicleData({this.id, this.plate_no, this.vehicle_type_id, this.capacity, this.capacity_unit_id, this.description, this.customer_id, this.user_id, this.updated_at, this.type, this.vehicle_capacity_unit, this.customer, this.user, final  List<VehicleImage>? vehicle_images}): _vehicle_images = vehicle_images;
  factory _VehicleData.fromJson(Map<String, dynamic> json) => _$VehicleDataFromJson(json);

@override final  int? id;
@override final  String? plate_no;
@override final  int? vehicle_type_id;
@override final  String? capacity;
@override final  int? capacity_unit_id;
@override final  String? description;
@override final  int? customer_id;
@override final  int? user_id;
@override final  String? updated_at;
@override final  VehicleType? type;
@override final  VehicleCapacityUnit? vehicle_capacity_unit;
@override final  Customer? customer;
@override final  User? user;
 final  List<VehicleImage>? _vehicle_images;
@override List<VehicleImage>? get vehicle_images {
  final value = _vehicle_images;
  if (value == null) return null;
  if (_vehicle_images is EqualUnmodifiableListView) return _vehicle_images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of VehicleData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleDataCopyWith<_VehicleData> get copyWith => __$VehicleDataCopyWithImpl<_VehicleData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VehicleData&&(identical(other.id, id) || other.id == id)&&(identical(other.plate_no, plate_no) || other.plate_no == plate_no)&&(identical(other.vehicle_type_id, vehicle_type_id) || other.vehicle_type_id == vehicle_type_id)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.capacity_unit_id, capacity_unit_id) || other.capacity_unit_id == capacity_unit_id)&&(identical(other.description, description) || other.description == description)&&(identical(other.customer_id, customer_id) || other.customer_id == customer_id)&&(identical(other.user_id, user_id) || other.user_id == user_id)&&(identical(other.updated_at, updated_at) || other.updated_at == updated_at)&&(identical(other.type, type) || other.type == type)&&(identical(other.vehicle_capacity_unit, vehicle_capacity_unit) || other.vehicle_capacity_unit == vehicle_capacity_unit)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.user, user) || other.user == user)&&const DeepCollectionEquality().equals(other._vehicle_images, _vehicle_images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,plate_no,vehicle_type_id,capacity,capacity_unit_id,description,customer_id,user_id,updated_at,type,vehicle_capacity_unit,customer,user,const DeepCollectionEquality().hash(_vehicle_images));

@override
String toString() {
  return 'VehicleData(id: $id, plate_no: $plate_no, vehicle_type_id: $vehicle_type_id, capacity: $capacity, capacity_unit_id: $capacity_unit_id, description: $description, customer_id: $customer_id, user_id: $user_id, updated_at: $updated_at, type: $type, vehicle_capacity_unit: $vehicle_capacity_unit, customer: $customer, user: $user, vehicle_images: $vehicle_images)';
}


}

/// @nodoc
abstract mixin class _$VehicleDataCopyWith<$Res> implements $VehicleDataCopyWith<$Res> {
  factory _$VehicleDataCopyWith(_VehicleData value, $Res Function(_VehicleData) _then) = __$VehicleDataCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? plate_no, int? vehicle_type_id, String? capacity, int? capacity_unit_id, String? description, int? customer_id, int? user_id, String? updated_at, VehicleType? type, VehicleCapacityUnit? vehicle_capacity_unit, Customer? customer, User? user, List<VehicleImage>? vehicle_images
});


@override $VehicleTypeCopyWith<$Res>? get type;@override $VehicleCapacityUnitCopyWith<$Res>? get vehicle_capacity_unit;@override $CustomerCopyWith<$Res>? get customer;@override $UserCopyWith<$Res>? get user;

}
/// @nodoc
class __$VehicleDataCopyWithImpl<$Res>
    implements _$VehicleDataCopyWith<$Res> {
  __$VehicleDataCopyWithImpl(this._self, this._then);

  final _VehicleData _self;
  final $Res Function(_VehicleData) _then;

/// Create a copy of VehicleData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? plate_no = freezed,Object? vehicle_type_id = freezed,Object? capacity = freezed,Object? capacity_unit_id = freezed,Object? description = freezed,Object? customer_id = freezed,Object? user_id = freezed,Object? updated_at = freezed,Object? type = freezed,Object? vehicle_capacity_unit = freezed,Object? customer = freezed,Object? user = freezed,Object? vehicle_images = freezed,}) {
  return _then(_VehicleData(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,plate_no: freezed == plate_no ? _self.plate_no : plate_no // ignore: cast_nullable_to_non_nullable
as String?,vehicle_type_id: freezed == vehicle_type_id ? _self.vehicle_type_id : vehicle_type_id // ignore: cast_nullable_to_non_nullable
as int?,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as String?,capacity_unit_id: freezed == capacity_unit_id ? _self.capacity_unit_id : capacity_unit_id // ignore: cast_nullable_to_non_nullable
as int?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,customer_id: freezed == customer_id ? _self.customer_id : customer_id // ignore: cast_nullable_to_non_nullable
as int?,user_id: freezed == user_id ? _self.user_id : user_id // ignore: cast_nullable_to_non_nullable
as int?,updated_at: freezed == updated_at ? _self.updated_at : updated_at // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as VehicleType?,vehicle_capacity_unit: freezed == vehicle_capacity_unit ? _self.vehicle_capacity_unit : vehicle_capacity_unit // ignore: cast_nullable_to_non_nullable
as VehicleCapacityUnit?,customer: freezed == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as Customer?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User?,vehicle_images: freezed == vehicle_images ? _self._vehicle_images : vehicle_images // ignore: cast_nullable_to_non_nullable
as List<VehicleImage>?,
  ));
}

/// Create a copy of VehicleData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VehicleTypeCopyWith<$Res>? get type {
    if (_self.type == null) {
    return null;
  }

  return $VehicleTypeCopyWith<$Res>(_self.type!, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of VehicleData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VehicleCapacityUnitCopyWith<$Res>? get vehicle_capacity_unit {
    if (_self.vehicle_capacity_unit == null) {
    return null;
  }

  return $VehicleCapacityUnitCopyWith<$Res>(_self.vehicle_capacity_unit!, (value) {
    return _then(_self.copyWith(vehicle_capacity_unit: value));
  });
}/// Create a copy of VehicleData
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
}/// Create a copy of VehicleData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
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


/// Adds pattern-matching-related methods to [Customer].
extension CustomerPatterns on Customer {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Customer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Customer() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Customer value)  $default,){
final _that = this;
switch (_that) {
case _Customer():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Customer value)?  $default,){
final _that = this;
switch (_that) {
case _Customer() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? Name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Customer() when $default != null:
return $default(_that.id,_that.Name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? Name)  $default,) {final _that = this;
switch (_that) {
case _Customer():
return $default(_that.id,_that.Name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? Name)?  $default,) {final _that = this;
switch (_that) {
case _Customer() when $default != null:
return $default(_that.id,_that.Name);case _:
  return null;

}
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


/// Adds pattern-matching-related methods to [VehicleType].
extension VehicleTypePatterns on VehicleType {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VehicleType value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VehicleType() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VehicleType value)  $default,){
final _that = this;
switch (_that) {
case _VehicleType():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VehicleType value)?  $default,){
final _that = this;
switch (_that) {
case _VehicleType() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? Name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VehicleType() when $default != null:
return $default(_that.id,_that.Name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? Name)  $default,) {final _that = this;
switch (_that) {
case _VehicleType():
return $default(_that.id,_that.Name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? Name)?  $default,) {final _that = this;
switch (_that) {
case _VehicleType() when $default != null:
return $default(_that.id,_that.Name);case _:
  return null;

}
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
mixin _$VehicleCapacityUnit {

 int? get id; String? get Name;
/// Create a copy of VehicleCapacityUnit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleCapacityUnitCopyWith<VehicleCapacityUnit> get copyWith => _$VehicleCapacityUnitCopyWithImpl<VehicleCapacityUnit>(this as VehicleCapacityUnit, _$identity);

  /// Serializes this VehicleCapacityUnit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VehicleCapacityUnit&&(identical(other.id, id) || other.id == id)&&(identical(other.Name, Name) || other.Name == Name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,Name);

@override
String toString() {
  return 'VehicleCapacityUnit(id: $id, Name: $Name)';
}


}

/// @nodoc
abstract mixin class $VehicleCapacityUnitCopyWith<$Res>  {
  factory $VehicleCapacityUnitCopyWith(VehicleCapacityUnit value, $Res Function(VehicleCapacityUnit) _then) = _$VehicleCapacityUnitCopyWithImpl;
@useResult
$Res call({
 int? id, String? Name
});




}
/// @nodoc
class _$VehicleCapacityUnitCopyWithImpl<$Res>
    implements $VehicleCapacityUnitCopyWith<$Res> {
  _$VehicleCapacityUnitCopyWithImpl(this._self, this._then);

  final VehicleCapacityUnit _self;
  final $Res Function(VehicleCapacityUnit) _then;

/// Create a copy of VehicleCapacityUnit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? Name = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,Name: freezed == Name ? _self.Name : Name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VehicleCapacityUnit].
extension VehicleCapacityUnitPatterns on VehicleCapacityUnit {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VehicleCapacityUnit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VehicleCapacityUnit() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VehicleCapacityUnit value)  $default,){
final _that = this;
switch (_that) {
case _VehicleCapacityUnit():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VehicleCapacityUnit value)?  $default,){
final _that = this;
switch (_that) {
case _VehicleCapacityUnit() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? Name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VehicleCapacityUnit() when $default != null:
return $default(_that.id,_that.Name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? Name)  $default,) {final _that = this;
switch (_that) {
case _VehicleCapacityUnit():
return $default(_that.id,_that.Name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? Name)?  $default,) {final _that = this;
switch (_that) {
case _VehicleCapacityUnit() when $default != null:
return $default(_that.id,_that.Name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VehicleCapacityUnit implements VehicleCapacityUnit {
  const _VehicleCapacityUnit({this.id, this.Name});
  factory _VehicleCapacityUnit.fromJson(Map<String, dynamic> json) => _$VehicleCapacityUnitFromJson(json);

@override final  int? id;
@override final  String? Name;

/// Create a copy of VehicleCapacityUnit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleCapacityUnitCopyWith<_VehicleCapacityUnit> get copyWith => __$VehicleCapacityUnitCopyWithImpl<_VehicleCapacityUnit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleCapacityUnitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VehicleCapacityUnit&&(identical(other.id, id) || other.id == id)&&(identical(other.Name, Name) || other.Name == Name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,Name);

@override
String toString() {
  return 'VehicleCapacityUnit(id: $id, Name: $Name)';
}


}

/// @nodoc
abstract mixin class _$VehicleCapacityUnitCopyWith<$Res> implements $VehicleCapacityUnitCopyWith<$Res> {
  factory _$VehicleCapacityUnitCopyWith(_VehicleCapacityUnit value, $Res Function(_VehicleCapacityUnit) _then) = __$VehicleCapacityUnitCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? Name
});




}
/// @nodoc
class __$VehicleCapacityUnitCopyWithImpl<$Res>
    implements _$VehicleCapacityUnitCopyWith<$Res> {
  __$VehicleCapacityUnitCopyWithImpl(this._self, this._then);

  final _VehicleCapacityUnit _self;
  final $Res Function(_VehicleCapacityUnit) _then;

/// Create a copy of VehicleCapacityUnit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? Name = freezed,}) {
  return _then(_VehicleCapacityUnit(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,Name: freezed == Name ? _self.Name : Name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$User {

 int? get id; String? get name;
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCopyWith<User> get copyWith => _$UserCopyWithImpl<User>(this as User, _$identity);

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is User&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'User(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $UserCopyWith<$Res>  {
  factory $UserCopyWith(User value, $Res Function(User) _then) = _$UserCopyWithImpl;
@useResult
$Res call({
 int? id, String? name
});




}
/// @nodoc
class _$UserCopyWithImpl<$Res>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._self, this._then);

  final User _self;
  final $Res Function(User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [User].
extension UserPatterns on User {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _User value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _User value)  $default,){
final _that = this;
switch (_that) {
case _User():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _User value)?  $default,){
final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.id,_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? name)  $default,) {final _that = this;
switch (_that) {
case _User():
return $default(_that.id,_that.name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _User implements User {
  const _User({this.id, this.name});
  factory _User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

@override final  int? id;
@override final  String? name;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCopyWith<_User> get copyWith => __$UserCopyWithImpl<_User>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _User&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'User(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$UserCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$UserCopyWith(_User value, $Res Function(_User) _then) = __$UserCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? name
});




}
/// @nodoc
class __$UserCopyWithImpl<$Res>
    implements _$UserCopyWith<$Res> {
  __$UserCopyWithImpl(this._self, this._then);

  final _User _self;
  final $Res Function(_User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = freezed,}) {
  return _then(_User(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$VehicleImage {

 int? get id; String? get Title; int? get RelationId;
/// Create a copy of VehicleImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleImageCopyWith<VehicleImage> get copyWith => _$VehicleImageCopyWithImpl<VehicleImage>(this as VehicleImage, _$identity);

  /// Serializes this VehicleImage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VehicleImage&&(identical(other.id, id) || other.id == id)&&(identical(other.Title, Title) || other.Title == Title)&&(identical(other.RelationId, RelationId) || other.RelationId == RelationId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,Title,RelationId);

@override
String toString() {
  return 'VehicleImage(id: $id, Title: $Title, RelationId: $RelationId)';
}


}

/// @nodoc
abstract mixin class $VehicleImageCopyWith<$Res>  {
  factory $VehicleImageCopyWith(VehicleImage value, $Res Function(VehicleImage) _then) = _$VehicleImageCopyWithImpl;
@useResult
$Res call({
 int? id, String? Title, int? RelationId
});




}
/// @nodoc
class _$VehicleImageCopyWithImpl<$Res>
    implements $VehicleImageCopyWith<$Res> {
  _$VehicleImageCopyWithImpl(this._self, this._then);

  final VehicleImage _self;
  final $Res Function(VehicleImage) _then;

/// Create a copy of VehicleImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? Title = freezed,Object? RelationId = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,Title: freezed == Title ? _self.Title : Title // ignore: cast_nullable_to_non_nullable
as String?,RelationId: freezed == RelationId ? _self.RelationId : RelationId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [VehicleImage].
extension VehicleImagePatterns on VehicleImage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VehicleImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VehicleImage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VehicleImage value)  $default,){
final _that = this;
switch (_that) {
case _VehicleImage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VehicleImage value)?  $default,){
final _that = this;
switch (_that) {
case _VehicleImage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? Title,  int? RelationId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VehicleImage() when $default != null:
return $default(_that.id,_that.Title,_that.RelationId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? Title,  int? RelationId)  $default,) {final _that = this;
switch (_that) {
case _VehicleImage():
return $default(_that.id,_that.Title,_that.RelationId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? Title,  int? RelationId)?  $default,) {final _that = this;
switch (_that) {
case _VehicleImage() when $default != null:
return $default(_that.id,_that.Title,_that.RelationId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VehicleImage implements VehicleImage {
  const _VehicleImage({this.id, this.Title, this.RelationId});
  factory _VehicleImage.fromJson(Map<String, dynamic> json) => _$VehicleImageFromJson(json);

@override final  int? id;
@override final  String? Title;
@override final  int? RelationId;

/// Create a copy of VehicleImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleImageCopyWith<_VehicleImage> get copyWith => __$VehicleImageCopyWithImpl<_VehicleImage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleImageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VehicleImage&&(identical(other.id, id) || other.id == id)&&(identical(other.Title, Title) || other.Title == Title)&&(identical(other.RelationId, RelationId) || other.RelationId == RelationId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,Title,RelationId);

@override
String toString() {
  return 'VehicleImage(id: $id, Title: $Title, RelationId: $RelationId)';
}


}

/// @nodoc
abstract mixin class _$VehicleImageCopyWith<$Res> implements $VehicleImageCopyWith<$Res> {
  factory _$VehicleImageCopyWith(_VehicleImage value, $Res Function(_VehicleImage) _then) = __$VehicleImageCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? Title, int? RelationId
});




}
/// @nodoc
class __$VehicleImageCopyWithImpl<$Res>
    implements _$VehicleImageCopyWith<$Res> {
  __$VehicleImageCopyWithImpl(this._self, this._then);

  final _VehicleImage _self;
  final $Res Function(_VehicleImage) _then;

/// Create a copy of VehicleImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? Title = freezed,Object? RelationId = freezed,}) {
  return _then(_VehicleImage(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,Title: freezed == Title ? _self.Title : Title // ignore: cast_nullable_to_non_nullable
as String?,RelationId: freezed == RelationId ? _self.RelationId : RelationId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
