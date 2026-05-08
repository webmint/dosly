# Spec: Surface Settings Persistence Errors

**Date**: 2026-05-07
**Status**: Complete
**Author**: Claude + Webmint
**Closes**: bug 003 (`bugs/003-silent-error-swallowing-fold.md`)

## 1. Overview

`SettingsNotifier`'s four mutators (`setThemeMode`, `setUseSystemTheme`,
`setUseSystemLanguage`, `setManualLanguage`) currently swallow persistence
failures: the Left branch of every `Either.fold` is an empty closure with a
deferral comment. If a `SharedPreferences` write fails, the user gets no
feedback — the toggle reverts visually (because state isn't updated) but the
user has no idea why. This spec adds a side-channel error stream from
`SettingsNotifier` and surfaces failures in `SettingsScreen` as a localized
SnackBar, satisfying constitution §4.2 ("never swallow errors silently").

## 2. Current State

### Source of the problem

`lib/features/settings/presentation/providers/settings_provider.dart:35-111`
declares `SettingsNotifier extends Notifier<AppSettings>`. The four mutators
all share the same shape:

```dart
Future<void> setThemeMode(AppThemeMode mode) async {
  final repo = ref.read(settingsRepositoryProvider);
  final result = await repo.saveThemeMode(mode);
  result.fold(
    (_) {
      // Failure surfacing deferred to bug 003 (UI surface) and bug 017 (typed logger).
    },
    (_) {
      state = state.copyWith(manualThemeMode: mode);
    },
  );
}
```

The exact same `(_) { /* deferral comment */ }` Left branch is duplicated at
lines 52–55 (`setThemeMode`), 69–72 (`setUseSystemTheme`), 86–89
(`setUseSystemLanguage`), and 102–105 (`setManualLanguage`).

This is the **post-spec-013** state. Spec 013 removed four `kDebugMode`-guarded
`debugPrint` calls (closing bug 002) and replaced them with the empty closures
above, deferring the actual UI surfacing to this spec (bug 003) and the typed
logger to bug 017. The deferral comments at all four sites name both downstream
bugs.

### State shape and consumers

`AppSettings` (`lib/features/settings/domain/entities/app_settings.dart`) is a
freezed entity with four scalar fields: `useSystemTheme`, `manualThemeMode`,
`useSystemLanguage`, `manualLanguage`. The provider is declared as
`final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(...)`
at `settings_provider.dart:27-29`. Initial load is **synchronous** — the
repository's `load()` reads from `SharedPreferencesWithCache` and never fails
(returns defaults if nothing is stored, per `settings_repository.dart:18-20`
contract).

Five files read from the provider:

| File | How it reads |
|------|--------------|
| `lib/app.dart:66-77` | `ref.watch(settingsProvider.select(...))` × 4 (one per scalar field) |
| `lib/features/settings/presentation/widgets/theme_selector.dart:33` | `ref.watch(settingsProvider)` |
| `lib/features/settings/presentation/widgets/language_selector.dart:35` | `ref.watch(settingsProvider)` |
| `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart:34` | `ref.watch(settingsProvider)` |
| `test/features/settings/presentation/providers/settings_provider_test.dart` | Direct `container.read(settingsProvider)` with a `_FakeSettingsRepository` that has per-method `failOnSaveX` flags |

**Architectural choice taken**: Option B from `bugs/003-silent-error-swallowing-fold.md` —
keep `SettingsNotifier` as `Notifier<AppSettings>` (state shape unchanged),
expose persistence failures via a side-channel `Stream<Failure>` owned by the
notifier, and add a `StreamProvider<Failure>` that `SettingsScreen` consumes
via `ref.listen` to show a SnackBar. Rejected alternatives:
- **Option A (`AsyncNotifier<AppSettings>`)**: too invasive — initial load is
  genuinely sync and never fails; wrapping the entire state in `AsyncValue`
  forces every consumer (`app.dart`, two selectors, theme preview) to
  `.when(data, error, loading)`-unwrap with no benefit, since the "error"
  value would never actually represent a state-error (saves don't roll back
  state, they leave it consistent with what was saved).
- **Option C (mutators return `Either<Failure, void>`)**: changes the public
  API of all four mutators and pushes UI concerns into every call site
  (theme_selector, language_selector, theme_preview_screen). The error signal
  is conceptually screen-level, not call-site-level.
- **Option D (sealed `Loaded | Error` state union)**: same blast radius as A
  with extra ceremony.

### Test fixture already in place

`test/features/settings/presentation/providers/settings_provider_test.dart:17-70`
declares `_FakeSettingsRepository` with four `failOnSaveX` boolean flags. The
existing tests verify that the in-memory state is **not** updated on failure
(lines 110-120, 133-143, 185-196, 209-219) — the "don't lie about success"
half of the contract. They do NOT verify the failure produces any observable
signal (the qa-engineer F1 finding from the audit). This spec adds that.

### Localization layout

ARB sources live at `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb`. The
project already has localized settings copy (`settingsTitle`,
`settingsUseSystemTheme`, etc.). New error-message keys plug into the same
machinery — `flutter gen-l10n` regenerates the `app_localizations*.dart`
files on every save. The `BuildContext` extension at
`lib/l10n/l10n_extensions.dart` (`context.l10n.xxx`) is the established
sanctioned access pattern (single auditable `!` site per the Feature 006
lesson).

## 3. Desired Behavior

### Provider layer changes

`SettingsNotifier` (still `Notifier<AppSettings>` — state shape unchanged):

- Owns a `StreamController<Failure>.broadcast()` created in `build()`.
- Registers `ref.onDispose(controller.close)` so the controller is closed
  with the provider.
- Exposes `Stream<Failure> get errors => _controller.stream`.
- In each of the four mutators, the Left branch becomes
  `(failure) => _controller.add(failure)` instead of an empty closure.
- The Right branch stays unchanged (`state = state.copyWith(...)`).
- The deferral comments at the four Left sites are removed.

A new top-level provider in `settings_provider.dart`:

```dart
/// Stream of persistence failures emitted by [SettingsNotifier].
///
/// Consumers (e.g. [SettingsScreen]) listen to this provider via
/// `ref.listen` to surface errors to the user — for example, by showing
/// a SnackBar.
final settingsErrorsProvider = StreamProvider<Failure>((ref) {
  return ref.watch(settingsProvider.notifier).errors;
});
```

### UI layer changes

`SettingsScreen` becomes a `ConsumerStatefulWidget` (or
`ConsumerWidget` — implementation choice in `/plan`) so it has a `ref`
to call `ref.listen`. Inside `build`:

```dart
ref.listen<AsyncValue<Failure>>(settingsErrorsProvider, (prev, next) {
  next.whenData((_) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.settingsPersistenceError),
        behavior: SnackBarBehavior.floating,
      ),
    );
  });
});
```

The existing `Scaffold(appBar: ..., body: ListView(...))` body is unchanged
otherwise.

### Localization changes

Add **one** new ARB key, `settingsPersistenceError`, with these values:

| Locale | Value |
|--------|-------|
| `en` | "Couldn't save your preference. Please try again." |
| `de` | "Einstellung konnte nicht gespeichert werden. Bitte erneut versuchen." |
| `uk` | "Не вдалося зберегти налаштування. Спробуйте ще раз." |

Description (in `@settingsPersistenceError`):
"SnackBar message shown on the Settings screen when a preference change fails to persist (e.g. SharedPreferences write error)."

The message is **generic** — it does not include the failure's `message` field
or any implementation detail. This satisfies the constitution §4.2.1 PHI-spirit
rule (don't leak diagnostic detail to the user) and keeps the i18n surface
small.

### Out-of-screen mutator callers

The other consumer of `SettingsNotifier`'s mutators —
`theme_preview_screen.dart` (dev-only, scheduled for removal per spec 002 §6/§8) —
remains silent on persistence failure. The error stream is screen-scoped: only
`SettingsScreen` listens. This matches the dev-only screen's intent and avoids
adding throwaway UI plumbing.

### Behavior unchanged

- `SettingsNotifier`'s state field shape is unchanged (still `AppSettings`).
- All four mutators' return type stays `Future<void>`.
- The contract "in-memory state is NOT updated on persistence failure" stays
  intact (the Right-only `state = state.copyWith(...)` pattern).
- `app.dart`'s four `.select(...)` calls remain unchanged.
- `theme_selector.dart` and `language_selector.dart` remain `ConsumerWidget`s
  with no changes — they read state from `settingsProvider` and call mutators
  the same way.
- `theme_preview_screen.dart` is unchanged.
- `SettingsRepository` and `SettingsRepositoryImpl` are unchanged.
- `SettingsLocalDataSource` is unchanged.
- The initial-load path is unchanged (still sync, still defaults-on-empty).

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Settings provider | `lib/features/settings/presentation/providers/settings_provider.dart` | Add `StreamController<Failure>` + `errors` getter on notifier; replace 4 empty Left closures with `(failure) => _controller.add(failure)`; remove 4 deferral comments; add `settingsErrorsProvider` (`StreamProvider<Failure>`); add `dart:async` import. |
| Settings screen | `lib/features/settings/presentation/screens/settings_screen.dart` | Convert from `StatelessWidget` to `ConsumerWidget`; add `ref.listen<AsyncValue<Failure>>(settingsErrorsProvider, ...)` block; show SnackBar via `ScaffoldMessenger.of(context).showSnackBar(...)`. |
| Localization (English) | `lib/l10n/app_en.arb` | Add `settingsPersistenceError` key + `@settingsPersistenceError` description. |
| Localization (German) | `lib/l10n/app_de.arb` | Add `settingsPersistenceError` key. |
| Localization (Ukrainian) | `lib/l10n/app_uk.arb` | Add `settingsPersistenceError` key. |
| Generated localizations | `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_de.dart`, `app_localizations_uk.dart` | Regenerated by `flutter gen-l10n` — not hand-edited. |
| Provider unit tests | `test/features/settings/presentation/providers/settings_provider_test.dart` | Add tests asserting `settingsErrorsProvider` emits a `Failure` when each of the four mutators encounters a Left result; add tests asserting it does NOT emit on success. The `_FakeSettingsRepository` already has the per-method `failOnSaveX` hooks needed. |
| Screen widget tests | `test/features/settings/presentation/screens/settings_screen_test.dart` | Add a widget test that overrides `settingsProvider` with a notifier (or repository fake) configured to fail, triggers a mutator (e.g. tap the SwitchListTile), and asserts a SnackBar with the localized error message appears. |
| Bug bookkeeping | `bugs/003-silent-error-swallowing-fold.md` | Front matter: Status → Closed, Fixed → 2026-05-07 (spec 014). |
| Feature documentation | `docs/features/settings.md` | Update the description of the four mutators' Left branch to reflect the new "emit to error stream" behavior; document the new `settingsErrorsProvider`; document the SnackBar contract. |

## 5. Acceptance Criteria

Each criterion is testable.

- [x] **AC-1**: `SettingsNotifier` exposes a `Stream<Failure> get errors`
  backed by a `StreamController<Failure>.broadcast()` created in `build()`
  and closed via `ref.onDispose`. Verified by reading the source and by an
  unit test that subscribes to the stream and confirms it does not emit on a
  successful mutation.
- [x] **AC-2**: When `SettingsRepository.saveThemeMode` returns
  `Left(CacheFailure(...))`, `settingsErrorsProvider` emits exactly that
  `Failure`. Verified by a unit test that wires the fake repo's
  `failOnSaveThemeMode = true`, calls `setThemeMode(AppThemeMode.dark)`,
  and asserts the next event on the stream is the expected `CacheFailure`.
- [x] **AC-3**: AC-2 holds for the other three mutators
  (`setUseSystemTheme`, `setUseSystemLanguage`, `setManualLanguage`) —
  each emits a `Failure` on Left. Verified by three additional unit tests.
- [x] **AC-4**: When any mutator's repository call returns `Right(null)`,
  `settingsErrorsProvider` does NOT emit. Verified by a unit test that
  subscribes, calls each mutator with `failOnSaveX = false`, and asserts
  no events are received.
- [x] **AC-5**: On a persistence failure for `setThemeMode`,
  `settings.manualThemeMode` is NOT updated (existing contract preserved).
  This is already covered by an existing test
  (`settings_provider_test.dart:110-120`) which must continue to pass
  unmodified. Equivalent existing tests for the other three mutators must
  also continue to pass unmodified (lines 133-143, 185-196, 209-219).
- [x] **AC-6**: `settings_provider.dart` contains zero `debugPrint`,
  `print`, `developer.log`, or any other logging call (constitution §4.2.1
  compliance preserved from spec 013). Verified by `grep -E
  '\b(debugPrint|print|developer\.log)\b'` returning no matches in the file.
- [x] **AC-7**: The four Left branches in `settings_provider.dart` no longer
  contain the deferral comment "Failure surfacing deferred to bug 003 (UI
  surface) and bug 017 (typed logger)." (the bug-003 half is resolved by
  this spec; bug 017 stays Open per its own doc). Verified by
  `grep -F 'deferred to bug 003'` returning no matches in
  `lib/features/settings/`.
- [x] **AC-8**: A new ARB key `settingsPersistenceError` exists in all three
  ARB files (`app_en.arb`, `app_de.arb`, `app_uk.arb`) with the exact
  English/German/Ukrainian values listed in §3 and a description block in
  `app_en.arb`. `flutter gen-l10n` runs cleanly and regenerates
  `app_localizations*.dart` without warnings.
- [x] **AC-9**: When `settingsErrorsProvider` emits a `Failure` and
  `SettingsScreen` is mounted, a SnackBar appears with text equal to
  `context.l10n.settingsPersistenceError`. Verified by a widget test that
  pumps `SettingsScreen` with an overridden `settingsProvider` configured to
  fail on `setUseSystemTheme`, taps the "Use system theme" `SwitchListTile`,
  pumps a frame, and asserts `find.text(<localized error string>)` matches.
- [x] **AC-10**: The SnackBar uses `SnackBarBehavior.floating`. The text is
  the localized `settingsPersistenceError` value verbatim — no failure
  message, no exception type, no diagnostic detail.
- [x] **AC-11**: `SettingsScreen` is a `ConsumerWidget` (or
  `ConsumerStatefulWidget`) and otherwise renders the same Scaffold + AppBar
  + ListView body as before. The two `Padding(child: ThemeSelector())` and
  `Padding(child: LanguageSelector())` sections are unchanged. Verified by
  reading the source and by the existing screen widget tests continuing to
  pass.
- [x] **AC-12**: `dart analyze` passes with zero issues on all modified
  files.
- [x] **AC-13**: `flutter test` passes — all existing tests continue to
  pass, and all new tests added by this spec pass.
- [x] **AC-14**: `flutter build apk --debug` succeeds.
- [x] **AC-15**: `bugs/003-silent-error-swallowing-fold.md` front matter is
  updated: `Status: Closed`, `Fixed: 2026-05-07 (spec 014)`. Verified by
  `grep` on the file.
- [x] **AC-16**: `docs/features/settings.md` is updated to describe the new
  failure-surfacing behavior (the four mutators now emit to
  `settingsErrorsProvider` on Left; `SettingsScreen` shows a localized
  SnackBar). Verified by reading the file.

## 6. Out of Scope

The following are explicitly NOT part of this spec. Each has a tracked bug
or a documented reason for the exclusion.

- **NOT included**: Building the typed logger at `lib/core/logging/logger.dart`
  (constitution §7.1 step #3). Tracked separately as
  `bugs/017-typed-logger-missing.md`. The fix in this spec routes failures to
  the UI, not to a logger; the logger is a different surface and lands in a
  different spec when bug 017 is picked up.
- **NOT included**: Logging the `Failure` to anywhere (file, telemetry,
  console). Until bug 017 lands, there is no compliant logging primitive.
  The error stream goes to the UI only.
- **NOT included**: Making `theme_preview_screen.dart` listen to
  `settingsErrorsProvider`. The screen is dev-only and scheduled for
  removal per `specs/002-main-screen/spec.md` §6/§8. Adding throwaway UI
  plumbing there is wasted effort.
- **NOT included**: Changing the return type of any mutator from
  `Future<void>` to `Future<Either<Failure, void>>`. Mutator API surface
  is unchanged — callers still `await` and move on. The error signal is
  out-of-band by design.
- **NOT included**: Converting `SettingsNotifier` to `AsyncNotifier`. State
  shape stays as raw `AppSettings`. See §2 "Architectural choice taken" for
  the rejected-alternative rationale.
- **NOT included**: Converting `Failure` from a manual sealed class to
  `freezed`. Tracked separately as `bugs/006-failure-hierarchy-incomplete.md`.
- **NOT included**: Adding a "retry" button to the SnackBar.
  `SnackBarAction.label = "Retry"` is appealing, but the user can simply
  re-tap the toggle (it's a single tap). Adding a retry handler would
  require persisting the most recent attempt, which expands the surface
  meaningfully. Defer to a follow-up if real-world failures prove common
  enough to warrant it.
- **NOT included**: Adding `Severity` or `category` fields to `Failure`.
  Out of scope of bug 003 — see bug 006.
- **NOT included**: Pre-fill business rule extraction in
  `theme_selector.dart` and `language_selector.dart` (the
  `if (!value)` pre-fill blocks). Tracked separately as
  `bugs/005-settings-feature-missing-usecases.md`.
- **NOT included**: Migrating other features' notifiers to the same
  error-stream pattern. There are no other notifiers in `lib/features/`
  yet — settings is the first feature with mutators that can fail. The
  pattern established here can be reused later when the next such feature
  lands.

## 7. Technical Constraints

- **Must follow Clean Architecture (CLAUDE.md, constitution §2)**: the new
  code lives entirely in `presentation/`. No `domain/` change. No `data/`
  change. The error stream is a presentation-layer concern (the UI consumes
  it; the data layer continues to return `Either` and knows nothing about
  streams).
- **Must follow §3.1 (no `!`)**: SnackBar code uses
  `ScaffoldMessenger.of(context)` (non-null on a mounted widget) and
  `context.l10n.settingsPersistenceError` (the sanctioned single-`!` site
  per Feature 006 lesson). No new `!` sites.
- **Must follow §4.2 (no silent error swallow)**: this spec satisfies the
  rule by surfacing all four mutator failures to the UI.
- **Must follow §4.2.1 (no `print`/`debugPrint`, no PHI in logs)**: the
  SnackBar text is generic and translator-managed; no PHI risk. The error
  stream carries the `Failure` object only — its `message` field is never
  shown to the user.
- **Must follow §7.1 (typed logger requirement)**: the typed logger does
  not exist yet, so this spec uses the UI surface as the compliant
  alternative. The deferral chain to bug 017 is preserved.
- **Must use `package:flutter/material.dart` for `ScaffoldMessenger` and
  `SnackBar`** — these are Material-only.
- **Must use `flutter gen-l10n`** for ARB → Dart codegen. Do not hand-edit
  the generated `app_localizations*.dart` files.
- **`StreamController` lifecycle**: must be `.broadcast()` (multiple
  subscribers possible — e.g., a future feature) and closed via
  `ref.onDispose`. Failing to close leaks resources and triggers Riverpod
  test warnings.
- **No new dependencies**: `dart:async` is already part of Dart core. No
  pubspec changes.

## 8. Open Questions

These are minor implementation choices that can be settled in `/plan`:

- **Q-A**: Should `SettingsScreen` become `ConsumerWidget` or
  `ConsumerStatefulWidget`? The `ref.listen` call works with either.
  `ConsumerWidget` is simpler if no other state is needed; `ConsumerStatefulWidget`
  is conventional when listeners are involved. `/plan` to decide.
- **Q-B**: Should the SnackBar use `behavior: SnackBarBehavior.floating`
  (modern M3) or the default (anchored to the bottom)? Specced as floating in
  §3 but `/plan` may revisit if it conflicts with other M3 conventions in
  the codebase.
- **Q-C**: Should `settingsErrorsProvider` be `autoDispose` or non-disposing?
  The notifier is non-`autoDispose` (it's app-wide settings), and
  ref.watching `notifier.errors` from a non-`autoDispose` provider transitively
  keeps the parent alive. Default to non-`autoDispose` for symmetry with
  `settingsProvider`. `/plan` to confirm.
- **Q-D**: Should the widget-level test (AC-9) override the entire
  `settingsProvider` with a fake notifier, or should it override
  `settingsRepositoryProvider` with a failing fake repo? The repository
  override approach is simpler and matches `settings_provider_test.dart`'s
  existing `_FakeSettingsRepository` pattern. `/plan` to decide whether the
  fake repo can be reused or needs its own copy in the screen test file.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `StreamController` leak (not closed on dispose) | Low | Med | AC-1 explicitly requires `ref.onDispose(controller.close)`. Code reviewer to verify. Riverpod surfaces unclosed controllers as test warnings. |
| Multiple SnackBars stack on rapid toggle taps | Low | Low | `ScaffoldMessenger` queues them by default; users see them sequentially. If this proves annoying, future fix is `removeCurrentSnackBar()` in the listener. Not a v1 concern. |
| Listener fires on rebuild and shows duplicate SnackBars | Low | Med | `ref.listen` (not `ref.watch`) only fires on state change, not rebuild. `whenData` only triggers on actual emission. Widget test (AC-9) verifies single-SnackBar-per-emission. |
| Existing tests break due to `SettingsScreen` becoming a `ConsumerWidget` | Low | Low | `settings_screen_test.dart` already uses `ProviderScope` (per the project's testing convention). Convert remains source-compatible. |
| Localized German/Ukrainian strings need a native review | Med | Low | English is the source of truth (constitution §6). The German and Ukrainian strings provided in §3 are reasonable translations; if the user wants different wording, change pre-merge. No build-time blocker. |
| `flutter gen-l10n` fails on missing key in one of the three ARBs | Low | Low | The build fails fast; fix is to add the missing key. Caught by AC-8. |
| Future feature wants the same error-stream pattern but uses an `AsyncNotifier` | Low | Low | Not this spec's problem. The pattern here is "screen-scoped error stream owned by a sync `Notifier`" and is documented in `docs/features/settings.md` per AC-16. |
| User dismisses SnackBar without noticing | Low | Med | `SnackBarBehavior.floating` is a Material 3 default and reasonably visible. Auto-dismiss at the default duration is acceptable for a soft-failure case. If the failure is repeated, the user sees repeated SnackBars. |
| Typo in ARB key produces a runtime crash on a German/Ukrainian device | Low | High | `flutter gen-l10n` validates that all locales have all keys; a missing key is a build error, not a runtime crash. Verified by AC-8. |
