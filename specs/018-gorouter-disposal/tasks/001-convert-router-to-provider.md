# Task 001: Convert appRouter to @riverpod provider + rewire test consumers

**Agent**: mobile-engineer
**Status**: Complete
**Files**:
- `lib/core/routing/app_router.dart` (modify)
- `lib/core/routing/app_router.g.dart` (create via codegen)
- `lib/app.dart` (modify)
- `test/core/routing/app_router_test.dart` (modify)
- `test/widget_test.dart` (verify — modify only if a runtime ordering issue surfaces)

**Depends on**: None
**Blocks**: 002
**Review checkpoint**: No
**Context docs**:
- `docs/architecture.md` § Routing — current routing pattern that this task replaces
- `docs/architecture.md` § Riverpod codegen — function-form `@Riverpod(keepAlive: true)` pattern reference

## Description

Replace the top-level `final GoRouter appRouter` singleton in `lib/core/routing/app_router.dart:25` with a function-form `@Riverpod(keepAlive: true)` codegen provider that registers `ref.onDispose(router.dispose)`. Update the sole production consumer (`lib/app.dart`) to read the router via `ref.watch(appRouterProvider)`. Rewire the test pump helper in `test/core/routing/app_router_test.dart` to drop the `GoRouter` parameter and accept optional `List<Override> overrides`; rewrite Test 4 to use `appRouterProvider.overrideWith(...)` with internal `ref.onDispose(r.dispose)`. Verify `test/widget_test.dart` still passes unchanged (DoslyApp consumes the provider internally).

This closes bug 007 by binding the router's lifecycle to the `ProviderScope`, eliminating the `ChangeNotifier` leak that was being papered over by `_buildTestRouterWithSentinel` + manual `testRouter.dispose()`.

Pattern reference: `lib/core/providers/shared_preferences_provider.dart` — the project's canonical `@Riverpod(keepAlive: true)` function-form exemplar. Mirror its shape exactly.

## Change details

### `lib/core/routing/app_router.dart` — modify

Replace this block:

```dart
import 'package:go_router/go_router.dart';
import '../../features/...';
// ...

/// Application singleton router instance.
///
/// Consumed by `DoslyApp` via `MaterialApp.router`.
final GoRouter appRouter = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(...),
    GoRoute(path: '/settings', builder: ...),
    GoRoute(path: '/theme-preview', builder: ...),
  ],
);
```

With:

```dart
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/...';
// ...

part 'app_router.g.dart';

/// Application router provider.
///
/// Returns the single app-wide [GoRouter] instance and binds its
/// [GoRouter.dispose] to the [ProviderScope] lifetime via `ref.onDispose`.
/// Consumed by `DoslyApp` via `ref.watch(appRouterProvider)`.
///
/// Tests that need a different route topology override this provider with
/// `appRouterProvider.overrideWith((ref) { final r = ...; ref.onDispose(r.dispose); return r; })`.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(/* exact same body */),
      GoRoute(path: '/settings', builder: ...),
      GoRoute(path: '/theme-preview', builder: ...),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
```

- Keep every route, every branch order, every builder, every `TODO(post-mvp)` comment **byte-identical** to current.
- Do NOT add a `name:` annotation argument (per MEMORY L141; function-form emits `appRouterProvider` directly).
- Library-level dartdoc at the top of the file: keep the existing `library;` declaration; update the doc text to describe the new provider shape (current text references `appRouter` — update to `appRouterProvider`).

### Run codegen

After saving `app_router.dart`, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This creates `lib/core/routing/app_router.g.dart`. Commit it — `.g.dart` files MUST be committed (constitution §2.2). Side-effect regenerations to other `.g.dart` files (e.g., `settings_provider.g.dart`, `shared_preferences_provider.g.dart`) are expected and acceptable per MEMORY guidance for spec 015 — include them in the same commit.

### `lib/app.dart` — modify

Change exactly one line in `DoslyApp.build`:

```dart
// Before
routerConfig: appRouter,

// After
routerConfig: ref.watch(appRouterProvider),
```

Update the library-level dartdoc (lines 1–17) to replace any mention of "delegated to [appRouter]" with "delegated to [appRouterProvider]". Keep every other doc sentence intact.

The import line `import 'core/routing/app_router.dart';` stays the same — it's the source file, which still exports `appRouterProvider` (the generated symbol).

### `test/core/routing/app_router_test.dart` — modify

Three changes:

**(a) `_pumpRouter` helper rewrite** (lines 124–140):

```dart
// Before
Future<void> _pumpRouter(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// After
Future<void> _pumpRouter(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
        ...overrides,
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          routerConfig: ref.watch(appRouterProvider),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
```

**(b) Tests 1, 2, 3, 5, 6**: replace `await _pumpRouter(tester, appRouter);` with `await _pumpRouter(tester);`. Six call sites at approximate lines 153, 182, 213, 280, 309 (line numbers shift after helper edit — use grep `_pumpRouter\(tester, appRouter\)` to find all). No other change inside these test bodies.

**(c) Test 4 rewire** (lines 247–271):

```dart
// Before
testWidgets(
  'Test 4 (AC-11): branch stack is preserved when switching tabs',
  (tester) async {
    final testRouter = _buildTestRouterWithSentinel();
    await _pumpRouter(tester, testRouter);

    // ... test body ...

    testRouter.dispose();
  },
);

// After
testWidgets(
  'Test 4 (AC-11): branch stack is preserved when switching tabs',
  (tester) async {
    await _pumpRouter(
      tester,
      overrides: [
        appRouterProvider.overrideWith((ref) {
          final r = _buildTestRouterWithSentinel();
          ref.onDispose(r.dispose);
          return r;
        }),
      ],
    );

    // ... test body unchanged ...
  },
);
```

Remove the trailing `testRouter.dispose();` line. The override callback's `ref.onDispose(r.dispose)` handles teardown when the `ProviderScope` is torn down at test end.

The `_buildTestRouterWithSentinel()` function definition itself (lines 76–117) stays in place — it defines a different ROUTE TOPOLOGY (sentinel child route under `/meds`), which is the test's actual purpose.

### `test/widget_test.dart` — verify, modify only if needed

Expected: no source change. All three tests pump `DoslyApp` inside `ProviderScope`. `DoslyApp` now reads `appRouterProvider` internally — the existing test wiring is sufficient.

If `flutter test` reports a pump-ordering failure after the Task 001 source changes land, add ONE extra `await tester.pump();` before the first assertion in the failing test. Do not rewrite assertions, do not change the test's intent, do not adjust the existing `pumpAndSettle()` calls.

## Done when

- [x] `grep -nE "^final GoRouter appRouter" lib/core/routing/app_router.dart` returns zero matches
- [x] `grep -nE "@Riverpod\(keepAlive: true\)" lib/core/routing/app_router.dart` returns exactly one match
- [x] `grep -nE "ref\.onDispose\(router\.dispose\)" lib/core/routing/app_router.dart` returns exactly one match
- [x] `grep -nE "name: '" lib/core/routing/app_router.dart` returns zero matches
- [x] `lib/core/routing/app_router.g.dart` exists, is tracked by git (`git ls-files lib/core/routing/app_router.g.dart` non-empty), and `grep -nE "appRouterProvider" lib/core/routing/app_router.g.dart` returns ≥ 1 match
- [x] `grep -nE "ref\.watch\(appRouterProvider\)" lib/app.dart` returns ≥ 1 match
- [x] `grep -nE "routerConfig: appRouter\b" lib/app.dart` returns zero matches
- [x] `grep -rnE "\bappRouter\b" lib/ | grep -v "lib/core/routing/app_router\.dart" | grep -v "lib/core/routing/app_router\.g\.dart" | grep -v "appRouterProvider"` returns zero matches
- [x] `grep -nE "appRouterProvider\.overrideWith" test/core/routing/app_router_test.dart` returns ≥ 1 match
- [x] `grep -nE "testRouter\.dispose\(\)" test/core/routing/app_router_test.dart` returns zero matches
- [x] `dart analyze 2>&1 | head -40` is clean (no errors, no new warnings)
- [x] `flutter test` passes with no "ChangeNotifier ... leaked" or "used after being disposed" diagnostics in the output. All 6 tests in `test/core/routing/app_router_test.dart` pass. All 3 tests in `test/widget_test.dart` pass.
- [x] `flutter build apk --debug` succeeds

**Spec criteria addressed**: AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10, AC-11

## Contracts

### Expects

- `pubspec.yaml` lists `riverpod_annotation` (runtime), `riverpod_generator` + `build_runner` (dev), `flutter_riverpod`, and `go_router` (verified at `/plan` time)
- `lib/core/providers/shared_preferences_provider.dart` declares `@Riverpod(keepAlive: true) SharedPreferencesWithCache sharedPreferences(Ref ref) => ...` as the canonical function-form pattern reference
- `lib/core/routing/app_router.dart` currently declares a top-level `final GoRouter appRouter = GoRouter(...)` constant
- `lib/app.dart`'s `DoslyApp.build` currently passes `appRouter` to `MaterialApp.router(routerConfig: ...)`
- `test/core/routing/app_router_test.dart` currently defines `_pumpRouter(WidgetTester tester, GoRouter router)` and uses `_buildTestRouterWithSentinel()` + explicit `testRouter.dispose()` for Test 4

### Produces

- `lib/core/routing/app_router.dart` declares `@Riverpod(keepAlive: true) GoRouter appRouter(Ref ref) { ... ref.onDispose(router.dispose); return router; }` and includes `part 'app_router.g.dart';`
- `lib/core/routing/app_router.g.dart` is generated, committed, and declares the public symbol `appRouterProvider`
- `lib/app.dart` reads `ref.watch(appRouterProvider)` and passes the result to `MaterialApp.router(routerConfig: ...)`. No bare `appRouter` identifier appears anywhere in `lib/` outside `app_router.dart` / `app_router.g.dart`.
- `test/core/routing/app_router_test.dart`'s `_pumpRouter` helper has signature `Future<void> _pumpRouter(WidgetTester tester, {List<Override> overrides = const []})` and reads `appRouterProvider` via a `Consumer`
- `test/core/routing/app_router_test.dart` Test 4 uses `appRouterProvider.overrideWith((ref) { final r = _buildTestRouterWithSentinel(); ref.onDispose(r.dispose); return r; })` and contains no bare `testRouter.dispose()` call
- `flutter test` passes with the same test count as `main` and zero leaked-`ChangeNotifier` diagnostics
- `flutter build apk --debug` succeeds
- `dart analyze` is clean

## Completion Notes

**Completed**: 2026-05-18
**Files changed** (5, one outside originally-scoped set):
- `lib/core/routing/app_router.dart` — provider migration (in scope)
- `lib/core/routing/app_router.g.dart` — codegen output (in scope, NEW)
- `lib/app.dart` — `routerConfig` consumer + dartdoc (in scope)
- `lib/core/routing/app_shell.dart` — one-word dartdoc fix `[appRouter]` → `[appRouterProvider]` (scope expansion; required to satisfy AC-6 grep predicate)
- `test/core/routing/app_router_test.dart` — `_pumpRouter` reshape + Test 4 rewire (in scope)
- `test/widget_test.dart` — no change required (as predicted in plan)

**Contract**: Expects 5/5 verified | Produces 8/8 verified

**Deviations from plan / notes**:
1. `app_shell.dart` was not in the originally-listed file set but contained a stale `[appRouter]` dartdoc reference that AC-6's grep would have caught as a bare `appRouter` identifier. Single-word dartdoc fix; legitimate scope expansion.
2. Test file required adding `import 'package:flutter_riverpod/misc.dart';` for the `Override` type — it is NOT re-exported from the main `flutter_riverpod.dart` barrel. The import is necessary and intentional.
3. The new provider's library-level dartdoc uses the phrase "keep-alive Riverpod provider" rather than literally repeating `@Riverpod(keepAlive: true)` so AC-1's grep count stays at exactly one match (the annotation itself).
4. Implementing agent landed the source changes as a single `feat(core/routing): ...` commit (`35e9a67`) instead of a `[WIP]` commit. The work is correct; `/finalize` will squash regardless of message form.

**Verification**:
- `dart analyze`: No issues found
- `flutter test`: 227 passed, 0 failed, zero `ChangeNotifier` leak diagnostics
- `flutter build apk --debug`: SUCCESS
- Code review: APPROVE (one Warning was a false positive due to truncated diff view — `ref.onDispose(router.dispose)` exists at line 80; reviewer's own conditional resolved the verdict to APPROVE upon confirmation)
