# Bug 012: `appRouter` dartdoc out of sync with code (`/settings` route undocumented)

**Status**: Fixed
**Severity**: Warning
**Source**: audit (audits/2026-04-30-audit.md)
**Reported**: 2026-04-30
**Fixed**: 2026-05-23 (resolved incidentally by commits bd2a1fe and 631fd69 — see Resolution)

## Description

The library-level dartdoc on `lib/core/routing/app_router.dart` describes the
shell + a single sibling top-level `GoRoute` for `/theme-preview` (silent on
`/settings`). But the actual code at lines 57–60 also routes `/settings` at
the same level (above the `/theme-preview` TODO).

Routing config is a maintenance landmine when docs and code disagree — the
next contributor reading the dartdoc will have an incomplete mental model of
the app's IA.

## File(s)

| File | Detail |
|------|--------|
| lib/core/routing/app_router.dart | Lines 1–11 (library dartdoc); lines 57–60 (`/settings` route — undocumented in dartdoc) |

## Evidence

`lib/core/routing/app_router.dart:1–11`:
```
/// Application routing composition root.
///
/// Declares the top-level [appRouter] — a `StatefulShellRoute.indexedStack`
/// with three branches (Home `/`, Meds `/meds`, History `/history`) sharing
/// a single [AppShell] scaffold + [AppBottomNav], plus a sibling top-level
/// [GoRoute] for `/theme-preview` that renders WITHOUT the shell (so the
/// dev-preview screen has no bottom nav).
///
/// Branch order matches [AppBottomNav] destination order (0=Today, 1=Meds,
/// 2=History). Do not reorder without updating the bottom nav.
library;
```

`lib/core/routing/app_router.dart:57–60`:
```
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
```

Reported by audit (architect F9 supplementary observation).

## Fix Notes

Update the library dartdoc to enumerate ALL top-level non-shell routes:

```
/// ... plus sibling top-level [GoRoute]s for `/settings` (the SettingsScreen)
/// and `/theme-preview` (the dev-preview screen) that render WITHOUT the
/// shell (so neither has the bottom nav).
```

Trivial one-comment fix. Bundle with bug 007 or bug 008 since they all touch
`lib/core/routing/app_router.dart`.

## Resolution

Resolved incidentally by later work on the same file (as the Fix Notes
anticipated):

- `bd2a1fe` *fix(core/routing): bind GoRouter lifecycle via @Riverpod provider
  (bug 007)* — rewrote the library dartdoc to describe `[appRouterProvider]`
  and now enumerates the `/settings` sibling route (current lines 6–7).
- `631fd69` *feat(theme_preview): remove dev-only theme preview feature* —
  removed the `/theme-preview` route from the app and its dartdoc mention.

As of 2026-05-23 the library dartdoc on `lib/core/routing/app_router.dart`
accurately matches the code: three shell branches (Home `/`, Meds `/meds`,
History `/history`) plus the `/settings` sibling route, with no stale
`/theme-preview` reference. No remaining drift; no fix required.
