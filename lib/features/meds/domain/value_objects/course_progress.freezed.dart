// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'course_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CourseProgress {

/// 1-based day within the current active window (never `0`, never above
/// [totalDays]).
 int get currentDay;/// Number of active intake days in a single course window.
 int get totalDays;/// Whether the medication is currently in an active window or a paused gap.
 CoursePhase get phase;
/// Create a copy of CourseProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseProgressCopyWith<CourseProgress> get copyWith => _$CourseProgressCopyWithImpl<CourseProgress>(this as CourseProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseProgress&&(identical(other.currentDay, currentDay) || other.currentDay == currentDay)&&(identical(other.totalDays, totalDays) || other.totalDays == totalDays)&&(identical(other.phase, phase) || other.phase == phase));
}


@override
int get hashCode => Object.hash(runtimeType,currentDay,totalDays,phase);

@override
String toString() {
  return 'CourseProgress(currentDay: $currentDay, totalDays: $totalDays, phase: $phase)';
}


}

/// @nodoc
abstract mixin class $CourseProgressCopyWith<$Res>  {
  factory $CourseProgressCopyWith(CourseProgress value, $Res Function(CourseProgress) _then) = _$CourseProgressCopyWithImpl;
@useResult
$Res call({
 int currentDay, int totalDays, CoursePhase phase
});




}
/// @nodoc
class _$CourseProgressCopyWithImpl<$Res>
    implements $CourseProgressCopyWith<$Res> {
  _$CourseProgressCopyWithImpl(this._self, this._then);

  final CourseProgress _self;
  final $Res Function(CourseProgress) _then;

/// Create a copy of CourseProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentDay = null,Object? totalDays = null,Object? phase = null,}) {
  return _then(_self.copyWith(
currentDay: null == currentDay ? _self.currentDay : currentDay // ignore: cast_nullable_to_non_nullable
as int,totalDays: null == totalDays ? _self.totalDays : totalDays // ignore: cast_nullable_to_non_nullable
as int,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as CoursePhase,
  ));
}

}


/// Adds pattern-matching-related methods to [CourseProgress].
extension CourseProgressPatterns on CourseProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseProgress value)  $default,){
final _that = this;
switch (_that) {
case _CourseProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseProgress value)?  $default,){
final _that = this;
switch (_that) {
case _CourseProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentDay,  int totalDays,  CoursePhase phase)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseProgress() when $default != null:
return $default(_that.currentDay,_that.totalDays,_that.phase);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentDay,  int totalDays,  CoursePhase phase)  $default,) {final _that = this;
switch (_that) {
case _CourseProgress():
return $default(_that.currentDay,_that.totalDays,_that.phase);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentDay,  int totalDays,  CoursePhase phase)?  $default,) {final _that = this;
switch (_that) {
case _CourseProgress() when $default != null:
return $default(_that.currentDay,_that.totalDays,_that.phase);case _:
  return null;

}
}

}

/// @nodoc


class _CourseProgress implements CourseProgress {
  const _CourseProgress({required this.currentDay, required this.totalDays, required this.phase});
  

/// 1-based day within the current active window (never `0`, never above
/// [totalDays]).
@override final  int currentDay;
/// Number of active intake days in a single course window.
@override final  int totalDays;
/// Whether the medication is currently in an active window or a paused gap.
@override final  CoursePhase phase;

/// Create a copy of CourseProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseProgressCopyWith<_CourseProgress> get copyWith => __$CourseProgressCopyWithImpl<_CourseProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseProgress&&(identical(other.currentDay, currentDay) || other.currentDay == currentDay)&&(identical(other.totalDays, totalDays) || other.totalDays == totalDays)&&(identical(other.phase, phase) || other.phase == phase));
}


@override
int get hashCode => Object.hash(runtimeType,currentDay,totalDays,phase);

@override
String toString() {
  return 'CourseProgress(currentDay: $currentDay, totalDays: $totalDays, phase: $phase)';
}


}

/// @nodoc
abstract mixin class _$CourseProgressCopyWith<$Res> implements $CourseProgressCopyWith<$Res> {
  factory _$CourseProgressCopyWith(_CourseProgress value, $Res Function(_CourseProgress) _then) = __$CourseProgressCopyWithImpl;
@override @useResult
$Res call({
 int currentDay, int totalDays, CoursePhase phase
});




}
/// @nodoc
class __$CourseProgressCopyWithImpl<$Res>
    implements _$CourseProgressCopyWith<$Res> {
  __$CourseProgressCopyWithImpl(this._self, this._then);

  final _CourseProgress _self;
  final $Res Function(_CourseProgress) _then;

/// Create a copy of CourseProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentDay = null,Object? totalDays = null,Object? phase = null,}) {
  return _then(_CourseProgress(
currentDay: null == currentDay ? _self.currentDay : currentDay // ignore: cast_nullable_to_non_nullable
as int,totalDays: null == totalDays ? _self.totalDays : totalDays // ignore: cast_nullable_to_non_nullable
as int,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as CoursePhase,
  ));
}


}

// dart format on
