# Spec: Remove `debugPrint` calls from `SettingsNotifier` (bug 002 fix)

**Date**: 2026-05-01
**Status**: Complete
**Author**: Claude + Webmint
**Source bug**: [`bugs/002-debugprint-in-settings-provider.md`](../../bugs/002-debugprint-in-settings-provider.md)

## 1. Overview

`SettingsNotifier` (`lib/features/settings/presentation/providers/settings_provider.dart`) contains four `kDebugMode`-guarded `debugPrint` calls — one inside the Left branch of each `Either.fold` for the four mutator methods. Constitution §4.2.1 forbids `print()` / `debugPrint()` in committed code unconditionally; the `kDebugMode` guard does not exempt the rule. This spec removes the four `debugPrint` sites without expanding into the larger architectural fixes that bugs 003 and 017 address. Production behavior is unchanged; debug-mode console output for these specific failures is lost (intentionally — bug 003 will replace it with a real surface).

## 2. Current State

### What the constitution says

`constitution.md:353` (§4.2.1, marked `[enforced]`):
> Never use `print()` or `debugPrint()` in committed code. Use the typed logger from `core/logging/`. The `avoid_print` lint must remain enabled.

### What the code currently does

`lib/features/settings/presentation/providers/settings_provider.dart` defines `SettingsNotifier extends Notifier<AppSettings>` with four mutator methods — `setThemeMode`, `setUseSystemTheme`, `setUseSystemLanguage`, `setManualLanguage`. Each follows the same shape:

```dart
Future<void> setThemeMode(AppThemeMode mode) async {
  final repo = ref.read(settingsRepositoryProvider);
  final result = await repo.saveThemeMode(mode);
  result.fold(
    (failure) {
      if (kDebugMode) {
        debugPrint('Settings: persistence failed — $failure');
      }
    },
    (_) {
      state = state.copyWith(manualThemeMode: mode);
    },
  );
}
```

The four `debugPrint` sites are at lines `56`, `75`, `94`, and `112`. The Left-branch closures contain only the `if (kDebugMode) { debugPrint(...) }` block — nothing else. Production builds (`kDebugMode == false`) execute the closure but evaluate no statements, so the Left branch is **already** a no-op in release.

### What downstream code depends on

The contract documented at `lib/features/settings/presentation/providers/settings_provider.dart:48–49` (and at `docs/features/settings.md:79`) is:
> "On persistence failure the in-memory state is not updated so the UI stays consistent with what was actually saved."

Callers (`ThemeSelector`, `LanguageSelector`) read the settings via `ref.watch(settingsProvider)` and never observe failures directly. The widgets simply re-render on state change; no error path exists at the UI layer.

### How `Either<Failure, void>` is produced

`lib/features/settings/data/repositories/settings_repository_impl.dart` catches `Exception` from `SettingsLocalDataSource` and returns `Left(CacheFailure(e.toString()))`. The data source itself wraps `SharedPreferencesWithCache` calls (which throw on disk-full, cache corruption, etc.). The Left branch in `SettingsNotifier` is therefore reachable in production.

### Current test coverage

`test/features/settings/presentation/providers/settings_provider_test.dart` already verifies the "state is not updated on failure" half of the contract via four tests (one per mutator), each setting `failOnSaveX = true` on a `_FakeSettingsRepository`. No test verifies anything about the `debugPrint` line — it is not currently observable.

### Related gaps tracked elsewhere

- **Bug 003** (`bugs/003-silent-error-swallowing-fold.md`) — the Left branch is a no-op in production, which violates constitution §4.2 ("Never swallow errors silently"). Recommended fix is `AsyncNotifier` migration + UI surfacing. Distinct from bug 002 in scope.
- **Bug 017** (`bugs/017-typed-logger-missing.md`) — `lib/core/logging/logger.dart` does not exist. Constitution §7.1 step #3 prescribes creating it. Until it lands, no compliant `log()` alternative exists.

## 3. Desired Behavior

After this spec lands:

1. Zero `debugPrint(...)` invocations exist in `lib/features/settings/presentation/providers/settings_provider.dart`.
2. Zero `import 'package:flutter/foundation.dart';` directives exist in that file (the import was added solely for `kDebugMode` and `debugPrint` and serves no other purpose there).
3. Each Left-branch closure contains a single inline comment cross-referencing the deferred work — `// Failure surfacing deferred to bug 003 (UI surface) and bug 017 (typed logger).` — and no executable statements.
4. The Right-branch behavior of all four mutators is identical to today (bit-for-bit `state.copyWith(...)` calls preserved).
5. `dart analyze` passes with zero new warnings or errors.
6. `flutter test` passes — including all 13 existing `SettingsNotifier` tests in `test/features/settings/presentation/providers/settings_provider_test.dart` — without modification to any production-call expectations. (One test name change is acceptable if "does not update state when save fails" is rephrased to clarify that the Left branch is now a no-op by design; the assertion shape stays the same.)
7. `grep -rn "debugPrint\|print(" lib/` returns zero matches across the entire `lib/` tree (today it returns exactly the four targeted sites — no other source files use either function).
8. The dartdoc on each mutator continues to document the "state stays consistent with what was actually saved" contract; no dartdoc claims the failure is logged.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Settings provider | `lib/features/settings/presentation/providers/settings_provider.dart` | Remove `flutter/foundation.dart` import; replace four `if (kDebugMode) { debugPrint(...) }` blocks with one-line cross-reference comments. |
| Settings provider tests | `test/features/settings/presentation/providers/settings_provider_test.dart` | No production assertion changes. Optional rename of the four "does not update state when save fails" tests for clarity (e.g. "leaves state unchanged on failure"). |
| Bug docs | `bugs/002-debugprint-in-settings-provider.md` | Mark `**Fixed**: 2026-05-01 (spec 013)` in the front matter; add `**Status**: Closed` line. |
| Feature docs | `docs/features/settings.md` | Lines 81–88 show a code snippet whose `(failure) { /* log, leave state unchanged */ }` comment misrepresents reality post-fix. Update the comment to `(failure) { /* leave state unchanged — bug 003 will surface to UI */ }`. |

## 5. Acceptance Criteria

- [x] **AC-1**: `lib/features/settings/presentation/providers/settings_provider.dart` contains zero occurrences of `debugPrint`.
- [x] **AC-2**: `lib/features/settings/presentation/providers/settings_provider.dart` contains zero occurrences of `kDebugMode`.
- [x] **AC-3**: `lib/features/settings/presentation/providers/settings_provider.dart` does not import `package:flutter/foundation.dart`.
- [x] **AC-4**: Each of the four `Either.fold` Left branches in `SettingsNotifier` is an empty closure body containing exactly one comment that references both bug 003 and bug 017 (the comment may span multiple `//` lines but must mention both bug numbers).
- [x] **AC-5**: `grep -rn "debugPrint\|print(" lib/` returns zero matches.
- [x] **AC-6**: `dart analyze` exits cleanly (no new warnings, no new errors compared to baseline).
- [x] **AC-7**: `flutter test` passes 100% — the existing 13 tests in `test/features/settings/presentation/providers/settings_provider_test.dart` continue to assert the unchanged "state remains old value on failure" contract for all four mutators.
- [x] **AC-8**: `flutter build apk --debug` succeeds.
- [x] **AC-9**: The Right branch of each mutator is byte-identical (modulo formatter-driven whitespace) to the pre-fix shape — `state = state.copyWith(<field>: <value>);` and nothing else. No new state shape, no new fields, no new providers.
- [x] **AC-10**: `bugs/002-debugprint-in-settings-provider.md` front matter shows `**Status**: Closed` and `**Fixed**: 2026-05-01 (spec 013)`.
- [x] **AC-11**: `docs/features/settings.md:81–88` snippet's failure-branch comment no longer says "log" (it currently does — that comment lies about post-fix reality).
- [x] **AC-12**: Library-level dartdoc on `SettingsNotifier` (lines 32–35) is updated if it implies the failure is logged (it currently doesn't, but verify during implementation).

## 6. Out of Scope

This spec deliberately closes only bug 002. The following gaps are **explicitly NOT addressed**:

- **Bug 003 (silent error swallowing)** — the Left branch will remain a no-op after this spec. Surfacing failures to the UI via `AsyncNotifier` / `AsyncValue.error` / SnackBar is bug 003's scope. Not in this spec.
- **Bug 017 (typed logger)** — creating `lib/core/logging/logger.dart` with a PHI-sanitize layer is bug 017's scope. Not in this spec. The Left-branch comments cross-reference bug 017 so the deferral is visible at the call site.
- **`SettingsNotifier` → `AsyncNotifier` conversion** — bundled with bug 003. Not in this spec.
- **New error-state field on `AppSettings`** — would change the entity shape and ripple into `lib/app.dart` selectors and both selector widgets. Not in this spec.
- **New `lastSettingsErrorProvider` / similar transient error provider** — that's an architectural choice that belongs in the bug 003 spec (Option B from the bug 003 fix-notes).
- **SnackBar / banner / toast UI feedback** — bundled with bug 003. Not in this spec.
- **Test rewrites that change assertion shape** — only optional renames. The four "does not update state when save fails" tests stay structurally identical.
- **Refactoring the four mutators to share their boilerplate** — each mutator is six lines of similar shape, but the constitution's DRY rule kicks in at 3+ occurrences AND DRY warns against premature extraction. Bug 003's `AsyncNotifier` migration will likely refactor this naturally; doing it now would create churn that bug 003 immediately reworks. Not in this spec.
- **Adding a log call elsewhere as a workaround** — there is no compliant logging primitive yet (bug 017). Adding a bare `print` / `debugPrint` / `log` would re-violate §4.2.1.
- **Touching any other feature** — only the settings feature's provider, its tests, and its docs are in scope.

## 7. Technical Constraints

- **Constitution §4.2.1** (`avoid_print`, no `debugPrint`): the rule being enforced.
- **Constitution §4.2** (no silent error swallowing): NOT being satisfied by this spec — the no-op Left branch was already silent in production. This spec does not make §4.2 worse; bug 003 will fix §4.2 properly.
- **Constitution §6.1** (Minimal Changes): every change in this spec must be confined to the four `debugPrint` sites + import removal + dartdoc/docs comment updates. Do not refactor the mutators, do not extract a helper, do not change `AppSettings` shape, do not touch the data layer.
- **Constitution §3.4** (Testing Requirements): the four "fail path" tests remain mandatory. Their assertion shape (state unchanged after failure) is the contract; this spec preserves it.
- **`flutter pub` not invoked**: no dependency changes. Bug 017 will own the eventual `package:logging` add.

## 8. Open Questions

- **Q-A (test rename)**: Worth renaming the four `setX does not update state when save fails` tests to `setX leaves state unchanged on failure (no logging until bug 003)` so a future reader doesn't wonder "why is this contract not logged"? Treat as an implementation-time judgment call — rename is acceptable, keeping the original name is also acceptable. NOT a hard AC.
- **Q-B (single comment vs four comments)**: Each Left-branch closure gets its own one-line comment? Or extract a single named constant/comment block elsewhere? The minimal-change path is one comment per site (four total). Resolved during implementation; should not block approval.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Removing `debugPrint` deletes the only debug-mode breadcrumb a developer would have if SharedPreferences started failing | Med | Low | Bug 003 will replace it with a real UI surface (snackbar) that's observable in BOTH debug and release. Until then, developers diagnosing a settings-write failure can attach a debugger breakpoint to the Left branch — no worse than today's release behavior. |
| Future audit picks up "no debug breadcrumb here" as a regression | Low | Low | The Left-branch comment cross-references bug 003 + bug 017 so the auditor sees the deferral chain. Spec 013 review.md will explicitly note the breadcrumb loss as a known, accepted trade-off. |
| Doc comment update at `docs/features/settings.md:85` is forgotten | Med | Low | Tracked as AC-11. Tech-writer pass during `/finalize` will catch any miss. |
| Bug 003 / bug 017 silently grow stale because their fix is "deferred to themselves" | Med | Med | Both bug files exist; both are referenced in the new code's comments; recurring audits surface unfixed bugs. The deferral is visible, not invisible. |
| Implementation accidentally widens scope (e.g. starts the `AsyncNotifier` migration) | Low | High | Spec §6 is exhaustive about deferrals; `/breakdown` task files will repeat the boundaries; code-reviewer will flag any out-of-scope edit. Same pattern that worked for spec 012's bundling discipline. |
