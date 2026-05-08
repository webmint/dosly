# Plan: Surface Settings Persistence Errors

**Date**: 2026-05-07
**Spec**: `specs/014-surface-settings-errors/spec.md`
**Status**: Draft

## Summary

Add a side-channel `Stream<Failure>` to `SettingsNotifier` (kept as a sync
`Notifier<AppSettings>`), expose it via a top-level `StreamProvider<Failure>`,
and have `SettingsScreen` (converted to a `ConsumerWidget`) listen via
`ref.listen` and show a localized M3 floating SnackBar on every emission. Adds
one ARB key in three locales. No domain-layer or data-layer changes.

## Technical Context

**Architecture**: Presentation-only change. Domain (`SettingsRepository`,
`AppSettings`, `Failure`) and data (`SettingsRepositoryImpl`,
`SettingsLocalDataSource`) are unchanged. The new
`StreamController<Failure>` lives entirely in
`presentation/providers/settings_provider.dart`. The new SnackBar surface
lives in `presentation/screens/settings_screen.dart`.

**Error Handling**: Continues the project's `Either<Failure, T>` (fpdart)
pattern. The Left branch of each `Either.fold` now pushes the `Failure` onto
the broadcast stream instead of being a no-op. The Right branch is unchanged
(`state = state.copyWith(...)`). No new `Failure` subclasses introduced.

**State Management**: Riverpod 3.x. `settingsProvider` stays as
`NotifierProvider<SettingsNotifier, AppSettings>` — state shape unchanged.
The new `settingsErrorsProvider` is a top-level
`StreamProvider<Failure>` declared in the same file, bridging
`ref.watch(settingsProvider.notifier).errors` to a broadcast stream.

## Constitution Compliance

- **§2.1 (domain layer is pure Dart, no Flutter imports)**: ✅ unchanged. No
  domain-layer file is touched.
- **§3.1 (no `!` null assertions)**: ✅ no new `!` sites. `ScaffoldMessenger.of(context)`
  returns non-null on a mounted widget; `context.l10n` continues to be the
  single sanctioned `!` site (Feature 006 lesson — does not increase).
- **§4.2 (no silent error swallow)**: ✅ this plan resolves the violation. Every
  `Either.fold` Left branch now produces an observable signal
  (stream emission → SnackBar).
- **§4.2.1 (no `print`/`debugPrint`, PHI sanitize)**: ✅ no new logging calls.
  Generic SnackBar text contains no PHI and no failure detail. Spec 013's
  `debugPrint` removal stays intact.
- **§7.1 (typed logger requirement)**: ⚠️ deferral preserved. The logger does
  not exist yet (bug 017 stays Open). This spec uses the UI surface as the
  compliant alternative, not "log to console." The deferral chain is now
  one-step shorter: bug 003 closes here; bug 017 remains the only open
  follow-up.
- **§6 (i18n: every user-facing string localized)**: ✅ new SnackBar text routes
  through `context.l10n.settingsPersistenceError` with values in `app_en.arb`,
  `app_de.arb`, `app_uk.arb`.
- **Strict-mode lints (`strict-casts`, `strict-inference`, `strict-raw-types`,
  no `dynamic`)**: ✅ all new code uses concrete types
  (`StreamController<Failure>`, `Stream<Failure>`,
  `StreamProvider<Failure>`, `AsyncValue<Failure>`).
- **No `package:flutter/*` in `domain/`**: ✅ change is `presentation/`-only.
- **`prefer_const_constructors`**: ✅ SnackBar with a non-const text widget can't
  be const at the outer level; `Text(context.l10n.xxx)` forces non-const. Apply
  `const` where possible (`SnackBarBehavior.floating` is an enum value, not a
  constructor).

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Domain | (unchanged) | — |
| Data | (unchanged) | — |
| Presentation — Provider | `SettingsNotifier` gains `late final StreamController<Failure> _errors` initialized in `build()` and registered via `ref.onDispose(_errors.close)`. Each of the 4 mutators' Left branch becomes `(failure) => _errors.add(failure)`. New `settingsErrorsProvider` (`StreamProvider<Failure>`) declared at top level in the same file. | `lib/features/settings/presentation/providers/settings_provider.dart` (modify) |
| Presentation — Screen | `SettingsScreen` becomes `ConsumerWidget`. Adds `ref.listen<AsyncValue<Failure>>(settingsErrorsProvider, ...)` in `build`. SnackBar shown via `ScaffoldMessenger.of(context).showSnackBar(...)`. | `lib/features/settings/presentation/screens/settings_screen.dart` (modify) |
| Presentation — Localization | Add `settingsPersistenceError` key to all three ARB files. `flutter gen-l10n` regenerates. | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (modify); `app_localizations*.dart` (regenerated) |
| Tests — Provider | Add tests asserting `settingsErrorsProvider` emits exactly one `Failure` per Left from each mutator; assert no emission on Right. Existing `_FakeSettingsRepository` already supports this (per-method `failOnSaveX` flags). | `test/features/settings/presentation/providers/settings_provider_test.dart` (modify) |
| Tests — Screen | Add a widget test that overrides `settingsRepositoryProvider` with a fake configured to fail on `setUseSystemTheme`, taps the "Use system theme" `SwitchListTile`, pumps a frame, asserts the localized error SnackBar appears. Existing minimal `_FakeSettingsRepository` is replaced/extended to support per-method failure flags. | `test/features/settings/presentation/screens/settings_screen_test.dart` (modify) |
| Bug bookkeeping | Front matter flip on bug 003. | `bugs/003-silent-error-swallowing-fold.md` (modify) |
| Documentation | Update settings feature doc to describe the new error-stream pattern + SnackBar contract. | `docs/features/settings.md` (modify) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| **Failure surfacing architecture** | Side-channel `StreamProvider<Failure>` (Option B) | Smallest blast radius (state shape, mutator API, all consumers except SettingsScreen unchanged). Idiomatic Riverpod. Initial load is genuinely sync — no need for `AsyncValue`. | A (AsyncNotifier — too invasive); C (mutator returns Either — pushes UI to call sites); D (sealed state union — same cost as A) |
| **StreamController ownership** | Owned by `SettingsNotifier`, initialized in `build()`, closed via `ref.onDispose` | Riverpod 3.x docs explicitly show this pattern. Notifier is the natural emitter (it's where the fold runs). | Owned by `StreamProvider` directly (would require a workaround to let the notifier push) |
| **Broadcast vs single-subscriber stream** | `StreamController<Failure>.broadcast()` | A future feature might want to listen too (e.g., a global error toast service). Broadcast costs nothing extra for one subscriber but allows N subscribers. | Single-subscriber would block any future fan-out |
| **`autoDispose` on `settingsErrorsProvider`** | Non-`autoDispose` (matches parent) | `settingsProvider` is non-`autoDispose`. App settings are app-wide. Mismatched lifecycles confuse. | autoDispose — would dispose between SettingsScreen pushes and lose the controller mid-fix-attempt sequence |
| **Listener placement** | `ConsumerWidget` + `ref.listen` in `build` | Simplest. Documented as the "safe and recommended way." SettingsScreen has no other state. | `ConsumerStatefulWidget + ref.listenManual` in initState (more boilerplate, no benefit) |
| **`ref.listen` callback shape** | `next.whenData((_) { showSnackBar })` | `whenData` skips the initial `AsyncLoading` (no false fire on first subscribe) and fires only on real emission. The `failure` payload itself isn't shown to the user (generic message), so we discard with `_`. | `next.value != null && prev?.value != next.value` — error-prone, and `prev` semantics on streams are subtle |
| **SnackBar behavior** | `SnackBarBehavior.floating` | M3 design guideline. App is `useMaterial3: true`. | Default `fixed` — legacy, anchored to bottom edge |
| **SnackBar message strategy** | Generic localized text, no failure detail | i18n-friendly. No PHI risk. CacheFailure.message is implementation detail. | Include `failure.message` — leaks detail, breaks i18n |
| **SnackBar action button (e.g., Retry)** | None | Adds state (must remember last attempt). User can simply re-tap toggle. Defer to follow-up if real failures prove common. | Add Retry — out of scope per spec §6 |
| **Test fake strategy** | Reuse the existing `_FakeSettingsRepository` shape with per-method `failOnSaveX` flags. Provider unit tests already have it; screen test gets a similar fake (private to the test file). | Honest test pyramid. Unit test verifies fold-and-emit; widget test verifies provider→SnackBar wiring on top of real notifier + real fold + real stream. | Override `settingsProvider` with a fake notifier — bypasses the very fold this spec is testing |
| **`SettingsScreen` ConsumerWidget vs ConsumerStatefulWidget** | `ConsumerWidget` | No initState work. `ref.listen` in build is the documented idiomatic pattern. | ConsumerStatefulWidget — boilerplate without benefit |
| **theme_preview_screen.dart listener** | Do not add | Dev-only screen scheduled for removal (spec 002 §6/§8). Adding throwaway plumbing is wasted effort. Per spec §6. | Add a listener — wasted work |
| **Existing test name preservation** | Keep all existing test names; add new tests with descriptive names | Preserves git history and avoids merge churn. New tests added as additional `test(...)` blocks in the same `group('SettingsNotifier', ...)`. | Rename for naming consistency — no value, churn cost |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/features/settings/presentation/providers/settings_provider.dart` | Modify | Add `import 'dart:async';`. Add `late final StreamController<Failure> _errors;` field on `SettingsNotifier`. In `build()`: `_errors = StreamController<Failure>.broadcast(); ref.onDispose(_errors.close);`. Add `Stream<Failure> get errors => _errors.stream;` getter. Replace each of the 4 empty Left closures with `(failure) => _errors.add(failure)`. Remove the 4 deferral comments. Add top-level `final settingsErrorsProvider = StreamProvider<Failure>((ref) => ref.watch(settingsProvider.notifier).errors);`. Add corresponding dartdoc. |
| `lib/features/settings/presentation/screens/settings_screen.dart` | Modify | Replace `extends StatelessWidget` with `extends ConsumerWidget`. Update `build` signature to `Widget build(BuildContext context, WidgetRef ref)`. Add `ref.listen<AsyncValue<Failure>>(settingsErrorsProvider, (prev, next) { next.whenData((_) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.settingsPersistenceError), behavior: SnackBarBehavior.floating)); }); });` at the top of build. Add necessary imports: `flutter_riverpod`, `core/error/failures.dart`, `../providers/settings_provider.dart`. Update class-level dartdoc to mention the error SnackBar. |
| `lib/l10n/app_en.arb` | Modify | Add `"settingsPersistenceError": "Couldn't save your preference. Please try again."` and `"@settingsPersistenceError": { "description": "SnackBar message shown on the Settings screen when a preference change fails to persist (e.g. SharedPreferences write error)." }`. |
| `lib/l10n/app_de.arb` | Modify | Add `"settingsPersistenceError": "Einstellung konnte nicht gespeichert werden. Bitte erneut versuchen."`. |
| `lib/l10n/app_uk.arb` | Modify | Add `"settingsPersistenceError": "Не вдалося зберегти налаштування. Спробуйте ще раз."`. |
| `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_de.dart`, `app_localizations_uk.dart` | Regenerated | `flutter gen-l10n` regenerates these. Do not hand-edit. |
| `test/features/settings/presentation/providers/settings_provider_test.dart` | Modify | Add a new `group('SettingsNotifier error stream', ...)` with: 4 tests (one per mutator) asserting `settingsErrorsProvider` emits a `CacheFailure` when `failOnSaveX` is true; 1 test asserting it does NOT emit on success path; 1 test asserting the broadcast stream supports multiple emissions in sequence. Use `expectLater(...).emitsInOrder([...])` or `await for` with a timeout — pattern TBD by qa-engineer. Add `import 'package:flutter/foundation.dart';` if needed for AsyncValue helpers (likely not). |
| `test/features/settings/presentation/screens/settings_screen_test.dart` | Modify | Replace the minimal `_FakeSettingsRepository` (which has `Either<Never, void>` return types and always succeeds) with a richer fake that has per-method `failOnSaveX` flags and `Either<Failure, void>` return types. Add a new `group('SettingsScreen error SnackBar', ...)` with: 1 test that pumps SettingsScreen with a fake configured to fail on `setUseSystemTheme`, taps the "Use system theme" SwitchListTile, calls `tester.pump()` (NOT `pumpAndSettle` because the SnackBar animation is timed), and asserts `find.text(<localized error>)` matches. The existing locale-resolution test groups should continue to pass unmodified. |
| `bugs/003-silent-error-swallowing-fold.md` | Modify | Front matter: `Status: Open` → `Status: Closed`; `Fixed:` → `Fixed: 2026-05-07 (spec 014)`. |
| `docs/features/settings.md` | Modify | Add a section describing: (a) the new `settingsErrorsProvider` (StreamProvider<Failure>); (b) the four mutators' Left branch now emits to the stream; (c) `SettingsScreen` listens via `ref.listen` and shows a localized SnackBar; (d) the new ARB key `settingsPersistenceError`. Remove any prose that referenced the old "silent failure" or "deferred to bug 003" behavior. |

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/features/settings.md` | Update | New §X "Error surfacing" — describes the StreamProvider, mutator behavior, SnackBar contract, and the closure of bug 003. Remove or revise any prose that describes the post-spec-013 "empty Left closure with deferral comment" state. |
| `docs/architecture.md` | Update (minor) | Add a one-paragraph note in the error-handling section: "For mutators that can fail, the side-channel `StreamProvider<Failure>` pattern (first established by `settingsErrorsProvider` in spec 014) is the recommended way to surface failures to the UI without changing state shape or the mutator's `Future<void>` return type." This documents the pattern for future features. |
| `docs/api/*` | No change | No API endpoints involved (no backend). |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `StreamController` not closed → memory leak / test warnings | Low | Med | AC-1 explicitly requires `ref.onDispose(_errors.close)`. code-reviewer to verify. Riverpod surfaces unclosed controllers as analyzer warnings. |
| `ref.listen` fires on first subscribe with `AsyncLoading` and shows a stale SnackBar | Low | Med | `next.whenData((_) { ... })` only fires on emitted data, never on `AsyncLoading` or `AsyncError`. Verified by widget test (AC-9). |
| Multiple SnackBars stack on rapid toggle taps | Low | Low | `ScaffoldMessenger` queues by default. Not a v1 concern. Future fix: `removeCurrentSnackBar()` before showing. |
| Listener fires twice on rebuild → duplicate SnackBars | Low | Med | `ref.listen` is identity-checked by Riverpod; same `provider` argument is the same listener. `whenData` only triggers on actual stream emission, not rebuild. Verified by widget test. |
| Existing `settings_screen_test.dart` `_resolveLocale` + `_harness` pattern breaks when `SettingsScreen` becomes `ConsumerWidget` | Low | Low | The harness already wraps in `ProviderScope`. A `ConsumerWidget` works inside a `ProviderScope` exactly like a `StatelessWidget`. Existing tests should pass unmodified. |
| `flutter gen-l10n` fails on missing key in one of the three ARBs | Low | Low | Build fails fast. Caught by AC-8 + the project's PostToolUse hook running `dart analyze`. |
| `pubspec.yaml` doesn't have a stream-test helper that simplifies emission assertions | Low | Low | `package:test` (transitively via `flutter_test`) provides `expectLater(..., emits(...))` and `emitsInOrder([...])` matchers out of the box. No new dependency needed. |
| Native German/Ukrainian translation review needed | Med | Low | Translations provided are reasonable. User can revise pre-merge if wording doesn't match preference. No build-time blocker. |
| Future feature wants to share the error-stream pattern | Low (positive) | — | `docs/architecture.md` will document the pattern. The first reuse will validate it. |
| `StreamProvider<Failure>` consumer in test misses the emission due to async timing | Med | Low | Standard `expectLater(stream, emits(matcher))` pattern handles this — it's a `Future` that resolves on first match. qa-engineer task to ensure tests use the right asynchronous pattern. |
| Deferral-comment grep miss — a stray reference somewhere | Low | Low | AC-7 grep is the safety net. PostToolUse `dart analyze` does NOT catch this; need explicit grep at task completion. |

## Dependencies

**Runtime**: No new dependencies.
- `flutter_riverpod ^3.3.1` (existing) — provides `StreamProvider`, `ConsumerWidget`, `ref.listen`, `ref.onDispose`.
- `fpdart ^1.2.0` (existing) — provides `Either`, `Left`, `Right`.
- `dart:async` (Dart core) — provides `StreamController`.
- `flutter_localizations` + `intl ^0.20.2` (existing) — ARB regeneration via `flutter gen-l10n`.

**Tooling**: `flutter gen-l10n` — must be run after ARB edits to regenerate `lib/l10n/app_localizations*.dart`.

**Environment**: None.

## Plan-Spec Cross-Reference Check

Verifying every AC has a clear implementation path in the plan:

| AC | Implementation Path | Files Involved |
|----|---------------------|----------------|
| AC-1 (Stream, controller, onDispose) | "Provider" row of Layer Map; Decision row "StreamController ownership" | `settings_provider.dart` |
| AC-2 (saveThemeMode failure emits) | "Provider" row; "Provider unit tests" row | `settings_provider.dart`, `settings_provider_test.dart` |
| AC-3 (other 3 mutators emit) | Same as AC-2 (4 identical-shape edits) | same |
| AC-4 (Right does NOT emit) | "Provider unit tests" row | `settings_provider_test.dart` |
| AC-5 (state-not-updated-on-failure preserved) | "Existing tests preserved" — see Decision row "Existing test name preservation" | `settings_provider_test.dart` (no changes to the existing 4 tests) |
| AC-6 (zero debugPrint/print/log) | Verified by file content. PostToolUse `dart analyze` enforces `avoid_print`. | `settings_provider.dart` |
| AC-7 (deferral comments removed) | Explicit in "File Impact" — "Remove the 4 deferral comments." Risk row notes grep is needed. | `settings_provider.dart` |
| AC-8 (ARB key in 3 locales + gen-l10n clean) | "Localization" rows of Layer Map and File Impact | `app_en.arb`, `app_de.arb`, `app_uk.arb` |
| AC-9 (SnackBar on emission, mounted screen) | "Screen" row of Layer Map; "Screen widget tests" row | `settings_screen.dart`, `settings_screen_test.dart` |
| AC-10 (SnackBar floating + verbatim localized text) | Decision row "SnackBar behavior" + "SnackBar message strategy" | `settings_screen.dart` |
| AC-11 (ConsumerWidget + Scaffold body unchanged) | "Screen" row; Decision row "ConsumerWidget vs ConsumerStatefulWidget" | `settings_screen.dart` |
| AC-12 (dart analyze passes) | PostToolUse hook + per-task verification | all modified files |
| AC-13 (flutter test passes) | per-task verification + terminal task gate | `settings_provider_test.dart`, `settings_screen_test.dart` |
| AC-14 (flutter build apk --debug passes) | terminal task gate | — |
| AC-15 (bug 003 front matter Closed) | "Bug bookkeeping" row | `bugs/003-silent-error-swallowing-fold.md` |
| AC-16 (docs/features/settings.md updated) | "Documentation Impact" table | `docs/features/settings.md` |

**Reverse check** — files in plan's File Impact NOT in spec's Affected Areas:
- `docs/architecture.md` — newly added (one-paragraph note documenting the
  error-stream pattern for future reuse). Discovered during planning. Low risk
  — single-paragraph addition. Adding to plan only; spec stays unchanged
  unless user wants to revise. Optional — could be deferred to /finalize's
  tech-writer pass.

All 16 ACs have a clear implementation path. No ACs require clarification
during breakdown.

## Supporting Documents

- [Research](research.md) — Riverpod 3.x StreamProvider + ref.listen patterns confirmed via Context7
- Data Model — N/A (no new entities; `Failure` is unchanged)
- Contracts — N/A (no API endpoints; app is fully local)
