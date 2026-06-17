// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dosage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Dosage {

/// The numeric quantity of the dose (e.g. `2` for two tablets, `5` for 5 ml).
 double get amount;/// The unit [amount] is measured in.
 DoseUnit get unit;
/// Create a copy of Dosage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DosageCopyWith<Dosage> get copyWith => _$DosageCopyWithImpl<Dosage>(this as Dosage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Dosage&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.unit, unit) || other.unit == unit));
}


@override
int get hashCode => Object.hash(runtimeType,amount,unit);

@override
String toString() {
  return 'Dosage(amount: $amount, unit: $unit)';
}


}

/// @nodoc
abstract mixin class $DosageCopyWith<$Res>  {
  factory $DosageCopyWith(Dosage value, $Res Function(Dosage) _then) = _$DosageCopyWithImpl;
@useResult
$Res call({
 double amount, DoseUnit unit
});




}
/// @nodoc
class _$DosageCopyWithImpl<$Res>
    implements $DosageCopyWith<$Res> {
  _$DosageCopyWithImpl(this._self, this._then);

  final Dosage _self;
  final $Res Function(Dosage) _then;

/// Create a copy of Dosage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? unit = null,}) {
  return _then(_self.copyWith(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as DoseUnit,
  ));
}

}


/// Adds pattern-matching-related methods to [Dosage].
extension DosagePatterns on Dosage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Dosage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Dosage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Dosage value)  $default,){
final _that = this;
switch (_that) {
case _Dosage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Dosage value)?  $default,){
final _that = this;
switch (_that) {
case _Dosage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double amount,  DoseUnit unit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Dosage() when $default != null:
return $default(_that.amount,_that.unit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double amount,  DoseUnit unit)  $default,) {final _that = this;
switch (_that) {
case _Dosage():
return $default(_that.amount,_that.unit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double amount,  DoseUnit unit)?  $default,) {final _that = this;
switch (_that) {
case _Dosage() when $default != null:
return $default(_that.amount,_that.unit);case _:
  return null;

}
}

}

/// @nodoc


class _Dosage implements Dosage {
  const _Dosage({required this.amount, required this.unit});
  

/// The numeric quantity of the dose (e.g. `2` for two tablets, `5` for 5 ml).
@override final  double amount;
/// The unit [amount] is measured in.
@override final  DoseUnit unit;

/// Create a copy of Dosage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DosageCopyWith<_Dosage> get copyWith => __$DosageCopyWithImpl<_Dosage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Dosage&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.unit, unit) || other.unit == unit));
}


@override
int get hashCode => Object.hash(runtimeType,amount,unit);

@override
String toString() {
  return 'Dosage(amount: $amount, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$DosageCopyWith<$Res> implements $DosageCopyWith<$Res> {
  factory _$DosageCopyWith(_Dosage value, $Res Function(_Dosage) _then) = __$DosageCopyWithImpl;
@override @useResult
$Res call({
 double amount, DoseUnit unit
});




}
/// @nodoc
class __$DosageCopyWithImpl<$Res>
    implements _$DosageCopyWith<$Res> {
  __$DosageCopyWithImpl(this._self, this._then);

  final _Dosage _self;
  final $Res Function(_Dosage) _then;

/// Create a copy of Dosage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? unit = null,}) {
  return _then(_Dosage(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as DoseUnit,
  ));
}


}

// dart format on
