# Architecture

This document describes how dosly is organized. It reflects the **current** state of the codebase, not the end-state vision. More sections will be added as real features land.

## Layering

dosly follows **Clean Architecture**. Every feature folder under `lib/features/[feature]/` is expected to contain three layers:

| Layer | Purpose | May import |
|---|---|---|
| `domain/` | Entities, value objects, repository interfaces, use cases. Pure Dart. | `fpdart`, `freezed_annotation`, `meta`, `clock`, other `domain/` files |
| `data/` | Concrete repositories, data sources, DTOs, mappers. Catches exceptions, returns `Left(Failure)`. | `drift`, platform plugins, its own `domain/` |
| `presentation/` | Screens, widgets, Riverpod providers. UI only. | `flutter`, `flutter_riverpod`, its own `domain/` via providers |

Hard rules (from the [constitution](../constitution.md) §2.1):

- **`domain/` never imports `package:flutter/*`.** Domain must run in pure-Dart tests.
- **`presentation/` never imports `data/` directly.** Always go through a domain use case, exposed via a Riverpod provider.
- **Feature A never imports from feature B.** Cross-feature shared code moves into `lib/core/`.

Anything shared across features lives under `lib/core/` and must be **feature-agnostic** — it may not know about medications, schedules, or any domain concept.

> This is the first feature. No `domain/` or `data/` layers exist yet — `001-m3-theme` only introduced `core/theme/` and a one-off `features/theme_preview/presentation/` folder. The three-layer pattern above will be exercised for real by the first medication feature.

## The theme module

Theme code lives under `lib/core/theme/` because it is cross-feature, has no domain knowledge, and every screen in the app will eventually depend on it. This location is mandated by constitution §2.2.

```
lib/core/theme/
├── app_color_schemes.dart   # const ColorScheme lightColorScheme / darkColorScheme
├── app_text_theme.dart      # AppTextTheme.textTheme (M3 type scale on Roboto)
├── app_theme.dart           # AppTheme.lightTheme / darkTheme (composes the above)
└── theme_controller.dart    # ThemeController + singleton themeController
```

See [`features/theme.md`](features/theme.md) for the full walkthrough.

### The "no color literals outside `lib/core/theme/`" rule

`app_color_schemes.dart` is the **single source of truth** for every `Color(0xFF…)` literal in the app. Widgets elsewhere must read colors from `Theme.of(context).colorScheme.*` — never hardcode a hex value. This keeps the palette swappable, keeps light/dark parity automatic, and makes drift from the design source impossible without touching the one file that tests pin.

A grep for `Color(0xFF` outside `lib/core/theme/` is run as part of verification (spec `001-m3-theme` AC-14).

## App-wide state: `ListenableBuilder` + `ValueNotifier<ThemeMode>`

Dosly intends to use Riverpod for feature-level state, but it has not been introduced yet (see spec `001-m3-theme` §6 — explicitly out of scope for the first feature). For the one piece of app-wide state that exists right now — the current `ThemeMode` — the app uses plain Flutter primitives:

```dart
// lib/core/theme/theme_controller.dart
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);
  void setMode(ThemeMode mode) { value = mode; }
  void cycle() { /* system -> light -> dark -> system */ }
}

final ThemeController themeController = ThemeController();
```

```dart
// lib/app.dart
class DoslyApp extends StatelessWidget {
  const DoslyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) => MaterialApp.router(
        title: 'dosly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.value,
        routerConfig: appRouter,
      ),
    );
  }
}
```

The `ListenableBuilder` at the root of `DoslyApp` rebuilds `MaterialApp.router` whenever the controller's value changes, which flips `themeMode` and causes Flutter to re-theme the tree. No Riverpod, no `InheritedWidget`, no `setState`. Routing is delegated to `appRouter` (see [Routing](#routing) below).

The controller is **in-memory only** — it resets to `ThemeMode.system` on every app restart. Persistence will arrive with the future Settings feature, which will use drift; it is not bolted onto `ThemeController`.

## Internationalization (i18n)

Translation infrastructure lives under `lib/l10n/` at the `lib/` root, not under `lib/core/` — this follows Flutter's framework convention for ARB sources (the `arb-dir` default used by `flutter gen-l10n`). The project accepts this deviation from the `lib/core/` rule for project-authored cross-feature code because ARB files are translation assets, not authored Dart logic.

**Layer placement**: `AppLocalizations` is a presentation concern. It must never be imported from `domain/` (constitution §2.1 — domain must be pure Dart). This rule is currently moot because no `domain/` layer exists yet; it is called out here for when the first medication feature introduces one.

**Single-`!` rule**: `AppLocalizations.of(context)` returns nullable. The project's constitution §4.2.1 prohibits `!` in general, with one documented exception: `AppLocalizations.of(context)!`. That exception is exercised in exactly one place — the `context.l10n` getter in `lib/l10n/l10n_extensions.dart`. All widgets call `context.l10n.xxx`; no widget calls `AppLocalizations.of(context)` directly. This is the codebase pattern for any future "framework-nullable-but-guaranteed-non-null-in-practice" primitive: centralize the `!` in one extension, consumers stay clean.

**Fallback locale**: `lib/app.dart` contains a private `_resolveLocale` function that overrides Flutter's default resolution. Flutter's default returns the alphabetically-first supported locale for unsupported devices — because `gen_l10n` emits `[de, en, uk]` alphabetically, the default would surface German as the fallback. `_resolveLocale` pins the fallback to English regardless of list order.

**Generated files**: Generated `app_localizations*.dart` files are committed to `lib/l10n/` (not gitignored). With `synthetic-package: false` (modern Flutter default), they are normal source files. Committing them ensures fresh clones compile before `flutter pub get` runs — the same policy the project will apply to freezed/drift/riverpod codegen when those land.

See [`features/i18n.md`](features/i18n.md) for the full walkthrough, including how to add a new string or locale.

## Routing

dosly uses **`go_router`** as its routing foundation. The router is declared as a top-level singleton in `lib/core/routing/app_router.dart` and consumed by `DoslyApp` via `MaterialApp.router(routerConfig: appRouter)`.

### Route topology

The router uses a `StatefulShellRoute.indexedStack` to wrap the three primary tab destinations inside a shared `AppShell` scaffold, plus sibling top-level `GoRoute`s for screens that render outside the shell (no bottom nav): `/settings` (the settings screen, pushed from the home gear icon) and the dev-only `/theme-preview`.

```dart
// lib/core/routing/app_router.dart
final GoRouter appRouter = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/',       builder: ...)]),
        StatefulShellBranch(routes: [GoRoute(path: '/meds',   builder: ...)]),
        StatefulShellBranch(routes: [GoRoute(path: '/history',builder: ...)]),
      ],
    ),
    GoRoute(path: '/settings', builder: ...),
    GoRoute(path: '/theme-preview', builder: ...),
  ],
);
```

Branch order matches `AppBottomNav` destination order (0 = Today, 1 = Meds, 2 = History). Reordering either side without updating the other breaks tab highlighting.

**Route table:**

| Path | Screen | Shell | Notes |
|---|---|---|---|
| `/` | `HomeScreen` | yes | App entry — Today tab placeholder |
| `/meds` | `MedsScreen` | yes | Meds tab placeholder |
| `/history` | `HistoryScreen` | yes | History tab placeholder |
| `/settings` | `SettingsScreen` | no | Push destination from home gear icon |
| `/theme-preview` | `ThemePreviewScreen` | no | Dev-only; scheduled for post-MVP removal |

### AppShell

`AppShell` (in `lib/core/routing/app_shell.dart`) is the adapter between go_router's `StatefulNavigationShell` and the core `AppBottomNav` widget (in `lib/core/widgets/app_bottom_nav.dart`). It renders a `Scaffold` with `navigationShell` as the `body` and `AppBottomNav` as the `bottomNavigationBar`:

```dart
// lib/core/routing/app_shell.dart
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
      ),
    );
  }
}
```

`navigationShell.goBranch` is a method tearoff that satisfies `ValueChanged<int>` directly — no lambda wrapper needed. Each branch's screen supplies its own `AppBar`; the shell intentionally omits one.

`StatefulShellRoute.indexedStack` preserves each branch's navigator stack across tab switches — navigating away from a branch and back restores its scroll position and back stack. This is the standard go_router idiom for persistent-state tabbed navigation.

### Conventions

- **`lib/core/routing/` is the composition root for routes.** It is the only place in the app allowed to import from multiple feature folders simultaneously — the documented exception to the "feature A never imports feature B" rule.
- **`appRouter` mirrors the `themeController` pattern** — a top-level `final` declared next to its module, not a Riverpod provider. Riverpod will arrive with the first real feature; the router was deliberately kept on plain primitives.
- **Navigation is `context.go(...)` / `context.push(...)`** from `package:go_router/go_router.dart`, not `Navigator.of(context)`.
- **`AppBottomNav` is router-agnostic.** It accepts `int` + `ValueChanged<int>` — plain values, not a `StatefulNavigationShell`. `AppShell` is the only coupling point.

## Entry point

`lib/main.dart` is deliberately tiny — it exists only to call `runApp`:

```dart
import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  runApp(const DoslyApp());
}
```

All wiring happens in `lib/app.dart`. Future async bootstrap (database open, notification scheduler init) will go into `main()` before `runApp`, per constitution §4.2.1 ("never block `main()` on async work" — show a splash, run setup, then `runApp`).

## Related

- [constitution.md](../constitution.md) — the full rule set
- [features/theme.md](features/theme.md) — the theme feature walkthrough
- [specs/001-m3-theme/plan.md](../specs/001-m3-theme/plan.md) — the plan that drove this first feature
