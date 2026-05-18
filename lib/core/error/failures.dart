/// Core failure types for the dosly application.
///
/// All domain-layer operations that can fail return `Either<Failure, T>`.
/// [Failure] is a `freezed` sealed union: each factory constructor redirects
/// to a public subclass (e.g. [CacheFailure], [ValidationFailure]) so that
/// presentation code can pattern-match exhaustively using Dart 3 sealed-class
/// switches while preserving direct-constructor call sites such as
/// `const CacheFailure('msg')`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

/// Base failure type for the dosly domain layer.
///
/// Sealed so that the compiler enforces exhaustive handling of every variant
/// in `switch` expressions. Each factory redirects to a public subclass with
/// the same constructor signature, so call sites can use either the union
/// factory (`Failure.cache('x')`) or the subclass directly (`CacheFailure('x')`).
@freezed
sealed class Failure with _$Failure {
  /// Requested entity (by [id]) was not found.
  const factory Failure.notFound({String? id}) = NotFoundFailure;

  /// Local cache operation failed (shared preferences, drift).
  const factory Failure.cache(String message) = CacheFailure;

  /// OS-level permission ([permission]) was denied by the user or system.
  const factory Failure.permissionDenied(String permission) =
      PermissionDeniedFailure;

  /// Scheduling a local notification failed for the given [reason].
  const factory Failure.notificationSchedule(String reason) =
      NotificationScheduleFailure;

  /// Domain validation failed for [field] with explanation [message].
  const factory Failure.validation({
    required String field,
    required String message,
  }) = ValidationFailure;

  /// Unanticipated error: original [error] and [stack] captured for triage.
  ///
  /// Callers MUST NOT pass user-visible strings or PII (medication names,
  /// dosages, intake history) in [error] — the default `toString()` emits
  /// `error.toString()` verbatim and may be logged.
  const factory Failure.unknown(Object error, StackTrace stack) = UnknownFailure;
}
