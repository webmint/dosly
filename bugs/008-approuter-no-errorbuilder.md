# Bug 008: `appRouter` has no `errorBuilder` — malformed routes silently fail in release

**Status**: Fixed
**Severity**: Critical
**Source**: audit (audits/2026-04-30-audit.md) — RECURRING from spec 007
**Reported**: 2026-04-30
**Fixed**: 2026-05-18

## Description

`GoRouter` without an `errorBuilder` uses the default error screen, which is a
debug-only red widget. In release builds, navigation to an undefined path
(deep link, notification action, invalid URL scheme) shows a blank screen or a
raw Flutter error overlay.

Constitution §5.2 / §5.3 already plans notification actions that "allow marking
taken or skipped directly without opening the app" — those will navigate via
deep links. Without an `errorBuilder`, a malformed deep link silently fails in
production.

Spec 007 review flagged this as Info; persists across two specs unaddressed.
Audit escalated to Critical because the constitutional plan for notification
actions makes this a real, not hypothetical, user-facing failure mode.

## File(s)

| File | Detail |
|------|--------|
| lib/core/routing/app_router.dart | Line 25 (`appRouter` declaration — no `errorBuilder` configured) |

## Evidence

`lib/core/routing/app_router.dart:25–29`:
```
final GoRouter appRouter = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
```

(No `errorBuilder:` parameter.)

Reported by audit (code-reviewer F8).

## Fix Notes

Suggested approach (to be confirmed in `/fix`):

Add an `errorBuilder` to the `GoRouter` constructor:

```dart
errorBuilder: (context, state) => Scaffold(
  appBar: AppBar(title: Text(context.l10n.errorScreenTitle)),
  body: Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.errorScreenBody),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.go('/'),
          child: Text(context.l10n.errorScreenGoHome),
        ),
      ],
    ),
  ),
),
```

Add three new ARB keys (`errorScreenTitle`, `errorScreenBody`,
`errorScreenGoHome`) across `app_en.arb`, `app_de.arb`, `app_uk.arb`. Run
`flutter gen-l10n`.

Add a router test that pushes `/nonexistent` and asserts the error screen
renders.

Pairs naturally with bug 007 (router lifecycle) — both touch
`lib/core/routing/app_router.dart`.

## Resolution

Fixed by spec 019 (`specs/019-router-error-screen/`).

- `lib/core/routing/app_router.dart` now sets `errorBuilder: (context, state) => const _RouterErrorScreen()` on the `GoRouter` constructor.
- `_RouterErrorScreen` is a private `StatelessWidget` in the same library. It renders a localized `Scaffold` (title, body, "Go to home" `FilledButton`) using `context.l10n`. The `FilledButton.onPressed` calls `context.go('/')`.
- Three ARB keys (`errorScreenTitle`, `errorScreenBody`, `errorScreenGoHome`) added to `app_en.arb`, `app_de.arb`, `app_uk.arb` and codegen regenerated `lib/l10n/app_localizations*.dart`.
- `test/core/routing/app_router_test.dart` adds Test 7 which pushes `/nonexistent`, asserts the error screen renders without `AppBottomNav`, and verifies the "Go to home" button recovers to `HomeScreen`.
