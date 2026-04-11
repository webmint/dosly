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

## Routing

dosly uses **`go_router`** as its routing foundation. The router is declared as a top-level singleton in `lib/core/routing/app_router.dart` and consumed by `DoslyApp` via `MaterialApp.router(routerConfig: appRouter)`.

```dart
// lib/core/routing/app_router.dart
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/theme-preview',
      builder: (context, state) => const ThemePreviewScreen(),
    ),
  ],
);
```

The route table is currently flat and minimal:

| Path | Screen | Notes |
|---|---|---|
| `/` | `HomeScreen` | App entry — placeholder until the real main screen ships |
| `/theme-preview` | `ThemePreviewScreen` | Dev-only, reachable via a button on `HomeScreen`. Scheduled for removal post-MVP along with `lib/features/theme_preview/`. |

A few conventions to note:

- **`lib/core/routing/` is the composition root for routes.** It is the only place in the app allowed to import from multiple feature folders simultaneously — this is the documented exception to the "feature A never imports feature B" rule, because the router by definition has to know about every screen.
- **`appRouter` mirrors the `themeController` pattern** — a top-level `final` declared next to its module, not a Riverpod provider. Riverpod will arrive with the first real feature; the router was deliberately kept on plain primitives to match the existing app-wide state style.
- **Navigation is `context.go(...)` / `context.push(...)`** from `package:go_router/go_router.dart`, not `Navigator.of(context)`.

This section will grow as the route table grows. For now there is no `ShellRoute`, no nested navigation, no redirect logic, and no deep-link handling — just two flat routes.

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
