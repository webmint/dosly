# Bug 007: Top-level `GoRouter` `ChangeNotifier` never disposed

**Status**: Open
**Severity**: Critical
**Source**: audit (audits/2026-04-30-audit.md) — RECURRING from spec 007
**Reported**: 2026-04-30
**Fixed**:

## Description

`GoRouter` extends `ChangeNotifier`. It is allocated as a top-level `final` in
`lib/core/routing/app_router.dart:25` and never has `dispose()` called. For a
long-running app process the leak is bounded (one instance for the process
lifetime), which is why spec 007 marked this Low.

In adversarial mode: `MaterialApp.router` is the root of the app tree and is
never removed, so its built-in dispose path never fires. In tests that pump
multiple `MaterialApp.router(routerConfig: appRouter)` instances the singleton
is shared — listener leaks accumulate. MEMORY.md (Feature 007 Task 005) already
documents `_buildTestRouterWithSentinel()` as the workaround; this is evidence
the issue is real, not theoretical.

Audit escalated to Critical because the issue persists across spec 007 and now
later specs without remediation.

## File(s)

| File | Detail |
|------|--------|
| lib/core/routing/app_router.dart | Line 25 (top-level `final GoRouter appRouter`) |

## Evidence

`lib/core/routing/app_router.dart:22–27`:
```
/// Application singleton router instance.
///
/// Consumed by `DoslyApp` via `MaterialApp.router`.
final GoRouter appRouter = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
```

Reported by audit (code-reviewer F7, architect F9).

## Fix Notes

Suggested approach (to be confirmed in `/fix`):

Wrap the router in a `@riverpod` provider so its lifecycle ties to
`ProviderScope`:

```dart
// lib/core/routing/app_router.dart
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final router = GoRouter(routes: [...]);
  ref.onDispose(router.dispose);
  return router;
}
```

Update `app.dart` to read `ref.watch(appRouterProvider)`.

This pairs with bug 004 (introduces `riverpod_generator`) — once codegen is
adopted, this fix is mechanical.

Tests that need a fresh router can override the provider in their
`ProviderScope`, eliminating the need for `_buildTestRouterWithSentinel()` over
time.
