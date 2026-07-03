// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'intake.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Intake {

/// Stable, typed identifier for this intake.
 IntakeId get id;/// The medication this intake is an occurrence of.
 MedicationId get medicationId;/// The schedule time slot that generated this occurrence.
 TimeSlotId get slotId;/// When this intake was due, in **UTC** (constitution §"All timestamps in
/// UTC, displayed in local").
 DateTime get scheduledAt;/// When the user confirmed the intake, in **UTC**. `null` while the intake
/// has not been confirmed (e.g. pending or skipped).
 DateTime? get confirmedAt;/// Current lifecycle state of this intake.
 IntakeStatus get status;/// Free-form user notes for this occurrence. `null` when none were entered.
 String? get notes;
/// Create a copy of Intake
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntakeCopyWith<Intake> get copyWith => _$IntakeCopyWithImpl<Intake>(this as Intake, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Intake&&(identical(other.id, id) || other.id == id)&&(identical(other.medicationId, medicationId) || other.medicationId == medicationId)&&(identical(other.slotId, slotId) || other.slotId == slotId)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,id,medicationId,slotId,scheduledAt,confirmedAt,status,notes);

@override
String toString() {
  return 'Intake(id: $id, medicationId: $medicationId, slotId: $slotId, scheduledAt: $scheduledAt, confirmedAt: $confirmedAt, status: $status, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $IntakeCopyWith<$Res>  {
  factory $IntakeCopyWith(Intake value, $Res Function(Intake) _then) = _$IntakeCopyWithImpl;
@useResult
$Res call({
 IntakeId id, MedicationId medicationId, TimeSlotId slotId, DateTime scheduledAt, DateTime? confirmedAt, IntakeStatus status, String? notes
});


$IntakeIdCopyWith<$Res> get id;$MedicationIdCopyWith<$Res> get medicationId;$TimeSlotIdCopyWith<$Res> get slotId;

}
/// @nodoc
class _$IntakeCopyWithImpl<$Res>
    implements $IntakeCopyWith<$Res> {
  _$IntakeCopyWithImpl(this._self, this._then);

  final Intake _self;
  final $Res Function(Intake) _then;

/// Create a copy of Intake
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? medicationId = null,Object? slotId = null,Object? scheduledAt = null,Object? confirmedAt = freezed,Object? status = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as IntakeId,medicationId: null == medicationId ? _self.medicationId : medicationId // ignore: cast_nullable_to_non_nullable
as MedicationId,slotId: null == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as TimeSlotId,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IntakeStatus,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Intake
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IntakeIdCopyWith<$Res> get id {
  
  return $IntakeIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of Intake
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedicationIdCopyWith<$Res> get medicationId {
  
  return $MedicationIdCopyWith<$Res>(_self.medicationId, (value) {
    return _then(_self.copyWith(medicationId: value));
  });
}/// Create a copy of Intake
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeSlotIdCopyWith<$Res> get slotId {
  
  return $TimeSlotIdCopyWith<$Res>(_self.slotId, (value) {
    return _then(_self.copyWith(slotId: value));
  });
}
}


/// Adds pattern-matching-related methods to [Intake].
extension IntakePatterns on Intake {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Intake value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Intake() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Intake value)  $default,){
final _that = this;
switch (_that) {
case _Intake():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Intake value)?  $default,){
final _that = this;
switch (_that) {
case _Intake() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( IntakeId id,  MedicationId medicationId,  TimeSlotId slotId,  DateTime scheduledAt,  DateTime? confirmedAt,  IntakeStatus status,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Intake() when $default != null:
return $default(_that.id,_that.medicationId,_that.slotId,_that.scheduledAt,_that.confirmedAt,_that.status,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( IntakeId id,  MedicationId medicationId,  TimeSlotId slotId,  DateTime scheduledAt,  DateTime? confirmedAt,  IntakeStatus status,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _Intake():
return $default(_that.id,_that.medicationId,_that.slotId,_that.scheduledAt,_that.confirmedAt,_that.status,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( IntakeId id,  MedicationId medicationId,  TimeSlotId slotId,  DateTime scheduledAt,  DateTime? confirmedAt,  IntakeStatus status,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _Intake() when $default != null:
return $default(_that.id,_that.medicationId,_that.slotId,_that.scheduledAt,_that.confirmedAt,_that.status,_that.notes);case _:
  return null;

}
}

}

/// @nodoc


class _Intake implements Intake {
  const _Intake({required this.id, required this.medicationId, required this.slotId, required this.scheduledAt, this.confirmedAt, required this.status, this.notes});
  

/// Stable, typed identifier for this intake.
@override final  IntakeId id;
/// The medication this intake is an occurrence of.
@override final  MedicationId medicationId;
/// The schedule time slot that generated this occurrence.
@override final  TimeSlotId slotId;
/// When this intake was due, in **UTC** (constitution §"All timestamps in
/// UTC, displayed in local").
@override final  DateTime scheduledAt;
/// When the user confirmed the intake, in **UTC**. `null` while the intake
/// has not been confirmed (e.g. pending or skipped).
@override final  DateTime? confirmedAt;
/// Current lifecycle state of this intake.
@override final  IntakeStatus status;
/// Free-form user notes for this occurrence. `null` when none were entered.
@override final  String? notes;

/// Create a copy of Intake
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IntakeCopyWith<_Intake> get copyWith => __$IntakeCopyWithImpl<_Intake>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Intake&&(identical(other.id, id) || other.id == id)&&(identical(other.medicationId, medicationId) || other.medicationId == medicationId)&&(identical(other.slotId, slotId) || other.slotId == slotId)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,id,medicationId,slotId,scheduledAt,confirmedAt,status,notes);

@override
String toString() {
  return 'Intake(id: $id, medicationId: $medicationId, slotId: $slotId, scheduledAt: $scheduledAt, confirmedAt: $confirmedAt, status: $status, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$IntakeCopyWith<$Res> implements $IntakeCopyWith<$Res> {
  factory _$IntakeCopyWith(_Intake value, $Res Function(_Intake) _then) = __$IntakeCopyWithImpl;
@override @useResult
$Res call({
 IntakeId id, MedicationId medicationId, TimeSlotId slotId, DateTime scheduledAt, DateTime? confirmedAt, IntakeStatus status, String? notes
});


@override $IntakeIdCopyWith<$Res> get id;@override $MedicationIdCopyWith<$Res> get medicationId;@override $TimeSlotIdCopyWith<$Res> get slotId;

}
/// @nodoc
class __$IntakeCopyWithImpl<$Res>
    implements _$IntakeCopyWith<$Res> {
  __$IntakeCopyWithImpl(this._self, this._then);

  final _Intake _self;
  final $Res Function(_Intake) _then;

/// Create a copy of Intake
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? medicationId = null,Object? slotId = null,Object? scheduledAt = null,Object? confirmedAt = freezed,Object? status = null,Object? notes = freezed,}) {
  return _then(_Intake(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as IntakeId,medicationId: null == medicationId ? _self.medicationId : medicationId // ignore: cast_nullable_to_non_nullable
as MedicationId,slotId: null == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as TimeSlotId,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IntakeStatus,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Intake
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IntakeIdCopyWith<$Res> get id {
  
  return $IntakeIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of Intake
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedicationIdCopyWith<$Res> get medicationId {
  
  return $MedicationIdCopyWith<$Res>(_self.medicationId, (value) {
    return _then(_self.copyWith(medicationId: value));
  });
}/// Create a copy of Intake
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeSlotIdCopyWith<$Res> get slotId {
  
  return $TimeSlotIdCopyWith<$Res>(_self.slotId, (value) {
    return _then(_self.copyWith(slotId: value));
  });
}
}

// dart format on
