/// PHI-safe sanitization of `package:logging` records.
///
/// dosly is a fully-local medication tracker; medication names, dosages and
/// intake history are sensitive Protected Health Information (PHI). Any value
/// that reaches a log sink is a potential leak (CWE-532: insertion of
/// sensitive information into a log file) and, when an error's `toString()`
/// embeds platform internals such as filesystem paths or stack details, also
/// CWE-209 (information exposure through an error message).
///
/// This library is the single, isolated point where leakage is prevented. It
/// is intentionally a PURE function over a [LogRecord] — it imports neither
/// `dart:developer`, `package:flutter/*`, nor anything Riverpod — so it can be
/// exercised in complete unit-test isolation. The actual log SINK lives
/// elsewhere; this file only decides what is safe to emit.
///
/// ## Redact-by-default policy (and why)
///
/// The default disposition of every error payload is REDACTED. A value is
/// emitted verbatim only when it is provably non-PHI and non-leaking:
///
/// * type names (`runtimeType`) are always safe — they are closed,
///   developer-authored identifiers;
/// * a [PermissionDeniedFailure]'s `permission` is a fixed OS identifier
///   (e.g. `POST_NOTIFICATIONS`) — safe;
/// * a [ValidationFailure]'s `field` is a closed, enum-like identifier — safe,
///   while its `message` may quote user-entered PHI — redacted;
/// * free-form, user- or platform-derived strings ([CacheFailure.message],
///   [NotificationScheduleFailure.reason], [NotFoundFailure.id]) are redacted
///   because they can carry medication names or leak platform internals;
/// * an [UnknownFailure]'s or arbitrary object's full `toString()` is emitted
///   only when the caller explicitly opts in via `includeErrorDetail`
///   (intended for verbose/debug builds), never by default.
///
/// The `switch` over [Failure] is deliberately EXHAUSTIVE with NO `default:`
/// clause (constitution §4.1): adding a future [Failure] variant MUST break
/// compilation here so its redaction disposition is consciously decided rather
/// than silently defaulting to "leak everything".
library;

import 'package:logging/logging.dart';

import '../error/failures.dart';

/// Placeholder substituted for any value the policy classifies as unsafe.
const String _redacted = '‹redacted›';

/// Maximum number of stack-trace frames retained on a sanitized record.
///
/// Stack frames reference source files (developer code), not user data, so
/// they are considered safe — but they are bounded to keep log volume sane.
const int _maxStackFrames = 10;

/// An immutable, leak-free projection of a [LogRecord] ready for a log sink.
///
/// The [error] and [stack] fields are guaranteed by [sanitizeRecord] to be
/// free of PHI and internal-detail leakage under the redact-by-default policy.
/// The [message] field is passed through verbatim — see [SanitizedLog.message].
class SanitizedLog {
  /// Creates a sanitized log value.
  const SanitizedLog({
    required this.message,
    required this.error,
    this.stack,
  });

  /// The log message, passed through verbatim from [LogRecord.message].
  ///
  /// The sanitizer does NOT inspect or redact this string: call sites are
  /// responsible for never interpolating PHI into log messages. The guarantee
  /// this library provides is about the structured [error] payload, which is
  /// where untrusted/sensitive values realistically end up.
  final String message;

  /// The sanitized, human-debuggable rendering of the record's error.
  ///
  /// Empty string when the record carried no error. Never contains a value the
  /// policy classifies as redacted; redacted values are shown as [_redacted].
  final String error;

  /// The first [_maxStackFrames] frames of the associated stack trace, or
  /// `null` when no stack trace is available.
  final String? stack;
}

/// Converts [record] into a leak-free [SanitizedLog] under the
/// redact-by-default policy documented on this library.
///
/// [includeErrorDetail] opts in to emitting the full `toString()` of an
/// [UnknownFailure] or any other non-[Failure] error object (intended for
/// verbose/debug builds only). When `false`, only the error's `runtimeType`
/// is emitted for those cases. It NEVER widens what is emitted for the
/// known, structurally-typed [Failure] variants.
///
/// The [message] is passed through verbatim (see [SanitizedLog.message]); the
/// guarantee is about the structured error payload and the bounded stack.
SanitizedLog sanitizeRecord(
  LogRecord record, {
  required bool includeErrorDetail,
}) {
  final Object? recordError = record.error;
  final String error = recordError == null
      ? ''
      : _sanitizeError(recordError, includeErrorDetail: includeErrorDetail);

  final String? stack = _sanitizeStack(record);

  return SanitizedLog(message: record.message, error: error, stack: stack);
}

/// Renders a non-null error object into a leak-free debug string.
String _sanitizeError(Object error, {required bool includeErrorDetail}) {
  if (error is Failure) {
    // Exhaustive over the sealed Failure union — NO `default:` (constitution
    // §4.1). A new variant must force a conscious redaction decision here.
    switch (error) {
      case NotFoundFailure():
        // `id` may identify a specific medication record — redact it.
        return 'NotFoundFailure($_redacted)';
      case CacheFailure():
        // `message` today carries platform `e.toString()` (filesystem paths,
        // CWE-209) — redact it.
        return 'CacheFailure($_redacted)';
      case PermissionDeniedFailure(:final permission):
        // `permission` is a fixed OS identifier (e.g. POST_NOTIFICATIONS).
        return 'PermissionDeniedFailure($permission)';
      case NotificationScheduleFailure():
        // `reason` is a free-form platform string — redact it.
        return 'NotificationScheduleFailure($_redacted)';
      case ValidationFailure(:final field):
        // `field` is a closed, enum-like identifier; `message` may quote
        // user-entered PHI (e.g. a medication name) — redact the message only.
        return 'ValidationFailure(field: $field, message: $_redacted)';
      case UnknownFailure(error: final innerError):
        // Wrapped opaque error: type only by default, full detail on opt-in.
        return 'UnknownFailure(${_renderOpaque(innerError, includeErrorDetail: includeErrorDetail)})';
    }
  }

  // Any other non-Failure object: type only by default, full detail on opt-in.
  return _renderOpaque(error, includeErrorDetail: includeErrorDetail);
}

/// Renders an opaque error object: its `runtimeType` by default, or
/// `runtimeType: toString()` only when [includeErrorDetail] is `true`.
String _renderOpaque(Object error, {required bool includeErrorDetail}) {
  if (includeErrorDetail) {
    return '${error.runtimeType}: $error';
  }
  return '${error.runtimeType}';
}

/// Selects and bounds the stack trace for [record].
///
/// Prefers [LogRecord.stackTrace]; falls back to an [UnknownFailure]'s own
/// captured stack when the record itself carries none. Returns `null` when no
/// stack is available; otherwise the first [_maxStackFrames] frames.
String? _sanitizeStack(LogRecord record) {
  StackTrace? stackTrace = record.stackTrace;

  final Object? recordError = record.error;
  if (stackTrace == null && recordError is UnknownFailure) {
    stackTrace = recordError.stack;
  }

  if (stackTrace == null) {
    return null;
  }

  return stackTrace
      .toString()
      .split('\n')
      .take(_maxStackFrames)
      .join('\n');
}
