# Bug 006: `Failure` hierarchy missing 6 of 7 mandated variants; not freezed

**Status**: Open
**Severity**: Critical
**Source**: audit (audits/2026-04-30-audit.md)
**Reported**: 2026-04-30
**Fixed**:

## Description

Constitution §3.2 prescribes a sealed `freezed` union with seven variants:

```dart
@freezed
sealed class Failure with _$Failure {
  const factory Failure.notFound({String? id}) = NotFoundFailure;
  const factory Failure.cache(String message) = CacheFailure;
  const factory Failure.permissionDenied(String permission) = PermissionDeniedFailure;
  const factory Failure.notificationSchedule(String reason) = NotificationScheduleFailure;
  const factory Failure.validation({required String field, required String message}) = ValidationFailure;
  const factory Failure.unknown(Object error, StackTrace stack) = UnknownFailure;
}
```

Actual `lib/core/error/failures.dart` declares only a hand-rolled
`sealed class Failure` base + a single `CacheFailure` subclass. Six variants
are missing: `NotFoundFailure`, `PermissionDeniedFailure`,
`NotificationScheduleFailure`, `ValidationFailure`, `UnknownFailure`. The class
is also not `freezed`-generated (constitution §3.1: "All entities, DTOs, and
state classes use freezed").

This blocks any future feature that needs `ValidationFailure` (e.g. AddMedication
in §7.2) or `PermissionDeniedFailure` (notifications/exact alarms). Consumers
doing exhaustive `switch` will silently compile against the lopsided shape and
need rewrites later.

Two security-adjacent risks compound: (1) `e.toString()` is currently
shovelled into `CacheFailure(message)` in `settings_repository_impl.dart`,
which can leak filesystem paths into error messages (CWE-209-adjacent).
(2) Free-form `String message` encourages future user-input concatenation.

## File(s)

| File | Detail |
|------|--------|
| lib/core/error/failures.dart | Lines 13–26 (entire file) |
| pubspec.yaml | (missing `freezed` + `freezed_annotation`) |
| lib/features/settings/data/repositories/settings_repository_impl.dart | Lines 31–37, 40–46, 51–57, 62–68 (catches funnel `e.toString()` into `CacheFailure(message)`) |

## Evidence

`lib/core/error/failures.dart:9–26`:
```
sealed class Failure {
  /// Creates a [Failure].
  const Failure();
}

/// A failure originating from local cache operations (e.g. shared preferences,
/// drift database).
class CacheFailure extends Failure {
  /// Creates a [CacheFailure] with a human-readable [message].
  const CacheFailure(this.message);

  /// Human-readable description of what went wrong.
  final String message;
}
```

Reported by audit (code-reviewer F12, architect F6, security-reviewer F3).

## Fix Notes

Suggested approach (to be confirmed in `/fix`):

1. Add `freezed` + `freezed_annotation` to `pubspec.yaml` (likely already
   needed for bug 001).
2. Re-author `lib/core/error/failures.dart` as the constitution-prescribed
   `@freezed sealed class Failure` with all 7 factory constructors.
3. Run codegen: `dart run build_runner build --delete-conflicting-outputs`.
4. Pair with bug 010: replace `Left(CacheFailure(e.toString()))` with
   `Left(Failure.unknown(e, st))` at catch sites that don't have a typed
   reason.

If the project wants to defer freezed adoption, an interim plain-Dart sealed
hierarchy with all 7 subclasses is acceptable (loses `==`/`copyWith` for free
but keeps compiler-enforced exhaustive switches).
