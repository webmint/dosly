/// Application logging pipeline composition root.
///
/// Defines the single funnel through which every log record flows:
///
///   call site (`Logger('dosly').warning(...)`)
///     → `package:logging` `Logger.root`
///     → the one `Logger.root.onRecord` listener registered here
///     → [sanitizeRecord] (the PHI-redaction choke point, from
///       `log_sanitizer.dart`)
///     → a [LogSink] (default: `dart:developer`).
///
/// ## Single choke point
///
/// There is exactly ONE `Logger.root.onRecord.listen` registration in this
/// file. Every record — regardless of which named [Logger] produced it —
/// passes through [sanitizeRecord] before reaching any sink, so leak
/// prevention can never be bypassed by a call site.
///
/// ## Release no-op
///
/// In release builds [levelFor] selects [Level.OFF], which suppresses all
/// records at the root level: no record is ever delivered to the listener, so
/// the pipeline is an effective no-op with zero sink cost in production.
///
/// ## Testability seams
///
/// [levelFor], [configureLogging] and the [LogSink] typedef are top-level and
/// independently callable. Tests drive [configureLogging] with explicit
/// `level`/`includeErrorDetail` values and a capturing [LogSink], without
/// touching `kReleaseMode`/`kDebugMode` or `dart:developer`.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'log_sanitizer.dart';

part 'logger.g.dart';

/// Selects the root log [Level] for the current build mode.
///
/// Returns [Level.OFF] in release builds — suppressing every record at the
/// root so the pipeline is a true no-op — and [Level.ALL] otherwise. Kept
/// pure (no `kReleaseMode` read) so tests can exercise both branches with an
/// explicit [isRelease] value.
Level levelFor({required bool isRelease}) =>
    isRelease ? Level.OFF : Level.ALL;

/// Destination for a sanitized log record.
///
/// Receives the already-[sanitizeRecord]-processed [SanitizedLog] together
/// with the originating record's [Level]. Injected into [configureLogging] so
/// tests can substitute a capturing sink for the default `dart:developer` one.
typedef LogSink = void Function(SanitizedLog log, Level level);

/// Default [LogSink] that forwards a sanitized record to `dart:developer`.
///
/// Joins [SanitizedLog.message] with [SanitizedLog.error] (when present) and
/// reconstructs a [StackTrace] from [SanitizedLog.stack] when available.
void _developerLogSink(SanitizedLog log, Level level) {
  final String? stack = log.stack;
  developer.log(
    log.error.isEmpty ? log.message : '${log.message} | ${log.error}',
    name: 'dosly',
    level: level.value,
    stackTrace: stack == null ? null : StackTrace.fromString(stack),
  );
}

/// The currently-installed root listener subscription, if any.
///
/// Tracked at module level so [configureLogging] can cancel a prior listener
/// before installing a new one — guaranteeing exactly one active
/// `Logger.root` listener regardless of how many times it is called (e.g.
/// across test [ProviderContainer]s). This is what makes the pipeline
/// idempotent (spec AC-3).
StreamSubscription<LogRecord>? _activeSubscription;

/// Configures `Logger.root` and registers the single pipeline listener.
///
/// Cancels any previously-installed listener first, then sets [Logger.root]'s
/// level to [level] and attaches the ONE `Logger.root.onRecord` listener for
/// the app. Because the prior subscription is always cancelled, this function
/// is idempotent: at most one active `Logger.root` listener exists no matter
/// how many times it is called (so registering the pipeline twice does not
/// double-emit — spec AC-3). Every emitted record is funneled through
/// [sanitizeRecord] (the choke point) with the given [includeErrorDetail]
/// policy before being handed to [sink].
///
/// Returns the [StreamSubscription] so the caller owns its lifetime and can
/// cancel it (e.g. via `ref.onDispose`); this function does not cancel itself.
StreamSubscription<LogRecord> configureLogging({
  required Level level,
  required bool includeErrorDetail,
  LogSink sink = _developerLogSink,
}) {
  _activeSubscription?.cancel();
  Logger.root.level = level;
  final subscription = Logger.root.onRecord.listen((record) {
    sink(
      sanitizeRecord(record, includeErrorDetail: includeErrorDetail),
      record.level,
    );
  });
  _activeSubscription = subscription;
  return subscription;
}

/// Keep-alive provider exposing the app-wide named [Logger].
///
/// This is the consumption point for the logging pipeline: on first build it
/// calls [configureLogging] (level from [levelFor] / `kReleaseMode`, error
/// detail from `kDebugMode`) and binds the resulting subscription's
/// cancellation to the provider lifetime via `ref.onDispose`.
///
/// Call sites log through the returned instance, e.g.
/// `ref.read(loggerProvider).warning('msg', failure)`.
@Riverpod(keepAlive: true)
Logger logger(Ref ref) {
  final subscription = configureLogging(
    level: levelFor(isRelease: kReleaseMode),
    includeErrorDetail: kDebugMode,
  );
  ref.onDispose(subscription.cancel);
  // `Logger('dosly')` returns the canonical interned instance for that name
  // (package:logging caches by name), not a new instance each call — so
  // repeated provider reads all share the one named logger.
  return Logger('dosly');
}
