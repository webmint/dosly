// Tests for the logging pipeline wiring in `lib/core/logging/logger.dart`.
//
// Exercises testability seams: levelFor (pure), configureLogging with a
// capturing sink, and loggerProvider — without touching kReleaseMode /
// kDebugMode or dart:developer.

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/core/logging/log_sanitizer.dart';
import 'package:dosly/core/logging/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Global teardown: clear all root listeners after every test so this file
  // never leaks listener state into other test files that share Logger.root.
  // ---------------------------------------------------------------------------
  tearDown(Logger.root.clearListeners);

  // ---------------------------------------------------------------------------
  // levelFor — pure function, no I/O
  // ---------------------------------------------------------------------------

  group('levelFor', () {
    test('should return Level.OFF when isRelease is true', () {
      expect(levelFor(isRelease: true), equals(Level.OFF));
    });

    test('should return Level.ALL when isRelease is false', () {
      expect(levelFor(isRelease: false), equals(Level.ALL));
    });
  });

  // ---------------------------------------------------------------------------
  // release suppression — Level.OFF at root means zero records reach the sink
  // ---------------------------------------------------------------------------

  group('release suppression', () {
    test(
      'should deliver zero records to sink when configured with Level.OFF',
      () {
        final captured = <SanitizedLog>[];
        void sink(SanitizedLog log, Level level) => captured.add(log);

        final sub = configureLogging(
          level: Level.OFF,
          includeErrorDetail: false,
          sink: sink,
        );
        addTearDown(sub.cancel);

        // Emit at every standard level — all must be suppressed at root.
        final log = Logger('dosly');
        log.info('should be suppressed');
        log.warning('should be suppressed too');
        log.severe('even severe is suppressed');

        expect(captured, isEmpty);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // idempotent single-emit — double configureLogging must not double-emit
  // ---------------------------------------------------------------------------

  group('idempotent single-emit', () {
    test('should emit exactly one entry after two configureLogging calls '
        'and the captured entry must pass through sanitization (AC-3)', () {
      final captured = <SanitizedLog>[];
      void sink(SanitizedLog log, Level level) => captured.add(log);

      // First registration.
      final sub1 = configureLogging(
        level: Level.ALL,
        includeErrorDetail: true,
        sink: sink,
      );
      // Second registration must cancel the first listener before installing
      // its own — so only ONE listener is active.
      final sub2 = configureLogging(
        level: Level.ALL,
        includeErrorDetail: true,
        sink: sink,
      );
      addTearDown(sub1.cancel);
      addTearDown(sub2.cancel);

      // Log a CacheFailure carrying a path that the sanitizer must redact.
      const secretPath = 'secret/path/dosly.db';
      final log = Logger('dosly');
      log.warning('cache miss', const CacheFailure(secretPath));

      // Exactly one entry — proves prior listener was cancelled (not two).
      expect(captured, hasLength(1));

      // The captured entry must show sanitization: no raw secretPath and must
      // contain the ‹redacted› placeholder.
      final sanitized = captured.first;
      expect(
        sanitized.error,
        contains('‹redacted›'),
        reason: 'CacheFailure message must be redacted by the sanitizer',
      );
      expect(
        sanitized.error,
        isNot(contains(secretPath)),
        reason: 'raw secret path must not pass through the sanitizer',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // default _developerLogSink — exercises both format branches without a
  // custom capturing sink so the real default sink path runs
  // ---------------------------------------------------------------------------

  group('default _developerLogSink', () {
    // The default sink calls dart:developer.log, which never throws under the
    // test runner. We verify that configureLogging with NO custom sink argument
    // and then logging via Logger('dosly') completes normally for both branches
    // inside _developerLogSink:
    //   branch (a): record.error is empty  → dart:developer.log(message, ...)
    //   branch (b): record.error is present → dart:developer.log(msg|err, ...,
    //               stackTrace: StackTrace.fromString(stack))
    // Both calls must return normally (no throw) — confirming the default sink
    // handles both branches and the StackTrace.fromString path without crashing.

    test(
      'default sink handles a record with no error without throwing (bare-message branch)',
      () {
        final sub = configureLogging(
          level: Level.ALL,
          includeErrorDetail: false,
          // No sink: argument — exercises the real _developerLogSink default.
        );
        addTearDown(sub.cancel);

        final log = Logger('dosly');

        // Branch (a): no error attached → log.error.isEmpty == true
        // → developer.log(message, ...) with no stackTrace.
        expect(() => log.info('bare message, no error'), returnsNormally);
      },
    );

    test(
      'default sink handles a record with error and stack without throwing (join + StackTrace.fromString branch)',
      () {
        final sub = configureLogging(
          level: Level.ALL,
          includeErrorDetail: true,
          // No sink: argument — exercises the real _developerLogSink default.
        );
        addTearDown(sub.cancel);

        final log = Logger('dosly');
        final inner = Exception('some error');
        final stack = StackTrace.current;

        // Branch (b): error present → log.error.isEmpty == false
        // → developer.log('msg | error', ..., stackTrace: StackTrace.fromString(stack))
        // The UnknownFailure carries its own StackTrace so _sanitizeStack picks
        // it up and _developerLogSink wraps it in StackTrace.fromString.
        expect(
          () => log.warning(
            'message with error and stack',
            Failure.unknown(inner, stack),
          ),
          returnsNormally,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // loggerProvider — provider builds, returns a Logger, and survives logging
  // ---------------------------------------------------------------------------

  group('loggerProvider', () {
    test('should return a Logger instance from the provider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(loggerProvider);

      expect(result, isA<Logger>());
    });

    test('should not throw when logging at info, warning, and severe levels '
        'via the provider-returned Logger', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final log = container.read(loggerProvider);

      // None of these should throw — the pipeline was configured on first read.
      expect(() => log.info('x'), returnsNormally);
      expect(() => log.warning('y'), returnsNormally);
      expect(() => log.severe('z'), returnsNormally);
    });
  });
}
