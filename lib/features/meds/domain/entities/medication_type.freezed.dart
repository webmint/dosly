// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medication_type.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MedicationType {

/// Local calendar date on which the medication regimen begins.
 DateTime get startDate;
/// Create a copy of MedicationType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicationTypeCopyWith<MedicationType> get copyWith => _$MedicationTypeCopyWithImpl<MedicationType>(this as MedicationType, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicationType&&(identical(other.startDate, startDate) || other.startDate == startDate));
}


@override
int get hashCode => Object.hash(runtimeType,startDate);

@override
String toString() {
  return 'MedicationType(startDate: $startDate)';
}


}

/// @nodoc
abstract mixin class $MedicationTypeCopyWith<$Res>  {
  factory $MedicationTypeCopyWith(MedicationType value, $Res Function(MedicationType) _then) = _$MedicationTypeCopyWithImpl;
@useResult
$Res call({
 DateTime startDate
});




}
/// @nodoc
class _$MedicationTypeCopyWithImpl<$Res>
    implements $MedicationTypeCopyWith<$Res> {
  _$MedicationTypeCopyWithImpl(this._self, this._then);

  final MedicationType _self;
  final $Res Function(MedicationType) _then;

/// Create a copy of MedicationType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startDate = null,}) {
  return _then(_self.copyWith(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MedicationType].
extension MedicationTypePatterns on MedicationType {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ContinuousType value)?  continuous,TResult Function( CourseType value)?  course,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ContinuousType() when continuous != null:
return continuous(_that);case CourseType() when course != null:
return course(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ContinuousType value)  continuous,required TResult Function( CourseType value)  course,}){
final _that = this;
switch (_that) {
case ContinuousType():
return continuous(_that);case CourseType():
return course(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ContinuousType value)?  continuous,TResult? Function( CourseType value)?  course,}){
final _that = this;
switch (_that) {
case ContinuousType() when continuous != null:
return continuous(_that);case CourseType() when course != null:
return course(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( DateTime startDate)?  continuous,TResult Function( DateTime startDate,  int durationDays,  int pauseDays)?  course,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ContinuousType() when continuous != null:
return continuous(_that.startDate);case CourseType() when course != null:
return course(_that.startDate,_that.durationDays,_that.pauseDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( DateTime startDate)  continuous,required TResult Function( DateTime startDate,  int durationDays,  int pauseDays)  course,}) {final _that = this;
switch (_that) {
case ContinuousType():
return continuous(_that.startDate);case CourseType():
return course(_that.startDate,_that.durationDays,_that.pauseDays);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( DateTime startDate)?  continuous,TResult? Function( DateTime startDate,  int durationDays,  int pauseDays)?  course,}) {final _that = this;
switch (_that) {
case ContinuousType() when continuous != null:
return continuous(_that.startDate);case CourseType() when course != null:
return course(_that.startDate,_that.durationDays,_that.pauseDays);case _:
  return null;

}
}

}

/// @nodoc


class ContinuousType implements MedicationType {
  const ContinuousType({required this.startDate});
  

/// Local calendar date on which the medication regimen begins.
@override final  DateTime startDate;

/// Create a copy of MedicationType
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContinuousTypeCopyWith<ContinuousType> get copyWith => _$ContinuousTypeCopyWithImpl<ContinuousType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContinuousType&&(identical(other.startDate, startDate) || other.startDate == startDate));
}


@override
int get hashCode => Object.hash(runtimeType,startDate);

@override
String toString() {
  return 'MedicationType.continuous(startDate: $startDate)';
}


}

/// @nodoc
abstract mixin class $ContinuousTypeCopyWith<$Res> implements $MedicationTypeCopyWith<$Res> {
  factory $ContinuousTypeCopyWith(ContinuousType value, $Res Function(ContinuousType) _then) = _$ContinuousTypeCopyWithImpl;
@override @useResult
$Res call({
 DateTime startDate
});




}
/// @nodoc
class _$ContinuousTypeCopyWithImpl<$Res>
    implements $ContinuousTypeCopyWith<$Res> {
  _$ContinuousTypeCopyWithImpl(this._self, this._then);

  final ContinuousType _self;
  final $Res Function(ContinuousType) _then;

/// Create a copy of MedicationType
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDate = null,}) {
  return _then(ContinuousType(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class CourseType implements MedicationType {
  const CourseType({required this.startDate, required this.durationDays, required this.pauseDays});
  

/// Local calendar date on which the (first) course begins.
@override final  DateTime startDate;
/// Number of active days in a single course window. The derived end date of
/// the first window is `startDate + durationDays − 1`.
 final  int durationDays;
/// Number of off days between consecutive course windows. `0` means the
/// course does not repeat; any value `> 0` makes the course cyclic.
 final  int pauseDays;

/// Create a copy of MedicationType
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseTypeCopyWith<CourseType> get copyWith => _$CourseTypeCopyWithImpl<CourseType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseType&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.pauseDays, pauseDays) || other.pauseDays == pauseDays));
}


@override
int get hashCode => Object.hash(runtimeType,startDate,durationDays,pauseDays);

@override
String toString() {
  return 'MedicationType.course(startDate: $startDate, durationDays: $durationDays, pauseDays: $pauseDays)';
}


}

/// @nodoc
abstract mixin class $CourseTypeCopyWith<$Res> implements $MedicationTypeCopyWith<$Res> {
  factory $CourseTypeCopyWith(CourseType value, $Res Function(CourseType) _then) = _$CourseTypeCopyWithImpl;
@override @useResult
$Res call({
 DateTime startDate, int durationDays, int pauseDays
});




}
/// @nodoc
class _$CourseTypeCopyWithImpl<$Res>
    implements $CourseTypeCopyWith<$Res> {
  _$CourseTypeCopyWithImpl(this._self, this._then);

  final CourseType _self;
  final $Res Function(CourseType) _then;

/// Create a copy of MedicationType
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDate = null,Object? durationDays = null,Object? pauseDays = null,}) {
  return _then(CourseType(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int,pauseDays: null == pauseDays ? _self.pauseDays : pauseDays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
