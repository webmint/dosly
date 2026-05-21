# Spec: Router Error Screen for Unmatched Routes

**Date**: 2026-05-18
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

Add an `errorBuilder` to the application's `GoRouter` so that requests to undefined paths (typos in `context.go(...)`, future deep links, future notification-action payloads) render a localized error screen with a "Go Home" action instead of go_router's debug-only red default screen (which appears blank or as a raw Flutter error overlay in release builds). The error screen is a single `Scaffold` declared inline inside `lib/core/routing/app_router.dart`, consumes three new ARB keys via the existing `context.l10n` extension, and is exercised by a new router test that pushes an unknown path.

This closes [bug 008](../../bugs/008-approuter-no-errorbuilder.md) — escalated to Critical by audit `2026-04-30` because constitution §5.2 already commits to notification-action deep links, which means the production failure mode is contractually planned, not hypothetical.

## 2. Current State

`lib/core/routing/app_router.dart:35-82` declares the `appRouter` provider as `@Riverpod(keepAlive: true) GoRouter appRouter(Ref ref)` — the post-spec-018 shape. The `GoRouter(...)` constructor call inside the provider passes a `routes:` list (one `StatefulShellRoute.indexedStack` plus two sibling `GoRoute`s for `/settings` and `/theme-preview`) and is followed by `ref.onDispose(router.dispose)`. **No** `errorBuilder:`, `errorPageBuilder:`, `onException:`, or `redirect:` parameter is configured.

When a user (or system caller) navigates to an unmatched path:
- **Debug builds** — go_router renders its default red `_ErrorScreen` widget showing the route name and the underlying exception. Functional, but ugly and English-only.
- **Release builds** — `assert(...)` failures are stripped; go_router falls back to a blank screen or the raw Flutter error overlay (yellow/black-striped error widget). No way back to a known-good route without process restart.

Existing infrastructure that the fix consumes as-is:
- **`context.l10n`** (`lib/l10n/l10n_extensions.dart:25`) — `BuildContext` extension that wraps the single sanctioned `!` site for `AppLocalizations.of(context)`. Constitution §3.1 forbids `!` everywhere except this one extension.
- **ARB pipeline** — `lib/l10n/app_{en,de,uk}.arb` plus `flutter gen-l10n` regenerates `lib/l10n/app_localizations*.dart` (4 files). Every ARB must contain every key or codegen errors out (docs/features/i18n.md §"How to add a new translated string"). English `@key` description blocks propagate into the abstract getter's dartdoc (MEMORY L203).
- **Router test scaffold** — `test/core/routing/app_router_test.dart:125` declares a `_pumpRouter(tester, {overrides})` helper that pumps `MaterialApp.router(routerConfig: ref.watch(appRouterProvider))` with `AppLocalizations.localizationsDelegates`, `supportedLocales`, and `locale: const Locale('en')` pinned. Six `testWidgets` already exist (AC-1, AC-2, AC-5, AC-7, AC-8, AC-9, AC-10, AC-11, AC-13 from spec 007 / spec 018).
- **Architectural rule** — `docs/architecture.md` §"Routing" → "Conventions" line 1: `lib/core/routing/` is the documented exception to the cross-feature-import rule (it imports from multiple feature folders to register routes). Navigation is `context.go(...)` / `context.push(...)` per the same section.
- **Navigation target for "go home"** — `/` is a string passed to `context.go('/')`. No feature import is required to reference the home path; `lib/core/routing/` is the layer where route strings are authoritative.

Prior deferral chain:
- Spec 007 review.md (line 13) flagged this as Info: "not a vulnerability today (no `android:intent-filter` / `CFBundleURLTypes` declared, all routes take zero params), but when deep-linking is enabled in a future feature, add an explicit `errorBuilder`."
- Spec 018 spec.md (line 111) explicitly excluded it from the lifecycle fix: "tracked separately by `bugs/008-approuter-no-errorbuilder.md`."
- Audit `2026-04-30` (code-reviewer F8, line 27) escalated it to Critical because constitution §5.2 line 459 commits to notification-action deep links: "Notification actions allow marking taken or skipped directly without opening the app" — those WILL hit the error path.

## 3. Desired Behavior

### 3.1 Production behavior

When `GoRouter` cannot resolve a path (no matching route after redirects), it builds and renders an in-app error screen with:

- A localized `AppBar` title (key: `errorScreenTitle`).
- A body message (key: `errorScreenBody`) explaining that the destination was not found.
- A `FilledButton` whose label (key: `errorScreenGoHome`) navigates back to `/` via `context.go('/')` when tapped.
- The screen is a plain `Scaffold` (no app-shell, no bottom nav) — `errorBuilder` always renders outside the `StatefulShellRoute`, so this matches the existing `/settings` and `/theme-preview` precedent.
- The screen reads `context.l10n` exactly once per `build()`, bound to a local — the standard pattern documented in `lib/l10n/l10n_extensions.dart:24` dartdoc.

### 3.2 Localization

Three new ARB keys are added to **all three** locale ARB files (`app_en.arb`, `app_de.arb`, `app_uk.arb`). Translations:

| Key | English | German | Ukrainian |
|---|---|---|---|
| `errorScreenTitle` | `Page not found` | `Seite nicht gefunden` | `Сторінку не знайдено` |
| `errorScreenBody` | `We couldn't find that destination.` | `Wir konnten dieses Ziel nicht finden.` | `Не вдалося знайти цей маршрут.` |
| `errorScreenGoHome` | `Go to home` | `Zur Startseite` | `На головну` |

English keys carry `@key.description` metadata blocks describing context and use site (audience: translators + IDE-hover dartdoc consumers — MEMORY L203). German and Ukrainian files contain the translated values only, no `@` metadata (per `docs/features/i18n.md` line 140).

`flutter gen-l10n` is run after the ARB edits; the regenerated files `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_de.dart`, and `app_localizations_uk.dart` are committed alongside the ARB sources (per `docs/features/i18n.md` line 156).

### 3.3 Test coverage

A new `testWidgets` is added to `test/core/routing/app_router_test.dart` under the existing `group('appRouter', ...)`. It:

1. Pumps the production `appRouter` via the existing `_pumpRouter(tester)` helper.
2. Navigates to a non-existent path: `GoRouter.of(tester.element(find.byType(HomeScreen))).go('/nonexistent')` (or equivalent context fetch — pattern at `app_router_test.dart:231` and MEMORY L186).
3. Asserts the localized title text (`Page not found`) is found.
4. Asserts the localized "Go to home" button is present.
5. Taps the button.
6. After `pumpAndSettle`, asserts `HomeScreen` is on screen — verifying the recovery action works.

The test does NOT introduce a sentinel route or a test-only router; the unmatched path triggers `errorBuilder` against the production route table.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Routing composition root | `lib/core/routing/app_router.dart` | Add `errorBuilder:` parameter to the existing `GoRouter(...)` call. Add a private `class _RouterErrorScreen extends StatelessWidget` (or equivalent inline-Scaffold builder — see §7 constraint on style) inside the same file. No structural change to the existing `routes:` list, branch order, or `ref.onDispose(router.dispose)` lifecycle line. |
| English source ARB | `lib/l10n/app_en.arb` | Add 3 keys (`errorScreenTitle`, `errorScreenBody`, `errorScreenGoHome`) each with a `@key.description` metadata block. |
| German ARB | `lib/l10n/app_de.arb` | Add 3 keys with German translations only (no `@` metadata). |
| Ukrainian ARB | `lib/l10n/app_uk.arb` | Add 3 keys with Ukrainian translations only (no `@` metadata). |
| Regenerated l10n | `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_de.dart`, `app_localizations_uk.dart` | Auto-regenerated by `flutter gen-l10n`. Commit alongside ARB edits. |
| Router integration test | `test/core/routing/app_router_test.dart` | Add one new `testWidgets` ("Test 7 (AC-1, AC-2, AC-3): errorBuilder renders for unmatched route and recovers to home") under the existing `group('appRouter', ...)`. Reuse `_pumpRouter`. |
| Bug record | `bugs/008-approuter-no-errorbuilder.md` | Set `**Status**: Fixed` and `**Fixed**: 2026-05-18`. Append a brief `## Resolution` section pointing to spec 019. |
| Architecture doc | `docs/architecture.md` | Add a single bullet under § Routing → "Conventions" referencing the new `errorBuilder` and what it renders. Do NOT rewrite the rest of the routing section — bug 012 (doc-vs-code drift) and MEMORY L192 already cover the lesson that rationale paragraphs rot; this is a small additive bullet. |

## 5. Acceptance Criteria

- [x] **AC-1**: `lib/core/routing/app_router.dart` contains an `errorBuilder:` argument inside the `GoRouter(...)` call. `grep -cE "errorBuilder:" lib/core/routing/app_router.dart` returns at least `1`.
- [x] **AC-2**: The `errorBuilder` builds a `Scaffold` containing (a) an `AppBar` whose `title` reads `context.l10n.errorScreenTitle`, (b) a body referencing `context.l10n.errorScreenBody`, and (c) a `FilledButton` whose label reads `context.l10n.errorScreenGoHome` and whose `onPressed` calls `context.go('/')`.
- [x] **AC-3**: Navigating to a path that matches no registered route (e.g. `/nonexistent`) renders the error screen — verified by a new `testWidgets` in `test/core/routing/app_router_test.dart` named `'Test 7 ... errorBuilder renders for unmatched route and recovers to home'`. The test pushes `/nonexistent`, expects `find.text('Page not found')` returns `findsOneWidget`, expects the "Go to home" button is present, taps it, and expects `find.byType(HomeScreen)` returns `findsOneWidget` after settle.
- [x] **AC-4**: `lib/l10n/app_en.arb` contains keys `errorScreenTitle` (value `Page not found`), `errorScreenBody` (value `We couldn't find that destination.`), and `errorScreenGoHome` (value `Go to home`). Each key has an `@key.description` metadata block (constitution / docs/features/i18n.md §"How to add a new translated string").
- [x] **AC-5**: `lib/l10n/app_de.arb` contains the same three keys with values `Seite nicht gefunden`, `Wir konnten dieses Ziel nicht finden.`, and `Zur Startseite` respectively. No `@` metadata blocks (per i18n doc line 140).
- [x] **AC-6**: `lib/l10n/app_uk.arb` contains the same three keys with values `Сторінку не знайдено`, `Не вдалося знайти цей маршрут.`, and `На головну` respectively. No `@` metadata blocks.
- [x] **AC-7**: `flutter gen-l10n` runs cleanly (exit code 0) and the regenerated `lib/l10n/app_localizations*.dart` files contain a `String get errorScreenTitle;` abstract getter in `app_localizations.dart` and concrete overrides in all three locale-specific files. `grep -l "errorScreenTitle" lib/l10n/app_localizations*.dart | wc -l` returns `4`.
- [x] **AC-8**: The error screen does NOT include an `AppBottomNav` — the `errorBuilder` renders outside `StatefulShellRoute`. The new Test 7 asserts `find.byType(AppBottomNav)` returns `findsNothing` while the error screen is on screen.
- [x] **AC-9**: The error screen contains zero new `!` null-assertion sites. The only sanctioned `!` site in the whole repo remains `lib/l10n/l10n_extensions.dart:25`. Verified by `grep -nE "!\s*[.\$]" lib/core/routing/app_router.dart` returning zero matches (constitution §3.1).
- [x] **AC-10**: `lib/core/routing/app_router.dart` does NOT add any new import from `lib/features/` (constitution §2.1 / docs/architecture.md §"Conventions": `lib/core/routing/` may import features, but this change does not need to). The "go home" target is the string `/`, not a typed reference to `HomeScreen`. `git diff main -- lib/core/routing/app_router.dart` shows zero added `import '../../features/` lines beyond what existed before.
- [x] **AC-11**: `dart analyze` exits 0 on the changed files. No new warnings, hints, or errors.
- [x] **AC-12**: `flutter test test/core/routing/app_router_test.dart` exits 0 with all 7 tests passing (6 existing + 1 new).
- [x] **AC-13**: `flutter build apk --debug` exits 0 (smoke test that codegen + analyze + test alignment hold under a real build).
- [x] **AC-14**: `bugs/008-approuter-no-errorbuilder.md` `**Status**` is `Fixed` and `**Fixed**` carries date `2026-05-18`. A `## Resolution` section references spec 019.
- [x] **AC-15**: `docs/architecture.md` § Routing → "Conventions" contains a new bullet describing the `errorBuilder` (one sentence, format: "`appRouter.errorBuilder` renders a localized `Scaffold` for unmatched paths with a `Go to home` action — entry point for malformed deep links and future notification-action payloads"). No other text in the routing section is modified.

## 6. Out of Scope

- **NOT included**: Wiring Android `<intent-filter>` or iOS `CFBundleURLTypes` for inbound deep links. The `errorBuilder` covers the *failure* case; ingress is a separate cross-platform feature deferred until the notification work (constitution §5.2) lands.
- **NOT included**: A `redirect:` policy on `GoRouter` (e.g., allow-list of safe paths, auth guards). This spec adds a UI fallback for paths that fail matching; it does NOT add a path-allow-list. Audit `2026-04-30` recommended *eventually* pairing `errorBuilder` with an allow-list redirect; that pairing is deferred until inbound deep linking exists to need it.
- **NOT included**: An `onException:` handler on `GoRouter`. `errorBuilder` covers no-match navigation; `onException:` covers thrown exceptions during route evaluation. None of the registered routes throws today, and adding `onException:` speculatively would couple this spec to error-typing decisions that have no caller.
- **NOT included**: Extracting `_RouterErrorScreen` into `lib/core/widgets/app_error_screen.dart`. The widget is ~15 lines, has exactly one consumer, and the inline form mirrors bug 008's Fix Notes. Extraction is speculative reuse and violates the "three similar lines is better than a premature abstraction" guidance from CLAUDE.md.
- **NOT included**: Logging or telemetry on error-screen entry. dosly has no backend (constitution §1 / §5.3) and no logger abstraction today. Adding `developer.log(...)` in the builder would be a one-off telemetry surface with nowhere to ship to. Bug 017 separately tracks a typed-logger introduction.
- **NOT included**: An "open settings" link, "report problem" link, or any secondary action. The fix is single-purpose: recover the user to a known-good route.
- **NOT included**: Localizing the route names themselves (e.g., showing `state.uri` translated). The error screen does not display the attempted path; that's a debug-builds-only need that the existing default go_router screen already prints.
- **NOT included**: A `redirect: (context, state) => Future<String?>.value(null)` no-op. Some templates wire one as a placeholder; we do not.
- **NOT included**: Modifying any of the 9 existing AC tests in `app_router_test.dart`. The new Test 7 is purely additive.
- **NOT included**: Closing any other open bug (009-016). Bug 008 is the sole closure target.

## 7. Technical Constraints

- **Must follow**: Clean Architecture layer boundaries (constitution §2.1). The error screen widget lives in `lib/core/routing/app_router.dart` (the composition root for routes, which is the only `lib/core/` site allowed to import features — and even here we do not need to). It is NOT placed in any `lib/features/[feature]/presentation/` directory.
- **Must follow**: No `!` null-assertion operator (constitution §3.1). Use `context.l10n` for localized strings.
- **Must follow**: Material 3 widgets (`FilledButton`, `Scaffold`, `AppBar`) — no custom theming, no hardcoded colors, no `TextStyle` literals. The screen inherits from `Theme.of(context)`.
- **Must follow**: `context.go(...)` (not `Navigator.of(context).pushReplacement(...)` or imperative APIs) per `docs/architecture.md` §"Conventions" line 249. `context.go('/')` clears the navigation stack on a top-level route — exactly the recovery semantics wanted.
- **Must use**: `context.l10n` accessor, not `AppLocalizations.of(context)!` direct calls (the sanctioned-`!` rule, MEMORY L120).
- **Must not break**: The six existing `testWidgets` in `app_router_test.dart`. The new errorBuilder fires only on unmatched paths; all existing tests exercise registered paths.
- **Must not break**: Spec 018's `appRouterProvider` lifecycle. The `errorBuilder` is a sibling parameter to `routes:`; `ref.onDispose(router.dispose)` stays unchanged.
- **Must follow**: Commit convention (CLAUDE.md "Commit Convention"). Final commit: `fix(core/routing): add localized errorBuilder for malformed routes (bug 008)`. WIP/checkpoint commits squashed by `/finalize`.
- **Style**: The error screen is declared as a private `class _RouterErrorScreen extends StatelessWidget` inside `app_router.dart` (private to the library, not exported). This is preferred over an inline `(context, state) { return Scaffold(...); }` closure because (a) it isolates the widget for code review, (b) it lets the widget tree show up correctly in the Flutter inspector, and (c) it lets the widget be `const`-constructed inside the `errorBuilder` closure. The `errorBuilder:` line itself is one expression: `errorBuilder: (context, state) => const _RouterErrorScreen()`.

## 8. Open Questions

None. The research file (`research/2026-05-18-bug-008-errorbuilder.md`) resolved approach (Option A — inline, ~15 lines, one file), file count (5), translation strings (chosen above, deliberately generic/short), and test shape. The remaining decision — closure vs. private `StatelessWidget` — is decided in §7 in favor of the private class for inspector and `const` reasons. `/plan` does not need to revisit any of these.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `flutter gen-l10n` fails because one ARB file is missing a key | Med | Med | All three ARBs are edited in the same task; `dart analyze` after gen-l10n catches drift. Bug 008 fix notes explicitly call out the three-file edit. |
| `find.text('Page not found')` matches another widget by accident | Low | Low | The string is unique to this screen (no other ARB key uses it). Test pins `locale: const Locale('en')` so the assertion is deterministic. |
| Tap on the "Go to home" `FilledButton` triggers `pumpAndSettle` timeout because `context.go('/')` queues a frame post-tap | Low | Low | The 5 existing tap-then-`pumpAndSettle` patterns (Test 1, 2, 5, 6, etc.) prove this works. If it doesn't, fall back to two explicit `pump()` calls. |
| The new `_RouterErrorScreen` class accidentally re-enters the error path (e.g. typo in the `/` literal) | Low | Med | Test 7 asserts `find.byType(HomeScreen) findsOneWidget` after the tap — directly verifies recovery, not just lack of crash. |
| `docs/architecture.md` § Routing bullet drifts again over time (bug 012 / MEMORY L192) | Low | Low | One-sentence bullet that names the *behavior*, not a rationale paragraph. Behavior facts are stable; rationale rots. |
| Adding the error screen surfaces a pre-existing bug elsewhere (e.g. `_pumpRouter` doesn't actually use the production router on a fresh ProviderScope) | Low | Low | All six existing tests pass against this helper. New test exercises the same helper with no overrides. |
| Future deep-link feature lands and the localized strings need tweaking (e.g. add the attempted path or a "try again" action) | Med | Low | ARB keys are scoped to *this* screen (`errorScreenXxx` prefix); future work edits the strings or adds new keys without re-architecting. |
