# Task 6: Wire router pilot + startup registration

**Agent**: mobile-engineer
**Files**: `lib/core/routing/app_router.dart`, `lib/app_bootstrap.dart`
**Depends on**: 4
**Review checkpoint**: Yes
**Context docs**: `docs/architecture.md` (router error branch description at `:108`)
**Status**: Complete

## Completion Notes
**Completed**: 2026-06-01
**Files changed**: `lib/core/routing/app_router.dart`, `lib/app_bootstrap.dart`
**Contract**: Expects 3/3 verified | Produces 3/3 verified (adjusted: logging via `errorBuilder`, NOT `onException` — see deviation)
**Code review**: APPROVE WITH WARNINGS → both addressed (W1: `ref.watch`→`ref.read` for the discarded startup logger init in AppBootstrap; W2: hoisted `final logger = ref.read(loggerProvider)` into the `appRouter` body, out of the errorBuilder closure).
**DEVIATION from plan**: Plan specified `GoRouter.onException`. **go_router 17.2.0 asserts (router.dart:255) "Only one of onException, errorPageBuilder, or errorBuilder can be provided."** The router already uses `errorBuilder` for `_RouterErrorScreen`, so `onException` would have removed the error screen (violating AC-9). Used the plan's documented fallback instead: log inside the existing `errorBuilder` with an `identical(error, lastLoggedError)` once-per-error guard, still returning `const _RouterErrorScreen()`. `_RouterErrorScreen` byte-identical (verified via git show). `state.error` flows through the sanitizer; message is a static string. Bootstrap reads `loggerProvider` once at startup so the listener registers before any route can fail. Full suite (285) green.

**Description**:
The first real consumer of the logger, proving the `loggerProvider` → sanitizer → sink pipeline end-to-end. Log routing failures through the logger via `go_router`'s `onException` (fires once per failed match — not on every rebuild like `errorBuilder` would). Separately, ensure the logger listener is configured at startup by reading `loggerProvider` once in `AppBootstrap` (required because `main()` is synchronous and wraps `ProviderScope`). Layer-boundary crossing — first presentation-layer task after the core infra.

**Change details**:
- In `lib/core/routing/app_router.dart`:
  - Add an `onException:` argument to the `GoRouter(...)` constructor. In its callback, obtain the logger via `ref.read(loggerProvider)` (the `appRouter(Ref ref)` provider scope already has `ref`) and log the routing error (`state.error`) at `warning`/`severe`, passing the error object so the sanitizer redacts it.
  - Leave `errorBuilder` and `_RouterErrorScreen` **unchanged** — the visible UI must stay byte-identical.
  - Verify `onException` exists on `go_router ^17.2.0` (it does since v7). If absent, fall back to a one-shot guarded log inside `errorBuilder`.
- In `lib/app_bootstrap.dart`:
  - Read `loggerProvider` once during startup (e.g. `ref.watch(loggerProvider)` in the relevant build/init point) so the `Logger.root` listener is registered before any route can fail.

**Done when**:
- [ ] `app_router.dart`'s `GoRouter` has an `onException` that reads `loggerProvider` and logs `state.error`
- [ ] `_RouterErrorScreen` and `errorBuilder` are unchanged (UI byte-identical)
- [ ] `app_bootstrap.dart` reads `loggerProvider` once at startup
- [ ] Logging fires once per routing error, not per widget rebuild
- [ ] `dart analyze` passes on changed files
- [ ] Existing router/bootstrap tests still pass

**Spec criteria addressed**: AC-9

## Contracts

### Expects
- `lib/core/logging/logger.dart` exports `loggerProvider` (Task 4).
- `lib/core/routing/app_router.dart` has `@Riverpod(keepAlive: true) GoRouter appRouter(Ref ref)` with a `GoRouter(...)` having `errorBuilder` and a private `_RouterErrorScreen`.
- `lib/app_bootstrap.dart` exists and runs inside the `ProviderScope`.

### Produces
- `lib/core/routing/app_router.dart` contains `onException:` on the `GoRouter` and a `ref.read(loggerProvider)` (or captured `ref`) call within it.
- `lib/app_bootstrap.dart` contains a read of `loggerProvider`.
- `_RouterErrorScreen` class body is unchanged.
