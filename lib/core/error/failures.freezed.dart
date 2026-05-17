// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failures.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Failure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Failure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure()';
}


}

/// @nodoc
class $FailureCopyWith<$Res>  {
$FailureCopyWith(Failure _, $Res Function(Failure) __);
}


/// Adds pattern-matching-related methods to [Failure].
extension FailurePatterns on Failure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NotFoundFailure value)?  notFound,TResult Function( CacheFailure value)?  cache,TResult Function( PermissionDeniedFailure value)?  permissionDenied,TResult Function( NotificationScheduleFailure value)?  notificationSchedule,TResult Function( ValidationFailure value)?  validation,TResult Function( UnknownFailure value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NotFoundFailure() when notFound != null:
return notFound(_that);case CacheFailure() when cache != null:
return cache(_that);case PermissionDeniedFailure() when permissionDenied != null:
return permissionDenied(_that);case NotificationScheduleFailure() when notificationSchedule != null:
return notificationSchedule(_that);case ValidationFailure() when validation != null:
return validation(_that);case UnknownFailure() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NotFoundFailure value)  notFound,required TResult Function( CacheFailure value)  cache,required TResult Function( PermissionDeniedFailure value)  permissionDenied,required TResult Function( NotificationScheduleFailure value)  notificationSchedule,required TResult Function( ValidationFailure value)  validation,required TResult Function( UnknownFailure value)  unknown,}){
final _that = this;
switch (_that) {
case NotFoundFailure():
return notFound(_that);case CacheFailure():
return cache(_that);case PermissionDeniedFailure():
return permissionDenied(_that);case NotificationScheduleFailure():
return notificationSchedule(_that);case ValidationFailure():
return validation(_that);case UnknownFailure():
return unknown(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NotFoundFailure value)?  notFound,TResult? Function( CacheFailure value)?  cache,TResult? Function( PermissionDeniedFailure value)?  permissionDenied,TResult? Function( NotificationScheduleFailure value)?  notificationSchedule,TResult? Function( ValidationFailure value)?  validation,TResult? Function( UnknownFailure value)?  unknown,}){
final _that = this;
switch (_that) {
case NotFoundFailure() when notFound != null:
return notFound(_that);case CacheFailure() when cache != null:
return cache(_that);case PermissionDeniedFailure() when permissionDenied != null:
return permissionDenied(_that);case NotificationScheduleFailure() when notificationSchedule != null:
return notificationSchedule(_that);case ValidationFailure() when validation != null:
return validation(_that);case UnknownFailure() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? id)?  notFound,TResult Function( String message)?  cache,TResult Function( String permission)?  permissionDenied,TResult Function( String reason)?  notificationSchedule,TResult Function( String field,  String message)?  validation,TResult Function( Object error,  StackTrace stack)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NotFoundFailure() when notFound != null:
return notFound(_that.id);case CacheFailure() when cache != null:
return cache(_that.message);case PermissionDeniedFailure() when permissionDenied != null:
return permissionDenied(_that.permission);case NotificationScheduleFailure() when notificationSchedule != null:
return notificationSchedule(_that.reason);case ValidationFailure() when validation != null:
return validation(_that.field,_that.message);case UnknownFailure() when unknown != null:
return unknown(_that.error,_that.stack);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? id)  notFound,required TResult Function( String message)  cache,required TResult Function( String permission)  permissionDenied,required TResult Function( String reason)  notificationSchedule,required TResult Function( String field,  String message)  validation,required TResult Function( Object error,  StackTrace stack)  unknown,}) {final _that = this;
switch (_that) {
case NotFoundFailure():
return notFound(_that.id);case CacheFailure():
return cache(_that.message);case PermissionDeniedFailure():
return permissionDenied(_that.permission);case NotificationScheduleFailure():
return notificationSchedule(_that.reason);case ValidationFailure():
return validation(_that.field,_that.message);case UnknownFailure():
return unknown(_that.error,_that.stack);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? id)?  notFound,TResult? Function( String message)?  cache,TResult? Function( String permission)?  permissionDenied,TResult? Function( String reason)?  notificationSchedule,TResult? Function( String field,  String message)?  validation,TResult? Function( Object error,  StackTrace stack)?  unknown,}) {final _that = this;
switch (_that) {
case NotFoundFailure() when notFound != null:
return notFound(_that.id);case CacheFailure() when cache != null:
return cache(_that.message);case PermissionDeniedFailure() when permissionDenied != null:
return permissionDenied(_that.permission);case NotificationScheduleFailure() when notificationSchedule != null:
return notificationSchedule(_that.reason);case ValidationFailure() when validation != null:
return validation(_that.field,_that.message);case UnknownFailure() when unknown != null:
return unknown(_that.error,_that.stack);case _:
  return null;

}
}

}

/// @nodoc


class NotFoundFailure implements Failure {
  const NotFoundFailure({this.id});
  

 final  String? id;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotFoundFailureCopyWith<NotFoundFailure> get copyWith => _$NotFoundFailureCopyWithImpl<NotFoundFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotFoundFailure&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'Failure.notFound(id: $id)';
}


}

/// @nodoc
abstract mixin class $NotFoundFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $NotFoundFailureCopyWith(NotFoundFailure value, $Res Function(NotFoundFailure) _then) = _$NotFoundFailureCopyWithImpl;
@useResult
$Res call({
 String? id
});




}
/// @nodoc
class _$NotFoundFailureCopyWithImpl<$Res>
    implements $NotFoundFailureCopyWith<$Res> {
  _$NotFoundFailureCopyWithImpl(this._self, this._then);

  final NotFoundFailure _self;
  final $Res Function(NotFoundFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = freezed,}) {
  return _then(NotFoundFailure(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class CacheFailure implements Failure {
  const CacheFailure(this.message);
  

 final  String message;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CacheFailureCopyWith<CacheFailure> get copyWith => _$CacheFailureCopyWithImpl<CacheFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CacheFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'Failure.cache(message: $message)';
}


}

/// @nodoc
abstract mixin class $CacheFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $CacheFailureCopyWith(CacheFailure value, $Res Function(CacheFailure) _then) = _$CacheFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$CacheFailureCopyWithImpl<$Res>
    implements $CacheFailureCopyWith<$Res> {
  _$CacheFailureCopyWithImpl(this._self, this._then);

  final CacheFailure _self;
  final $Res Function(CacheFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(CacheFailure(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PermissionDeniedFailure implements Failure {
  const PermissionDeniedFailure(this.permission);
  

 final  String permission;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PermissionDeniedFailureCopyWith<PermissionDeniedFailure> get copyWith => _$PermissionDeniedFailureCopyWithImpl<PermissionDeniedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PermissionDeniedFailure&&(identical(other.permission, permission) || other.permission == permission));
}


@override
int get hashCode => Object.hash(runtimeType,permission);

@override
String toString() {
  return 'Failure.permissionDenied(permission: $permission)';
}


}

/// @nodoc
abstract mixin class $PermissionDeniedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $PermissionDeniedFailureCopyWith(PermissionDeniedFailure value, $Res Function(PermissionDeniedFailure) _then) = _$PermissionDeniedFailureCopyWithImpl;
@useResult
$Res call({
 String permission
});




}
/// @nodoc
class _$PermissionDeniedFailureCopyWithImpl<$Res>
    implements $PermissionDeniedFailureCopyWith<$Res> {
  _$PermissionDeniedFailureCopyWithImpl(this._self, this._then);

  final PermissionDeniedFailure _self;
  final $Res Function(PermissionDeniedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? permission = null,}) {
  return _then(PermissionDeniedFailure(
null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class NotificationScheduleFailure implements Failure {
  const NotificationScheduleFailure(this.reason);
  

 final  String reason;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationScheduleFailureCopyWith<NotificationScheduleFailure> get copyWith => _$NotificationScheduleFailureCopyWithImpl<NotificationScheduleFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationScheduleFailure&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'Failure.notificationSchedule(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $NotificationScheduleFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $NotificationScheduleFailureCopyWith(NotificationScheduleFailure value, $Res Function(NotificationScheduleFailure) _then) = _$NotificationScheduleFailureCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$NotificationScheduleFailureCopyWithImpl<$Res>
    implements $NotificationScheduleFailureCopyWith<$Res> {
  _$NotificationScheduleFailureCopyWithImpl(this._self, this._then);

  final NotificationScheduleFailure _self;
  final $Res Function(NotificationScheduleFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(NotificationScheduleFailure(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ValidationFailure implements Failure {
  const ValidationFailure({required this.field, required this.message});
  

 final  String field;
 final  String message;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValidationFailureCopyWith<ValidationFailure> get copyWith => _$ValidationFailureCopyWithImpl<ValidationFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidationFailure&&(identical(other.field, field) || other.field == field)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,field,message);

@override
String toString() {
  return 'Failure.validation(field: $field, message: $message)';
}


}

/// @nodoc
abstract mixin class $ValidationFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ValidationFailureCopyWith(ValidationFailure value, $Res Function(ValidationFailure) _then) = _$ValidationFailureCopyWithImpl;
@useResult
$Res call({
 String field, String message
});




}
/// @nodoc
class _$ValidationFailureCopyWithImpl<$Res>
    implements $ValidationFailureCopyWith<$Res> {
  _$ValidationFailureCopyWithImpl(this._self, this._then);

  final ValidationFailure _self;
  final $Res Function(ValidationFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field = null,Object? message = null,}) {
  return _then(ValidationFailure(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class UnknownFailure implements Failure {
  const UnknownFailure(this.error, this.stack);
  

 final  Object error;
 final  StackTrace stack;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownFailureCopyWith<UnknownFailure> get copyWith => _$UnknownFailureCopyWithImpl<UnknownFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownFailure&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stack, stack) || other.stack == stack));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack);

@override
String toString() {
  return 'Failure.unknown(error: $error, stack: $stack)';
}


}

/// @nodoc
abstract mixin class $UnknownFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $UnknownFailureCopyWith(UnknownFailure value, $Res Function(UnknownFailure) _then) = _$UnknownFailureCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace stack
});




}
/// @nodoc
class _$UnknownFailureCopyWithImpl<$Res>
    implements $UnknownFailureCopyWith<$Res> {
  _$UnknownFailureCopyWithImpl(this._self, this._then);

  final UnknownFailure _self;
  final $Res Function(UnknownFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stack = null,}) {
  return _then(UnknownFailure(
null == error ? _self.error : error ,null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

// dart format on
