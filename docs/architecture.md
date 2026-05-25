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

> The three-layer pattern was first exercised in full by `009-theme-settings`: `domain/entities/app_settings.dart` and `domain/repositories/settings_repository.dart` exist as pure Dart; `data/` holds the data source and repository implementation; `presentation/` holds the Riverpod providers and widgets.

> Spec `016-settings-usecases` completed the domain triangle by adding a `domain/usecases/` sublayer to the settings feature — five callable classes (`SetThemeMode`, `SetUseSystemTheme`, `SetUseSystemLanguage`, `SetManualLanguage`, `CycleThemeMode`), each with a `const` constructor taking one `SettingsRepository`. The notifier delegates all persistence through these use cases via Riverpod function providers; `ref.read(settingsRepositoryProvider)` no longer appears in any mutator body. `lib/features/settings/` is the canonical example of the full four-sublayer domain: `entities/`, `repositories/`, `usecases/`, and their corresponding `data/` and `presentation/` counterparts.

> Spec `012-settings-domain-purify` (2026-04-30) made the constitution
> §2.1 layering rule actually true for the settings feature: `lib/features/settings/domain/`
> and `lib/features/settings/data/` are now free of `package:flutter/*` imports. The
> Flutter SDK ↔ domain mapping (e.g., `AppThemeMode → ThemeMode`) is
> confined to the presentation seam in `lib/app.dart`, where four narrow
> `ref.watch(settingsNotifierProvider.select(...))` calls read the four raw entity
> fields and compute `MaterialApp.themeMode` / `locale` inline.

## The theme module

Theme code lives under `lib/core/theme/` because it is cross-feature, has no domain knowledge, and every screen in the app will eventually depend on it. This location is mandated by constitution §2.2.

```
lib/core/theme/
├── app_color_schemes.dart   # const ColorScheme lightColorScheme / darkColorScheme
├── app_text_theme.dart      # AppTextTheme.textTheme (M3 type scale on Roboto)
└── app_theme.dart           # AppTheme.lightTheme / darkTheme (composes the above)
```

See [`features/theme.md`](features/theme.md) for the full walkthrough.

### The "no color literals outside `lib/core/theme/`" rule

`app_color_schemes.dart` is the **single source of truth** for every `Color(0xFF…)` literal in the app. Widgets elsewhere must read colors from `Theme.of(context).colorScheme.*` — never hardcode a hex value. This keeps the palette swappable, keeps light/dark parity automatic, and makes drift from the design source impossible without touching the one file that tests pin.

A grep for `Color(0xFF` outside `lib/core/theme/` is run as part of verification (spec `001-m3-theme` AC-14).

## App-wide state: Riverpod + `SharedPreferences`

Dosly uses **Riverpod** (`flutter_riverpod`) for all feature-level and app-wide reactive state. It was introduced with the `009-theme-settings` feature, which also replaced the earlier `ThemeController` singleton.

`DoslyApp` is a `ConsumerWidget`. It watches `settingsNotifierProvider` with four narrow selectors — one per raw `AppSettings` field — so only an actual field change triggers a rebuild:

```dart
// lib/app.dart
class DoslyApp extends ConsumerWidget {
  const DoslyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useSystemTheme = ref.watch(
      settingsNotifierProvider.select((s) => s.useSystemTheme),
    );
    final manualThemeMode = ref.watch(
      settingsNotifierProvider.select((s) => s.manualThemeMode),
    );
    final useSystemLanguage = ref.watch(
      settingsNotifierProvider.select((s) => s.useSystemLanguage),
    );
    final manualLanguage = ref.watch(
      settingsNotifierProvider.select((s) => s.manualLanguage),
    );

    return MaterialApp.router(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: useSystemLanguage ? null : Locale(manualLanguage.code),
      themeMode: useSystemTheme
          ? ThemeMode.system
          : _toFlutterThemeMode(manualThemeMode),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
```

### Bootstrap: `SharedPreferencesWithCache`

Settings are persisted via `SharedPreferencesWithCache`, which provides a synchronous in-memory cache backed by the platform `SharedPreferences` store. Startup is **non-blocking**: `main()` is synchronous and calls `runApp` immediately. The async prefs creation is delegated to the widget tree via `AppBootstrap` (spec 021-async-startup-splash):

```dart
// lib/main.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AppBootstrap()));
}
```

`AppBootstrap` (in `lib/app_bootstrap.dart`) is a `ConsumerWidget` mounted at the root `ProviderScope`. It watches `sharedPreferencesInitProvider` — a `@riverpod` function provider that calls `SharedPreferencesWithCache.create(...)` asynchronously — and maps each `AsyncValue` state to the appropriate child:

- **loading** — renders `SplashScreen` inside a lightweight `MaterialApp` shell so the OS launch-screen hand-off is seamless.
- **error** — renders `PrefsLoadErrorScreen` inside the same shell; its Retry button calls `ref.invalidate(sharedPreferencesInitProvider)` to re-trigger the async init. Structured failure logging is deferred to Bug 017 (typed logger not yet built) — the error branch is UI-only for now.
- **data** — wraps `DoslyApp` in a nested `ProviderScope` that overrides the synchronous `sharedPreferencesProvider` with the resolved instance, preserving the settings tree's synchronous-read contract unchanged.

`sharedPreferencesProvider` (in `lib/core/providers/shared_preferences_provider.dart`) is declared with a throwing placeholder — failing to inject the override is a programmer error surfaced immediately. The override now lives in `AppBootstrap`'s data branch rather than in `main()`.

### Provider wiring

| Provider | Type | Purpose |
|---|---|---|
| `sharedPreferencesInitProvider` | `@riverpod` function (Future) | Async creation of the prefs instance; awaited by `AppBootstrap` before the sync provider is overridden |
| `sharedPreferencesProvider` | `@Riverpod(keepAlive: true)` function | App-wide prefs instance, override-injected by `AppBootstrap`'s data branch; throwing placeholder until then |
| `appRouterProvider` | `@Riverpod(keepAlive: true)` function | App-wide `GoRouter` instance with `onDispose`-bound lifecycle |
| `settingsRepositoryProvider` | `@riverpod` function (autoDispose) | Wires data source to repository |
| `settingsNotifierProvider` | `@Riverpod(keepAlive: true, name: 'settingsNotifierProvider')` class form | Current settings + mutation API |
| `settingsErrorsProvider` | `@riverpod` function (autoDispose) | Broadcast stream of persistence failures from `SettingsNotifier` (added by feature 014) |

### Failure handling

The data layer returns `Either<Failure, T>` (via `fpdart`) for all fallible operations. `lib/core/error/failures.dart` defines the sealed `Failure` hierarchy:

```dart
@freezed
sealed class Failure with _$Failure {
  const factory Failure.notFound({String? id}) = NotFoundFailure;
  const factory Failure.cache(String message) = CacheFailure;
  const factory Failure.permissionDenied(String permission) = PermissionDeniedFailure;
  const factory Failure.notificationSchedule(String reason) = NotificationScheduleFailure;
  const factory Failure.validation({required String field, required String message}) = ValidationFailure;
  const factory Failure.unknown(Object error, StackTrace stack) = UnknownFailure;
}
```

Sealed classes let callers pattern-match exhaustively. `SettingsNotifier` follows the "optimistic-write, no-update-on-failure" pattern: in-memory state is only updated when persistence succeeds. Each redirect target (`NotFoundFailure`, `CacheFailure`, `PermissionDeniedFailure`, `NotificationScheduleFailure`, `ValidationFailure`, `UnknownFailure`) is a public concrete class, so callers can pattern-match (`case CacheFailure(:final message)`) or assert (`isA<CacheFailure>()`) on the redirect name directly.

**Side-channel error-stream pattern**: when a mutator notifier needs to surface failures to the UI without changing its state shape, it owns a broadcast `StreamController<Failure>` initialized in `build()` and closed via `ref.onDispose`. Each Left fold-branch emits the failure into the controller (`_errors.add(failure)`), and a companion top-level `StreamProvider<Failure>` exposes the stream to the widget tree. Consumers subscribe with `ref.listen<AsyncValue<Failure>>(errorsProvider, (_, next) => next.whenData(...))` to trigger side-effects such as showing a SnackBar, without coupling state shape to error state. The canonical example is `settingsErrorsProvider` in `lib/features/settings/presentation/providers/settings_provider.dart`, established by spec 014. When implementing this pattern, pass only static localized strings to the SnackBar — never forward `failure.message` to UI text, as that message originates from a platform exception and is not localized, not user-safe, and may contain internal details.

`SettingsNotifier.build()` also emits to this stream on a load failure, but because `build()` runs before any subscriber attaches, the event is dropped (broadcast stream — no buffering). The observable effect at startup is `const AppSettings()` as the initial state, not a visible error (spec 022, OQ-2).

**`Failure.unknown` for uncategorized throwables**: all `SettingsRepository` methods route every caught throwable — including `Error` subtypes such as `TypeError` — to `Failure.unknown(e, st)`. `CacheFailure` is intentionally NOT used for uncategorized platform exceptions: `CacheFailure(e.toString())` would embed the raw exception string, which on some platforms includes the absolute filesystem path of the on-disk preferences store (CWE-209-adjacent). Use `Failure.unknown` whenever you are catching a bare `catch (e, st)` block and the throwable origin is a platform bridge or external I/O call.

> The earlier `ThemeController` singleton (`lib/core/theme/theme_controller.dart`) has been deleted. All theme-mode state is now owned by `settingsNotifierProvider`.

### Riverpod codegen

Provider declarations use `@riverpod` / `@Riverpod(...)` codegen (constitution §4.1.1). Run `dart run build_runner build --delete-conflicting-outputs` after editing any annotated provider; generated `*.g.dart` files sit next to their source and are committed (§2.2). The two existing exemplars are `lib/core/providers/shared_preferences_provider.dart` (function form, `@Riverpod(keepAlive: true)`) and `lib/features/settings/presentation/providers/settings_provider.dart` (mixed function and class forms).

One quirk worth knowing when adding new class-form notifiers: codegen derives the provider symbol by stripping a trailing `Notifier` from the class name and appending `Provider`. So `class FooNotifier extends _$FooNotifier` emits `fooProvider`, not `fooNotifierProvider`. Pass `name: 'fooNotifierProvider'` on the annotation to keep the canonical codegen class-form naming idiom — `settings_provider.dart` does this for `SettingsNotifier`.

## Internationalization (i18n)

Translation infrastructure lives under `lib/l10n/` at the `lib/` root, not under `lib/core/` — this follows Flutter's framework convention for ARB sources (the `arb-dir` default used by `flutter gen-l10n`). The project accepts this deviation from the `lib/core/` rule for project-authored cross-feature code because ARB files are translation assets, not authored Dart logic.

**Layer placement**: `AppLocalizations` is a presentation concern. It must never be imported from `domain/` (constitution §2.1 — domain must be pure Dart). This rule is currently moot because no `domain/` layer exists yet; it is called out here for when the first medication feature introduces one.

**Single-`!` rule**: `AppLocalizations.of(context)` returns nullable. The project's constitution §4.2.1 prohibits `!` in general, with one documented exception: `AppLocalizations.of(context)!`. That exception is exercised in exactly one place — the `context.l10n` getter in `lib/l10n/l10n_extensions.dart`. All widgets call `context.l10n.xxx`; no widget calls `AppLocalizations.of(context)` directly. This is the codebase pattern for any future "framework-nullable-but-guaranteed-non-null-in-practice" primitive: centralize the `!` in one extension, consumers stay clean.

**Fallback locale**: `lib/core/l10n/locale_resolver.dart` exports `resolveAppLocale`, the single production source of truth for the English-fallback locale policy. Flutter's default resolution returns the alphabetically-first supported locale for unsupported devices — because `gen_l10n` emits `[de, en, uk]` alphabetically, the default would surface German as the fallback. `resolveAppLocale` matches by `languageCode` and falls back to English regardless of list order. Both `lib/app.dart` and `lib/app_bootstrap.dart` pass it as `localeResolutionCallback`.

**Generated files**: Generated `app_localizations*.dart` files are committed to `lib/l10n/` (not gitignored). With `synthetic-package: false` (modern Flutter default), they are normal source files. Committing them ensures fresh clones compile before `flutter pub get` runs — the same policy the project will apply to freezed/drift/riverpod codegen when those land.

See [`features/i18n.md`](features/i18n.md) for the full walkthrough, including how to add a new string or locale.

## Routing

dosly uses **`go_router`** as its routing foundation. The router is declared as a function-form `@Riverpod(keepAlive: true)` provider in `lib/core/routing/app_router.dart` and consumed by `DoslyApp` via `MaterialApp.router(routerConfig: ref.watch(appRouterProvider))`. `ref.onDispose(router.dispose)` binds the router's `ChangeNotifier` lifecycle to the `ProviderScope`, so tests that override the provider (e.g., to inject a different route topology) get automatic teardown.

### Route topology

The router uses a `StatefulShellRoute.indexedStack` to wrap the three primary tab destinations inside a shared `AppShell` scaffold, plus sibling top-level `GoRoute`s for screens that render outside the shell (no bottom nav): `/settings` (the settings screen, pushed from the home gear icon).

```dart
// lib/core/routing/app_router.dart
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
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
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
```

Branch order matches `AppBottomNav` destination order (0 = Today, 1 = Meds, 2 = History). Reordering either side without updating the other breaks tab highlighting.

**Route table:**

| Path | Screen | Shell | Notes |
|---|---|---|---|
| `/` | `HomeScreen` | yes | App entry — Today tab placeholder |
| `/meds` | `MedsScreen` | yes | Meds tab placeholder |
| `/history` | `HistoryScreen` | yes | History tab placeholder |
| `/settings` | `SettingsScreen` | no | Push destination from home gear icon |

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
- **`appRouter` is a function-form `@Riverpod(keepAlive: true)` provider.** The emitted symbol is `appRouterProvider`. Lifecycle is bound to the `ProviderScope` via `ref.onDispose(router.dispose)`. Tests that need a different route topology override with `appRouterProvider.overrideWith((ref) { final r = ...; ref.onDispose(r.dispose); return r; })` — the override callback's `Ref` mirrors the production lifecycle binding so tests do not call `dispose()` directly. The earlier rationale for keeping the router on plain primitives (Riverpod hadn't landed yet) was retired by spec 018.
- **Navigation is `context.go(...)` / `context.push(...)`** from `package:go_router/go_router.dart`, not `Navigator.of(context)`.
- **Full-screen modals over the shell use `Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(fullscreenDialog: true, ...))`** — the only sanctioned use of the imperative `Navigator` API. `rootNavigator: true` is required so the modal covers `AppShell`'s bottom nav bar. See [`features/meds.md`](features/meds.md) for the reference implementation.
- **`AppBottomNav` is router-agnostic.** It accepts `int` + `ValueChanged<int>` — plain values, not a `StatefulNavigationShell`. `AppShell` is the only coupling point.
- **Unmatched paths render a localized error screen.** `appRouter.errorBuilder` produces a private `_RouterErrorScreen` (in `lib/core/routing/app_router.dart`) that shows a localized title/body and a "Go to home" `FilledButton` calling `context.go('/')`. This is the recovery path for malformed deep links and future notification-action payloads (constitution §5.2). The screen renders outside the `StatefulShellRoute`, so no `AppBottomNav` is visible.

## Entry point

`lib/main.dart` bootstraps the app synchronously: it calls `WidgetsFlutterBinding.ensureInitialized()` and then `runApp` immediately — no `await`, no async work. Async initialization (currently SharedPreferences hydration) is delegated to `AppBootstrap` inside the widget tree, per constitution §4.2.1 ("Never block `main()` on async work"). Future async work (database open, notification scheduler init) follows the same pattern: add a new `@riverpod` init provider and gate the dependent UI on its `AsyncValue` in `AppBootstrap`.

All UI wiring happens in `lib/app.dart`. `DoslyApp` is a `ConsumerWidget` rather than a plain `StatelessWidget`. The `ProviderScope` override for `sharedPreferencesProvider` is now injected by `AppBootstrap`'s data branch (a nested `ProviderScope`), not by `main()`. See [App-wide state](#app-wide-state-riverpod--sharedpreferences) above.

## Related

- [constitution.md](../constitution.md) — the full rule set
- [features/theme.md](features/theme.md) — the theme feature walkthrough
- [features/settings.md](features/settings.md) — Settings screen and theme-mode selector
- [specs/001-m3-theme/plan.md](../specs/001-m3-theme/plan.md) — the plan that introduced the M3 theme
- [specs/009-theme-settings/spec.md](../specs/009-theme-settings/spec.md) — the spec that introduced Riverpod, SharedPreferences, and the Failure hierarchy
