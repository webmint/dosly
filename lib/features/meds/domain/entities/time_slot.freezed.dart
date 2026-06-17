// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'time_slot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TimeSlot {

/// Stable identifier for this slot.
 TimeSlotId get id;/// Local wall-clock minute of the day, in the range `0..1439`
/// (`0` = 00:00, `1439` = 23:59). This is a wall-clock value, not a
/// UTC offset — it intentionally carries no timezone information.
 int get minuteOfDay;/// Per-slot dose that replaces the medication's default dose for this
/// slot when non-null; `null` means "use the medication's default dose".
 Dosage? get doseOverride;
/// Create a copy of TimeSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeSlotCopyWith<TimeSlot> get copyWith => _$TimeSlotCopyWithImpl<TimeSlot>(this as TimeSlot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeSlot&&(identical(other.id, id) || other.id == id)&&(identical(other.minuteOfDay, minuteOfDay) || other.minuteOfDay == minuteOfDay)&&(identical(other.doseOverride, doseOverride) || other.doseOverride == doseOverride));
}


@override
int get hashCode => Object.hash(runtimeType,id,minuteOfDay,doseOverride);

@override
String toString() {
  return 'TimeSlot(id: $id, minuteOfDay: $minuteOfDay, doseOverride: $doseOverride)';
}


}

/// @nodoc
abstract mixin class $TimeSlotCopyWith<$Res>  {
  factory $TimeSlotCopyWith(TimeSlot value, $Res Function(TimeSlot) _then) = _$TimeSlotCopyWithImpl;
@useResult
$Res call({
 TimeSlotId id, int minuteOfDay, Dosage? doseOverride
});


$TimeSlotIdCopyWith<$Res> get id;$DosageCopyWith<$Res>? get doseOverride;

}
/// @nodoc
class _$TimeSlotCopyWithImpl<$Res>
    implements $TimeSlotCopyWith<$Res> {
  _$TimeSlotCopyWithImpl(this._self, this._then);

  final TimeSlot _self;
  final $Res Function(TimeSlot) _then;

/// Create a copy of TimeSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? minuteOfDay = null,Object? doseOverride = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as TimeSlotId,minuteOfDay: null == minuteOfDay ? _self.minuteOfDay : minuteOfDay // ignore: cast_nullable_to_non_nullable
as int,doseOverride: freezed == doseOverride ? _self.doseOverride : doseOverride // ignore: cast_nullable_to_non_nullable
as Dosage?,
  ));
}
/// Create a copy of TimeSlot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeSlotIdCopyWith<$Res> get id {
  
  return $TimeSlotIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of TimeSlot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DosageCopyWith<$Res>? get doseOverride {
    if (_self.doseOverride == null) {
    return null;
  }

  return $DosageCopyWith<$Res>(_self.doseOverride!, (value) {
    return _then(_self.copyWith(doseOverride: value));
  });
}
}


/// Adds pattern-matching-related methods to [TimeSlot].
extension TimeSlotPatterns on TimeSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimeSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimeSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimeSlot value)  $default,){
final _that = this;
switch (_that) {
case _TimeSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimeSlot value)?  $default,){
final _that = this;
switch (_that) {
case _TimeSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TimeSlotId id,  int minuteOfDay,  Dosage? doseOverride)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimeSlot() when $default != null:
return $default(_that.id,_that.minuteOfDay,_that.doseOverride);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TimeSlotId id,  int minuteOfDay,  Dosage? doseOverride)  $default,) {final _that = this;
switch (_that) {
case _TimeSlot():
return $default(_that.id,_that.minuteOfDay,_that.doseOverride);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TimeSlotId id,  int minuteOfDay,  Dosage? doseOverride)?  $default,) {final _that = this;
switch (_that) {
case _TimeSlot() when $default != null:
return $default(_that.id,_that.minuteOfDay,_that.doseOverride);case _:
  return null;

}
}

}

/// @nodoc


class _TimeSlot implements TimeSlot {
  const _TimeSlot({required this.id, required this.minuteOfDay, this.doseOverride});
  

/// Stable identifier for this slot.
@override final  TimeSlotId id;
/// Local wall-clock minute of the day, in the range `0..1439`
/// (`0` = 00:00, `1439` = 23:59). This is a wall-clock value, not a
/// UTC offset — it intentionally carries no timezone information.
@override final  int minuteOfDay;
/// Per-slot dose that replaces the medication's default dose for this
/// slot when non-null; `null` means "use the medication's default dose".
@override final  Dosage? doseOverride;

/// Create a copy of TimeSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimeSlotCopyWith<_TimeSlot> get copyWith => __$TimeSlotCopyWithImpl<_TimeSlot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimeSlot&&(identical(other.id, id) || other.id == id)&&(identical(other.minuteOfDay, minuteOfDay) || other.minuteOfDay == minuteOfDay)&&(identical(other.doseOverride, doseOverride) || other.doseOverride == doseOverride));
}


@override
int get hashCode => Object.hash(runtimeType,id,minuteOfDay,doseOverride);

@override
String toString() {
  return 'TimeSlot(id: $id, minuteOfDay: $minuteOfDay, doseOverride: $doseOverride)';
}


}

/// @nodoc
abstract mixin class _$TimeSlotCopyWith<$Res> implements $TimeSlotCopyWith<$Res> {
  factory _$TimeSlotCopyWith(_TimeSlot value, $Res Function(_TimeSlot) _then) = __$TimeSlotCopyWithImpl;
@override @useResult
$Res call({
 TimeSlotId id, int minuteOfDay, Dosage? doseOverride
});


@override $TimeSlotIdCopyWith<$Res> get id;@override $DosageCopyWith<$Res>? get doseOverride;

}
/// @nodoc
class __$TimeSlotCopyWithImpl<$Res>
    implements _$TimeSlotCopyWith<$Res> {
  __$TimeSlotCopyWithImpl(this._self, this._then);

  final _TimeSlot _self;
  final $Res Function(_TimeSlot) _then;

/// Create a copy of TimeSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? minuteOfDay = null,Object? doseOverride = freezed,}) {
  return _then(_TimeSlot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as TimeSlotId,minuteOfDay: null == minuteOfDay ? _self.minuteOfDay : minuteOfDay // ignore: cast_nullable_to_non_nullable
as int,doseOverride: freezed == doseOverride ? _self.doseOverride : doseOverride // ignore: cast_nullable_to_non_nullable
as Dosage?,
  ));
}

/// Create a copy of TimeSlot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeSlotIdCopyWith<$Res> get id {
  
  return $TimeSlotIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of TimeSlot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DosageCopyWith<$Res>? get doseOverride {
    if (_self.doseOverride == null) {
    return null;
  }

  return $DosageCopyWith<$Res>(_self.doseOverride!, (value) {
    return _then(_self.copyWith(doseOverride: value));
  });
}
}

// dart format on
