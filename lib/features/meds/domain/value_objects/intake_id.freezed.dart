// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'intake_id.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IntakeId {

 String get value;
/// Create a copy of IntakeId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntakeIdCopyWith<IntakeId> get copyWith => _$IntakeIdCopyWithImpl<IntakeId>(this as IntakeId, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IntakeId&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'IntakeId(value: $value)';
}


}

/// @nodoc
abstract mixin class $IntakeIdCopyWith<$Res>  {
  factory $IntakeIdCopyWith(IntakeId value, $Res Function(IntakeId) _then) = _$IntakeIdCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$IntakeIdCopyWithImpl<$Res>
    implements $IntakeIdCopyWith<$Res> {
  _$IntakeIdCopyWithImpl(this._self, this._then);

  final IntakeId _self;
  final $Res Function(IntakeId) _then;

/// Create a copy of IntakeId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [IntakeId].
extension IntakeIdPatterns on IntakeId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IntakeId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IntakeId() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IntakeId value)  $default,){
final _that = this;
switch (_that) {
case _IntakeId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IntakeId value)?  $default,){
final _that = this;
switch (_that) {
case _IntakeId() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IntakeId() when $default != null:
return $default(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String value)  $default,) {final _that = this;
switch (_that) {
case _IntakeId():
return $default(_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String value)?  $default,) {final _that = this;
switch (_that) {
case _IntakeId() when $default != null:
return $default(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _IntakeId implements IntakeId {
  const _IntakeId(this.value);
  

@override final  String value;

/// Create a copy of IntakeId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IntakeIdCopyWith<_IntakeId> get copyWith => __$IntakeIdCopyWithImpl<_IntakeId>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IntakeId&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'IntakeId(value: $value)';
}


}

/// @nodoc
abstract mixin class _$IntakeIdCopyWith<$Res> implements $IntakeIdCopyWith<$Res> {
  factory _$IntakeIdCopyWith(_IntakeId value, $Res Function(_IntakeId) _then) = __$IntakeIdCopyWithImpl;
@override @useResult
$Res call({
 String value
});




}
/// @nodoc
class __$IntakeIdCopyWithImpl<$Res>
    implements _$IntakeIdCopyWith<$Res> {
  __$IntakeIdCopyWithImpl(this._self, this._then);

  final _IntakeId _self;
  final $Res Function(_IntakeId) _then;

/// Create a copy of IntakeId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_IntakeId(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
