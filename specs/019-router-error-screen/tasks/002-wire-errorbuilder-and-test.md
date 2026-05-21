# Task 002: Wire `errorBuilder` + private `_RouterErrorScreen` + Test 7

**Agent**: mobile-engineer
**Files**:
- `lib/core/routing/app_router.dart` (modify)
- `test/core/routing/app_router_test.dart` (modify — append Test 7 to the existing `group('appRouter', ...)`)

**Depends on**: 001
**Blocks**: 003
**Context docs**: `docs/architecture.md` (§"Routing" → "Conventions" — for the `context.go(...)` rule and the cross-feature-import exception that applies to `lib/core/routing/`)
**Review checkpoint**: No

## Description

Plug the `errorBuilder:` parameter into the existing `GoRouter(...)` constructor call inside the `appRouter` provider, declare a private `_RouterErrorScreen` widget in the same library, and add one widget test that pushes `/nonexistent` and verifies the screen renders + the "Go to home" button recovers to `HomeScreen`.

The widget is a `StatelessWidget` with a `const` constructor so the `errorBuilder` closure becomes a single expression: `errorBuilder: (context, state) => const _RouterErrorScreen()`. The `state: GoRouterState` argument is intentionally unused (spec §6: the attempted path is NOT displayed — it's unverified input).

The widget renders a plain `Scaffold` outside the `StatefulShellRoute`, so no `AppBottomNav` is visible (verified by Test 7's `findsNothing` assertion). The AppBar has `automaticallyImplyLeading: false` because the error path has no guaranteed previous frame to pop to; the only recovery action is the explicit `FilledButton`.

## Change details

### `lib/core/routing/app_router.dart`

1. Add two imports (after the existing `package:` imports, before the relative-feature imports):
   ```dart
   import 'package:flutter/material.dart';

   import '../../l10n/l10n_extensions.dart';
   ```

2. Inside the `GoRouter(...)` call (currently lines 36–79), add an `errorBuilder:` argument between the closing `]` of `routes:` and the closing `)`:
   ```dart
   errorBuilder: (context, state) => const _RouterErrorScreen(),
   ```
   (The `ref.onDispose(router.dispose);` line and surrounding structure stay untouched.)

3. Append, after the closing `}` of the `appRouter` function body:
   ```dart
   /// Private fallback screen rendered by [appRouter]'s `errorBuilder` when no
   /// [GoRoute] matches the requested path.
   ///
   /// Renders outside the [StatefulShellRoute] so no [AppBottomNav] is visible.
   /// The only recovery action is the localized "Go to home" [FilledButton],
   /// which calls `context.go('/')` to clear the route stack and land on the
   /// home branch.
   class _RouterErrorScreen extends StatelessWidget {
     const _RouterErrorScreen();

     @override
     Widget build(BuildContext context) {
       final l10n = context.l10n;
       return Scaffold(
         appBar: AppBar(
           title: Text(l10n.errorScreenTitle),
           automaticallyImplyLeading: false,
         ),
         body: Padding(
           padding: const EdgeInsets.all(24),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               Text(l10n.errorScreenBody, textAlign: TextAlign.center),
               const SizedBox(height: 16),
               FilledButton(
                 onPressed: () => context.go('/'),
                 child: Text(l10n.errorScreenGoHome),
               ),
             ],
           ),
         ),
       );
     }
   }
   ```

### `test/core/routing/app_router_test.dart`

Append a 7th `testWidgets` inside the existing `group('appRouter', () { … });` block (after Test 6, before the group's closing `});`). The test reuses `_pumpRouter` (no overrides) so it exercises the production `appRouter` provider:

```dart
// -----------------------------------------------------------------------
// Test 7 — AC-1, AC-2, AC-3, AC-8: errorBuilder renders a localized
// error screen for an unmatched path, outside the shell (no AppBottomNav),
// and the "Go to home" button recovers to HomeScreen.
// -----------------------------------------------------------------------
testWidgets(
  'Test 7 (AC-1, AC-2, AC-3, AC-8): errorBuilder renders for unmatched route and recovers to home',
  (tester) async {
    await _pumpRouter(tester);

    // Navigate to an unmatched path.
    GoRouter.of(tester.element(find.byType(HomeScreen))).go('/nonexistent');
    await tester.pumpAndSettle();

    // Error screen is rendered with the localized title.
    expect(find.text('Page not found'), findsOneWidget);

    // Screen renders OUTSIDE the StatefulShellRoute — no bottom nav.
    expect(find.byType(AppBottomNav), findsNothing);

    // Recovery button is present.
    expect(
      find.widgetWithText(FilledButton, 'Go to home'),
      findsOneWidget,
    );

    // Tap the button → navigate back to HomeScreen.
    await tester.tap(find.widgetWithText(FilledButton, 'Go to home'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
  },
);
```

No other test in the file is modified.

## Contracts

### Expects
- `AppLocalizations` exposes abstract getters `String get errorScreenTitle;`, `String get errorScreenBody;`, `String get errorScreenGoHome;` (from Task 001 Produces).
- The three concrete `AppLocalizationsEn/De/Uk` classes provide overrides for those getters (from Task 001 Produces).
- `lib/core/routing/app_router.dart` declares the `appRouter` function annotated with `@Riverpod(keepAlive: true)` and calls `GoRouter(routes: [...])` followed by `ref.onDispose(router.dispose)` (existing — spec 018 shape).
- `lib/l10n/l10n_extensions.dart` exports the `AppLocalizationsContext` extension on `BuildContext` with a `l10n` getter (existing — Feature 006).
- `test/core/routing/app_router_test.dart` declares `_pumpRouter(tester, {overrides})` helper at line 125 and a `group('appRouter', () { … })` with 6 existing `testWidgets` cases (existing — Features 007 + 018).
- `AppBottomNav` widget exists in `lib/core/widgets/app_bottom_nav.dart` and is imported by the test file (existing).
- `HomeScreen` widget exists in `lib/features/home/presentation/screens/home_screen.dart` and is imported by the test file (existing).

### Produces
- `lib/core/routing/app_router.dart` adds an import line `import 'package:flutter/material.dart';` and an import line `import '../../l10n/l10n_extensions.dart';`.
- The `GoRouter(...)` call inside `appRouter` includes a literal `errorBuilder:` argument.
- `lib/core/routing/app_router.dart` declares a top-level private class `class _RouterErrorScreen extends StatelessWidget` with a `const _RouterErrorScreen()` constructor.
- `_RouterErrorScreen.build` returns a `Scaffold` whose `appBar.title` reads `Text(l10n.errorScreenTitle)`, whose body contains a `Text(l10n.errorScreenBody, …)` and a `FilledButton(onPressed: () => context.go('/'), child: Text(l10n.errorScreenGoHome))`.
- `lib/core/routing/app_router.dart` contains no new import line matching `'../../features/'` beyond the four that already existed before the task.
- `test/core/routing/app_router_test.dart` contains a 7th `testWidgets` whose first argument string contains the substring `errorBuilder renders for unmatched route and recovers to home`.
- The new test asserts `find.text('Page not found')` is `findsOneWidget`, `find.byType(AppBottomNav)` is `findsNothing` on the error screen, taps the "Go to home" button, and asserts `find.byType(HomeScreen)` and `find.byType(AppBottomNav)` are each `findsOneWidget` after recovery.

## Done when

- [x] `grep -cE "errorBuilder:" lib/core/routing/app_router.dart` returns at least `1`. (= 1)
- [x] `grep -cE "class _RouterErrorScreen" lib/core/routing/app_router.dart` returns `1`.
- [x] `grep -cE "context\.go\\('/'\\)" lib/core/routing/app_router.dart` returns at least `1`. (= 2: source + dartdoc)
- [x] `grep -cE "!\s*[.\$]" lib/core/routing/app_router.dart` returns `0`.
- [x] `git diff main -- lib/core/routing/app_router.dart | grep -cE "^\\+import '\\.\\./\\.\\./features/"` returns `0`.
- [x] `grep -c "errorBuilder renders for unmatched route" test/core/routing/app_router_test.dart` returns `1`.
- [x] `dart analyze` passes with zero new warnings/hints/errors. (`No issues found!`)
- [x] `flutter test test/core/routing/app_router_test.dart` exits 0 with 7 tests passing.
- [x] `flutter build apk --debug` exits 0. (`✓ Built build/app/outputs/flutter-apk/app-debug.apk`)

**Spec criteria addressed**: AC-1, AC-2, AC-3, AC-8, AC-9, AC-10, AC-11, AC-12, AC-13

## Completion Notes

**Status**: Complete
**Completed**: 2026-05-18
**Files changed**:
- `lib/core/routing/app_router.dart` — added 2 imports + `errorBuilder:` param + private `_RouterErrorScreen` class with class-level dartdoc
- `test/core/routing/app_router_test.dart` — appended Test 7 inside existing `group('appRouter', ...)`

**Contract**: Expects 6/6 verified | Produces 6/6 verified
**Code review**: APPROVE (11/11 review checks pass; zero Critical/Warning; only confirmation Info items including AC-8 / StatefulShellRoute placement, body layout match, MEMORY L186 test pattern adherence)
**Notes**:
- `errorBuilder` IS a sibling of `routes:` in `GoRouter(...)` — confirmed renders outside the `StatefulShellRoute` (AC-8: `find.byType(AppBottomNav) findsNothing` passed).
- Test 7 used the production `appRouter` provider (no overrides) — `keepAlive: true` lifecycle (spec 018) cleanly isolates state across the 7 tests.
- `flutter build apk --debug` took ~3s post-Gradle warm cache — confirms codegen / analyze / test alignment under a real build.
