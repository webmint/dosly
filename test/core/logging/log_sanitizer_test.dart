// Tests for [sanitizeRecord] in `lib/core/logging/log_sanitizer.dart`.
//
// Security focus: every test verifies the redact-by-default policy that
// prevents PHI (medication names, filesystem paths) from leaking into logs
// (CWE-532, CWE-209). Tests use direct assertions on absence of secret values
// rather than checking exact placeholder text, so the tests survive cosmetic
// changes to the placeholder while still catching real leaks.

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/core/logging/log_sanitizer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

/// Canonical redaction marker — mirrors the private `_redacted` constant in
/// the sanitizer. Hardcoded here so the test file has no source dependency on
/// the private const.
const String _redacted = '‹redacted›';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Builds a [LogRecord] carrying [error] and optional [stackTrace].
  LogRecord makeRecord(
    Object? error, {
    StackTrace? stackTrace,
    String message = 'test message',
  }) => LogRecord(Level.WARNING, message, 'dosly', error, stackTrace);

  /// Returns the full sanitized output string for leak-scanning.
  String fullOutput(SanitizedLog s) =>
      '${s.message} ${s.error} ${s.stack ?? ''}';

  // ---------------------------------------------------------------------------
  // Failure sanitization — one test per variant
  // ---------------------------------------------------------------------------

  group('Failure sanitization', () {
    test('should redact NotFoundFailure id and emit placeholder', () {
      const secretId = 'med-uuid-1234';
      final record = makeRecord(const NotFoundFailure(id: secretId));

      final s = sanitizeRecord(record, includeErrorDetail: false);

      expect(s.error, contains(_redacted));
      expect(s.error, isNot(contains(secretId)));
    });

    test('should redact CacheFailure message and emit placeholder', () {
      const secretMsg = 'sqlite3_open /secure/path/db.sqlite failed';
      final record = makeRecord(const CacheFailure(secretMsg));

      final s = sanitizeRecord(record, includeErrorDetail: false);

      expect(s.error, equals('CacheFailure($_redacted)'));
      expect(s.error, isNot(contains(secretMsg)));
    });

    test('should emit PermissionDeniedFailure permission verbatim', () {
      const permission = 'POST_NOTIFICATIONS';
      final record = makeRecord(const PermissionDeniedFailure(permission));

      final s = sanitizeRecord(record, includeErrorDetail: false);

      expect(s.error, equals('PermissionDeniedFailure($permission)'));
      expect(s.error, contains(permission));
    });

    test(
      'should redact NotificationScheduleFailure reason and emit placeholder',
      () {
        const secretReason = 'exact platform error string with internals';
        final record = makeRecord(
          const NotificationScheduleFailure(secretReason),
        );

        final s = sanitizeRecord(record, includeErrorDetail: false);

        expect(s.error, equals('NotificationScheduleFailure($_redacted)'));
        expect(s.error, isNot(contains(secretReason)));
      },
    );

    test('should emit ValidationFailure field and redact message', () {
      const field = 'medicationName';
      const secretMessage = 'Aspirin is not allowed here';
      final record = makeRecord(
        const ValidationFailure(field: field, message: secretMessage),
      );

      final s = sanitizeRecord(record, includeErrorDetail: false);

      expect(s.error, contains('field: $field'));
      expect(s.error, contains('message: $_redacted'));
      expect(s.error, isNot(contains(secretMessage)));
    });

    test(
      'should emit UnknownFailure with runtimeType only when includeErrorDetail is false',
      () {
        final inner = PlatformException(code: 'ERR', message: 'secret detail');
        final record = makeRecord(UnknownFailure(inner, StackTrace.current));

        final s = sanitizeRecord(record, includeErrorDetail: false);

        // Must contain the runtime type name
        expect(s.error, contains('PlatformException'));
        // Must NOT contain the secret platform message detail
        expect(s.error, isNot(contains('secret detail')));
      },
    );

    test(
      'should emit UnknownFailure with full toString when includeErrorDetail is true',
      () {
        final inner = PlatformException(code: 'ERR', message: 'visible detail');
        final record = makeRecord(UnknownFailure(inner, StackTrace.current));

        final s = sanitizeRecord(record, includeErrorDetail: true);

        expect(s.error, contains('PlatformException'));
        expect(s.error, contains('visible detail'));
      },
    );

    test(
      'should emit non-Failure object with runtimeType only when includeErrorDetail is false',
      () {
        final error = Exception('some internal exception detail');
        final record = makeRecord(error);

        final s = sanitizeRecord(record, includeErrorDetail: false);

        // Match the public type name without coupling to the SDK-private
        // `_Exception` class name (which could be renamed across Dart SDKs).
        expect(s.error, contains('Exception'));
        expect(s.error, isNot(contains('some internal exception detail')));
      },
    );

    test(
      'should emit non-Failure object with full toString when includeErrorDetail is true',
      () {
        final error = Exception('some internal exception detail');
        final record = makeRecord(error);

        final s = sanitizeRecord(record, includeErrorDetail: true);

        expect(s.error, contains('some internal exception detail'));
      },
    );

    test('should return empty error string when record carries no error', () {
      final record = makeRecord(null);

      final s = sanitizeRecord(record, includeErrorDetail: false);

      expect(s.error, equals(''));
    });
  });

  // ---------------------------------------------------------------------------
  // Mandatory PHI / platform-internal leak tests
  // ---------------------------------------------------------------------------

  group('Leak prevention', () {
    test(
      'should not leak iOS filesystem path from UnknownFailure wrapping PlatformException',
      () {
        final platformEx = PlatformException(
          code: 'IO',
          message:
              '/Users/me/Library/Developer/CoreSimulator/db.sqlite write failed',
        );
        final record = makeRecord(
          UnknownFailure(platformEx, StackTrace.current),
        );

        final s = sanitizeRecord(record, includeErrorDetail: false);
        final output = fullOutput(s);

        expect(output, isNot(contains('/Users/me/Library')));
        expect(output, isNot(contains('db.sqlite')));
      },
    );

    test('should not leak medication name from ValidationFailure message', () {
      final record = makeRecord(
        const ValidationFailure(
          field: 'name',
          message: 'Aspirin is not a valid name',
        ),
      );

      final s = sanitizeRecord(record, includeErrorDetail: false);
      final output = fullOutput(s);

      expect(output, isNot(contains('Aspirin')));
    });

    test(
      'should not leak Android shared-prefs path from CacheFailure message',
      () {
        final record = makeRecord(
          const CacheFailure(
            'FileSystemException: /data/data/app.dosly/shared_prefs/prefs.xml not found',
          ),
        );

        final s = sanitizeRecord(record, includeErrorDetail: false);
        final output = fullOutput(s);

        expect(output, isNot(contains('/data/data/app.dosly')));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // includeErrorDetail flag
  // ---------------------------------------------------------------------------

  group('includeErrorDetail flag', () {
    test('false suppresses full toString, true exposes it', () {
      final inner = PlatformException(
        code: 'WRITE',
        message: '/private/var/containers/secret/path/dosly.db',
      );
      final st = StackTrace.current;
      final record = makeRecord(UnknownFailure(inner, st));

      final withDetail = sanitizeRecord(record, includeErrorDetail: true);
      final withoutDetail = sanitizeRecord(record, includeErrorDetail: false);

      // With detail: full toString present
      expect(withDetail.error, contains('/private/var/containers/secret/path'));

      // Without detail: sensitive path absent
      expect(
        withoutDetail.error,
        isNot(contains('/private/var/containers/secret/path')),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // _sanitizeStack UnknownFailure fallback branch
  // ---------------------------------------------------------------------------

  group('_sanitizeStack UnknownFailure fallback', () {
    test(
      'should pull stack from UnknownFailure when LogRecord.stackTrace is null',
      () {
        // All existing stack tests supply the stack via the LogRecord.stackTrace
        // argument, so the fallback branch
        //   `if (stackTrace == null && recordError is UnknownFailure) {
        //      stackTrace = recordError.stack; }`
        // (log_sanitizer.dart:157-159) is never hit.
        //
        // Here: LogRecord.stackTrace is omitted (null) but the error IS an
        // UnknownFailure carrying a real StackTrace — the fallback must pick
        // it up and produce a non-null SanitizedLog.stack.
        final someStack = StackTrace.current;
        final record = makeRecord(
          Failure.unknown(Exception('wrapped error'), someStack),
          // stackTrace argument deliberately omitted → null
        );

        final s = sanitizeRecord(record, includeErrorDetail: false);

        expect(
          s.stack,
          isNotNull,
          reason:
              'stack must be populated via the UnknownFailure fallback path',
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Stack truncation
  // ---------------------------------------------------------------------------

  group('Stack truncation', () {
    test('should truncate stack to at most 10 frames', () {
      // Synthesize a StackTrace with 30 frames.
      final longStack = StackTrace.fromString(
        List.generate(30, (i) => '#$i frame$i').join('\n'),
      );
      final record = makeRecord(
        UnknownFailure(Exception('overflow'), longStack),
      );

      final s = sanitizeRecord(record, includeErrorDetail: false);

      expect(s.stack, isNotNull);
      final lines = s.stack!.split('\n');
      expect(
        lines.length,
        lessThanOrEqualTo(10),
        reason: 'stack must be bounded to 10 frames, got ${lines.length}',
      );
    });

    test('should return null stack when record carries no stack trace', () {
      final record = makeRecord(
        const CacheFailure('some msg'),
        // no stackTrace argument
      );

      final s = sanitizeRecord(record, includeErrorDetail: false);

      expect(s.stack, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Null error
  // ---------------------------------------------------------------------------

  group('Null error', () {
    test('should produce empty error string when record.error is null', () {
      final record = LogRecord(Level.INFO, 'info log', 'dosly');

      final s = sanitizeRecord(record, includeErrorDetail: false);

      expect(s.error, equals(''));
      expect(s.stack, isNull);
      expect(s.message, equals('info log'));
    });
  });

  // ---------------------------------------------------------------------------
  // Message passthrough
  // ---------------------------------------------------------------------------

  group('Message passthrough', () {
    test('should pass through log message verbatim', () {
      const msg = 'dosly: loading settings';
      final record = makeRecord(null, message: msg);

      final s = sanitizeRecord(record, includeErrorDetail: false);

      expect(s.message, equals(msg));
    });
  });
}
