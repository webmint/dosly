<!-- This file is a fixed-size sliding window. Always fully overwritten, never appended. Max ~40 lines. -->
# Session State

## Current Feature
025-typed-logger — Typed logger with PHI sanitize layer

## Progress
ALL 7 tasks Complete. Feature implementation done; ready for /review → /verify → /summarize → /finalize.

## Recently Completed (last 3)
- Task 5: logger pipeline tests (levelFor, release suppression, idempotent single-emit, provider) — 6 tests
- Task 6: router pilot — errorBuilder logs state.error via loggerProvider (once-guarded); AppBootstrap reads loggerProvider at startup
- Task 7: docs/architecture.md — removed stale "deferred to Bug 017", added Logging subsection + loggerProvider row

## Recent Decisions
- package:logging (not dart:developer wrapper) — single Logger.root.onRecord listener = structural sanitize choke point
- Release no-op via levelFor(isRelease: kReleaseMode) → Level.OFF; debug → Level.ALL
- onException UNUSABLE (asserts-conflicts with errorBuilder) → logged in errorBuilder instead

## Recently Modified Files
- lib/core/logging/logger.dart, logger.g.dart, log_sanitizer.dart
- lib/core/routing/app_router.dart, lib/app_bootstrap.dart, pubspec.yaml
- test/core/logging/log_sanitizer_test.dart, logger_test.dart

## Verification
dart analyze: clean | flutter test: 285 pass
