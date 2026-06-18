// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pack_stock.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PackStock {

/// Units currently left in the pack.
 int get remaining;/// Units in a full pack (the size a refill restores [remaining] to).
 int get total;/// Low-stock threshold: when [remaining] drops to or below this value,
/// the user should be warned to refill.
 int get warnAt;
/// Create a copy of PackStock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PackStockCopyWith<PackStock> get copyWith => _$PackStockCopyWithImpl<PackStock>(this as PackStock, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PackStock&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.total, total) || other.total == total)&&(identical(other.warnAt, warnAt) || other.warnAt == warnAt));
}


@override
int get hashCode => Object.hash(runtimeType,remaining,total,warnAt);

@override
String toString() {
  return 'PackStock(remaining: $remaining, total: $total, warnAt: $warnAt)';
}


}

/// @nodoc
abstract mixin class $PackStockCopyWith<$Res>  {
  factory $PackStockCopyWith(PackStock value, $Res Function(PackStock) _then) = _$PackStockCopyWithImpl;
@useResult
$Res call({
 int remaining, int total, int warnAt
});




}
/// @nodoc
class _$PackStockCopyWithImpl<$Res>
    implements $PackStockCopyWith<$Res> {
  _$PackStockCopyWithImpl(this._self, this._then);

  final PackStock _self;
  final $Res Function(PackStock) _then;

/// Create a copy of PackStock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? remaining = null,Object? total = null,Object? warnAt = null,}) {
  return _then(_self.copyWith(
remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,warnAt: null == warnAt ? _self.warnAt : warnAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PackStock].
extension PackStockPatterns on PackStock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PackStock value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PackStock() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PackStock value)  $default,){
final _that = this;
switch (_that) {
case _PackStock():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PackStock value)?  $default,){
final _that = this;
switch (_that) {
case _PackStock() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int remaining,  int total,  int warnAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PackStock() when $default != null:
return $default(_that.remaining,_that.total,_that.warnAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int remaining,  int total,  int warnAt)  $default,) {final _that = this;
switch (_that) {
case _PackStock():
return $default(_that.remaining,_that.total,_that.warnAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int remaining,  int total,  int warnAt)?  $default,) {final _that = this;
switch (_that) {
case _PackStock() when $default != null:
return $default(_that.remaining,_that.total,_that.warnAt);case _:
  return null;

}
}

}

/// @nodoc


class _PackStock implements PackStock {
  const _PackStock({required this.remaining, required this.total, required this.warnAt});
  

/// Units currently left in the pack.
@override final  int remaining;
/// Units in a full pack (the size a refill restores [remaining] to).
@override final  int total;
/// Low-stock threshold: when [remaining] drops to or below this value,
/// the user should be warned to refill.
@override final  int warnAt;

/// Create a copy of PackStock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PackStockCopyWith<_PackStock> get copyWith => __$PackStockCopyWithImpl<_PackStock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PackStock&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.total, total) || other.total == total)&&(identical(other.warnAt, warnAt) || other.warnAt == warnAt));
}


@override
int get hashCode => Object.hash(runtimeType,remaining,total,warnAt);

@override
String toString() {
  return 'PackStock(remaining: $remaining, total: $total, warnAt: $warnAt)';
}


}

/// @nodoc
abstract mixin class _$PackStockCopyWith<$Res> implements $PackStockCopyWith<$Res> {
  factory _$PackStockCopyWith(_PackStock value, $Res Function(_PackStock) _then) = __$PackStockCopyWithImpl;
@override @useResult
$Res call({
 int remaining, int total, int warnAt
});




}
/// @nodoc
class __$PackStockCopyWithImpl<$Res>
    implements _$PackStockCopyWith<$Res> {
  __$PackStockCopyWithImpl(this._self, this._then);

  final _PackStock _self;
  final $Res Function(_PackStock) _then;

/// Create a copy of PackStock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? remaining = null,Object? total = null,Object? warnAt = null,}) {
  return _then(_PackStock(
remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,warnAt: null == warnAt ? _self.warnAt : warnAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
