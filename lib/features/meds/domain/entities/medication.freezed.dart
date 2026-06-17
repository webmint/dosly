// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medication.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Medication {

/// Stable, typed identifier for this medication.
 MedicationId get id;/// User-facing display name of the medication.
 String get name;/// Physical form the medication is taken in (tablet, syrup, …).
 MedicationForm get form;/// Temporal pattern of intake: continuous or a bounded/cyclic course.
 MedicationType get type;/// The recurring intake plan (frequency + time slots).
 Schedule get schedule;/// Default dose taken at each occurrence. `null` when no default dose is
/// recorded (individual [TimeSlot]s may still carry per-slot overrides).
 Dosage? get dosePerIntake;/// On-hand inventory tracking. `null` when stock is not tracked for this
/// medication.
 PackStock? get stock;/// Free-form user notes. `null` when none were entered.
 String? get notes;/// Timestamp at which this medication record was created.
 DateTime get createdAt;
/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicationCopyWith<Medication> get copyWith => _$MedicationCopyWithImpl<Medication>(this as Medication, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Medication&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.form, form) || other.form == form)&&(identical(other.type, type) || other.type == type)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.dosePerIntake, dosePerIntake) || other.dosePerIntake == dosePerIntake)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,form,type,schedule,dosePerIntake,stock,notes,createdAt);

@override
String toString() {
  return 'Medication(id: $id, name: $name, form: $form, type: $type, schedule: $schedule, dosePerIntake: $dosePerIntake, stock: $stock, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MedicationCopyWith<$Res>  {
  factory $MedicationCopyWith(Medication value, $Res Function(Medication) _then) = _$MedicationCopyWithImpl;
@useResult
$Res call({
 MedicationId id, String name, MedicationForm form, MedicationType type, Schedule schedule, Dosage? dosePerIntake, PackStock? stock, String? notes, DateTime createdAt
});


$MedicationIdCopyWith<$Res> get id;$MedicationTypeCopyWith<$Res> get type;$ScheduleCopyWith<$Res> get schedule;$DosageCopyWith<$Res>? get dosePerIntake;$PackStockCopyWith<$Res>? get stock;

}
/// @nodoc
class _$MedicationCopyWithImpl<$Res>
    implements $MedicationCopyWith<$Res> {
  _$MedicationCopyWithImpl(this._self, this._then);

  final Medication _self;
  final $Res Function(Medication) _then;

/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? form = null,Object? type = null,Object? schedule = null,Object? dosePerIntake = freezed,Object? stock = freezed,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as MedicationId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,form: null == form ? _self.form : form // ignore: cast_nullable_to_non_nullable
as MedicationForm,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MedicationType,schedule: null == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as Schedule,dosePerIntake: freezed == dosePerIntake ? _self.dosePerIntake : dosePerIntake // ignore: cast_nullable_to_non_nullable
as Dosage?,stock: freezed == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as PackStock?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedicationIdCopyWith<$Res> get id {
  
  return $MedicationIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedicationTypeCopyWith<$Res> get type {
  
  return $MedicationTypeCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScheduleCopyWith<$Res> get schedule {
  
  return $ScheduleCopyWith<$Res>(_self.schedule, (value) {
    return _then(_self.copyWith(schedule: value));
  });
}/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DosageCopyWith<$Res>? get dosePerIntake {
    if (_self.dosePerIntake == null) {
    return null;
  }

  return $DosageCopyWith<$Res>(_self.dosePerIntake!, (value) {
    return _then(_self.copyWith(dosePerIntake: value));
  });
}/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PackStockCopyWith<$Res>? get stock {
    if (_self.stock == null) {
    return null;
  }

  return $PackStockCopyWith<$Res>(_self.stock!, (value) {
    return _then(_self.copyWith(stock: value));
  });
}
}


/// Adds pattern-matching-related methods to [Medication].
extension MedicationPatterns on Medication {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Medication value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Medication() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Medication value)  $default,){
final _that = this;
switch (_that) {
case _Medication():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Medication value)?  $default,){
final _that = this;
switch (_that) {
case _Medication() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MedicationId id,  String name,  MedicationForm form,  MedicationType type,  Schedule schedule,  Dosage? dosePerIntake,  PackStock? stock,  String? notes,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Medication() when $default != null:
return $default(_that.id,_that.name,_that.form,_that.type,_that.schedule,_that.dosePerIntake,_that.stock,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MedicationId id,  String name,  MedicationForm form,  MedicationType type,  Schedule schedule,  Dosage? dosePerIntake,  PackStock? stock,  String? notes,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Medication():
return $default(_that.id,_that.name,_that.form,_that.type,_that.schedule,_that.dosePerIntake,_that.stock,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MedicationId id,  String name,  MedicationForm form,  MedicationType type,  Schedule schedule,  Dosage? dosePerIntake,  PackStock? stock,  String? notes,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Medication() when $default != null:
return $default(_that.id,_that.name,_that.form,_that.type,_that.schedule,_that.dosePerIntake,_that.stock,_that.notes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _Medication implements Medication {
  const _Medication({required this.id, required this.name, required this.form, required this.type, required this.schedule, this.dosePerIntake, this.stock, this.notes, required this.createdAt});
  

/// Stable, typed identifier for this medication.
@override final  MedicationId id;
/// User-facing display name of the medication.
@override final  String name;
/// Physical form the medication is taken in (tablet, syrup, …).
@override final  MedicationForm form;
/// Temporal pattern of intake: continuous or a bounded/cyclic course.
@override final  MedicationType type;
/// The recurring intake plan (frequency + time slots).
@override final  Schedule schedule;
/// Default dose taken at each occurrence. `null` when no default dose is
/// recorded (individual [TimeSlot]s may still carry per-slot overrides).
@override final  Dosage? dosePerIntake;
/// On-hand inventory tracking. `null` when stock is not tracked for this
/// medication.
@override final  PackStock? stock;
/// Free-form user notes. `null` when none were entered.
@override final  String? notes;
/// Timestamp at which this medication record was created.
@override final  DateTime createdAt;

/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicationCopyWith<_Medication> get copyWith => __$MedicationCopyWithImpl<_Medication>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Medication&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.form, form) || other.form == form)&&(identical(other.type, type) || other.type == type)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.dosePerIntake, dosePerIntake) || other.dosePerIntake == dosePerIntake)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,form,type,schedule,dosePerIntake,stock,notes,createdAt);

@override
String toString() {
  return 'Medication(id: $id, name: $name, form: $form, type: $type, schedule: $schedule, dosePerIntake: $dosePerIntake, stock: $stock, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MedicationCopyWith<$Res> implements $MedicationCopyWith<$Res> {
  factory _$MedicationCopyWith(_Medication value, $Res Function(_Medication) _then) = __$MedicationCopyWithImpl;
@override @useResult
$Res call({
 MedicationId id, String name, MedicationForm form, MedicationType type, Schedule schedule, Dosage? dosePerIntake, PackStock? stock, String? notes, DateTime createdAt
});


@override $MedicationIdCopyWith<$Res> get id;@override $MedicationTypeCopyWith<$Res> get type;@override $ScheduleCopyWith<$Res> get schedule;@override $DosageCopyWith<$Res>? get dosePerIntake;@override $PackStockCopyWith<$Res>? get stock;

}
/// @nodoc
class __$MedicationCopyWithImpl<$Res>
    implements _$MedicationCopyWith<$Res> {
  __$MedicationCopyWithImpl(this._self, this._then);

  final _Medication _self;
  final $Res Function(_Medication) _then;

/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? form = null,Object? type = null,Object? schedule = null,Object? dosePerIntake = freezed,Object? stock = freezed,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_Medication(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as MedicationId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,form: null == form ? _self.form : form // ignore: cast_nullable_to_non_nullable
as MedicationForm,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MedicationType,schedule: null == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as Schedule,dosePerIntake: freezed == dosePerIntake ? _self.dosePerIntake : dosePerIntake // ignore: cast_nullable_to_non_nullable
as Dosage?,stock: freezed == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as PackStock?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedicationIdCopyWith<$Res> get id {
  
  return $MedicationIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedicationTypeCopyWith<$Res> get type {
  
  return $MedicationTypeCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScheduleCopyWith<$Res> get schedule {
  
  return $ScheduleCopyWith<$Res>(_self.schedule, (value) {
    return _then(_self.copyWith(schedule: value));
  });
}/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DosageCopyWith<$Res>? get dosePerIntake {
    if (_self.dosePerIntake == null) {
    return null;
  }

  return $DosageCopyWith<$Res>(_self.dosePerIntake!, (value) {
    return _then(_self.copyWith(dosePerIntake: value));
  });
}/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PackStockCopyWith<$Res>? get stock {
    if (_self.stock == null) {
    return null;
  }

  return $PackStockCopyWith<$Res>(_self.stock!, (value) {
    return _then(_self.copyWith(stock: value));
  });
}
}

// dart format on
