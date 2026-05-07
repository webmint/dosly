# Task 001: Remove `debugPrint` calls from `SettingsNotifier`

**Status**: Complete
**Agent**: mobile-engineer
**Files**:
- `lib/features/settings/presentation/providers/settings_provider.dart` (modify)
- `test/features/settings/presentation/providers/settings_provider_test.dart` (modify — optional rename only, no assertion changes)

**Depends on**: None
**Blocks**: 002
**Context docs**: `docs/features/settings.md` (read for the documented "state stays consistent with what was actually saved" contract that this task must preserve byte-for-byte)
**Review checkpoint**: No

## Description

Eliminate all four `debugPrint` invocations in `SettingsNotifier` (the source of bug 002, a constitution §4.2.1 violation). Each `Either.fold` Left branch — currently `(failure) { if (kDebugMode) { debugPrint('Settings: persistence failed — $failure'); } }` — becomes an empty closure body holding a single comment cross-referencing bug 003 (deferred UI surface) and bug 017 (deferred typed logger).

Production behavior is bit-identical to today: the Left branch was already a no-op in release because `kDebugMode == false`. Debug-mode console output for these specific failures is intentionally lost; bug 003 will replace it with an observable UI surface, and bug 017 will provide a compliant logger primitive.

The Right branch of every mutator is preserved unchanged. The `Notifier<AppSettings>` shape is preserved (the `AsyncNotifier` migration is bug 003's scope). No new state field, no new provider, no helper extraction.

## Change details

- In `lib/features/settings/presentation/providers/settings_provider.dart`:
  - **Remove the import** `import 'package:flutter/foundation.dart';` (currently line 8). It is no longer needed — `kDebugMode` and `debugPrint` were its only consumers in this file.
  - **For `setThemeMode` (currently lines ~50–63)**: replace the Left-branch closure body
    ```dart
    (failure) {
      if (kDebugMode) {
        debugPrint('Settings: persistence failed — $failure');
      }
    },
    ```
    with
    ```dart
    (_) {
      // Failure surfacing deferred to bug 003 (UI surface) and bug 017 (typed logger).
    },
    ```
    Note: parameter renamed `failure` → `_` because it is no longer referenced.
  - **For `setUseSystemTheme` (currently lines ~69–82)**: same replacement pattern.
  - **For `setUseSystemLanguage` (currently lines ~88–101)**: same replacement pattern.
  - **For `setManualLanguage` (currently lines ~106–119)**: same replacement pattern.
  - **Right branches unchanged**: every `(_) { state = state.copyWith(<field>: <value>); }` block stays byte-identical (modulo any whitespace `dart format` normalises).
  - **Library-level dartdoc unchanged**: lines 1–6 currently say nothing about logging. Verify during edit; if any wording implies logging, fix inline.
  - **Per-mutator dartdoc unchanged**: each method's `///` block already documents the "On persistence failure the in-memory state is not updated" contract. Do not add or remove wording.

- In `test/features/settings/presentation/providers/settings_provider_test.dart`:
  - **Optional**: rename the four `setX does not update state when save fails` tests to a clearer phrasing such as `setX leaves state unchanged on failure (no logging until bug 003)`. This is a judgment call — either keep the original names OR rename. **Assertion bodies must not change**.
  - **`_FakeSettingsRepository` fixture**: untouched. The four `failOnSaveX` flags continue to drive the failure-path assertions.

## Out of scope (explicit guards — do not do these)

- Do **NOT** convert `SettingsNotifier` to `AsyncNotifier` — that is bug 003's scope.
- Do **NOT** add an error-state field to `AppSettings` — would change entity shape and ripple into `lib/app.dart` and the selector widgets (bug 003).
- Do **NOT** introduce `lib/core/logging/logger.dart` — bug 017's scope.
- Do **NOT** add a new provider (`lastSettingsErrorProvider`, etc.) — bug 003's scope.
- Do **NOT** add a `print`, `developer.log`, or any other logging-style call as a workaround — re-violates §4.2.1.
- Do **NOT** extract a private `_ignoreFailure` helper — premature DRY (constitution §3.6: wait for the third occurrence; bug 003 will refactor anyway).
- Do **NOT** modify any file under `lib/features/settings/data/` or `lib/features/settings/domain/`.
- Do **NOT** modify `lib/app.dart`, the selector widgets, or the settings screen.
- Do **NOT** modify `_FakeSettingsRepository` or any test fixture.
- Do **NOT** change the structure or count of the existing 13 tests — the four failure-path assertions are the contract this task must preserve.
- Do **NOT** touch `docs/features/settings.md` or `bugs/002-debugprint-in-settings-provider.md` — those are Task 002's scope.

## Done when

- [x] `grep -n "debugPrint" lib/features/settings/presentation/providers/settings_provider.dart` returns zero matches.
- [x] `grep -n "kDebugMode" lib/features/settings/presentation/providers/settings_provider.dart` returns zero matches.
- [x] `grep -n "package:flutter/foundation.dart" lib/features/settings/presentation/providers/settings_provider.dart` returns zero matches.
- [x] All four `Either.fold` Left-branch closures in `SettingsNotifier` have an empty body containing exactly one comment line that includes both `bug 003` and `bug 017` (literal substrings).
- [x] Each of the four mutators' Right branches is byte-identical (modulo formatter whitespace) to the pre-fix shape — `state = state.copyWith(<field>: <value>);`.
- [x] `grep -rn "debugPrint\|print(" lib/` returns zero matches across the entire `lib/` tree.
- [x] `dart analyze 2>&1 | head -40` shows zero new warnings or errors compared to the pre-task baseline.
- [x] `flutter test test/features/settings/presentation/providers/settings_provider_test.dart` passes 100% (all 13 tests green).
- [x] `flutter test` passes 100% across the entire test suite (196/196).
- [x] `flutter build apk --debug` succeeds.

## Completion Notes

**Completed**: 2026-05-01
**Files changed**: `lib/features/settings/presentation/providers/settings_provider.dart` (1 file, 8 +, 17 -)
**Contract**: Expects 6/6 verified | Produces 8/8 verified
**Notes**: Optional test rename (Q-A in spec §8) was deferred — the agent kept the original four `setX does not update state when save fails` test names. All assertion bodies unchanged. Code review APPROVE with zero findings. The single comment line `// Failure surfacing deferred to bug 003 (UI surface) and bug 017 (typed logger).` appears in all four Left-branch closures exactly as specified.

## Spec criteria addressed

AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-12

## Contracts

### Expects (preconditions)

- `lib/features/settings/presentation/providers/settings_provider.dart` exists and exports `class SettingsNotifier extends Notifier<AppSettings>` with four mutator methods: `setThemeMode`, `setUseSystemTheme`, `setUseSystemLanguage`, `setManualLanguage`.
- `lib/features/settings/presentation/providers/settings_provider.dart` currently contains exactly four `debugPrint(` invocations and exactly four `kDebugMode` references, all inside Left-branch closures of `Either.fold` calls.
- `lib/features/settings/presentation/providers/settings_provider.dart` currently imports `package:flutter/foundation.dart`.
- `test/features/settings/presentation/providers/settings_provider_test.dart` exists with `class _FakeSettingsRepository implements SettingsRepository` exposing `bool failOnSaveThemeMode`, `bool failOnSaveUseSystemTheme`, `bool failOnSaveUseSystemLanguage`, `bool failOnSaveManualLanguage`.
- `test/features/settings/presentation/providers/settings_provider_test.dart` contains 13 tests including four that assert state is not updated when the corresponding `failOnSaveX` flag is true.
- `bugs/003-silent-error-swallowing-fold.md` exists.
- `bugs/017-typed-logger-missing.md` exists.

### Produces (postconditions)

- `lib/features/settings/presentation/providers/settings_provider.dart` contains zero occurrences of `debugPrint` (literal substring).
- `lib/features/settings/presentation/providers/settings_provider.dart` contains zero occurrences of `kDebugMode` (literal substring).
- `lib/features/settings/presentation/providers/settings_provider.dart` does not contain the import directive `import 'package:flutter/foundation.dart';`.
- `lib/features/settings/presentation/providers/settings_provider.dart` still exports `class SettingsNotifier extends Notifier<AppSettings>` with the same four public mutator methods (`setThemeMode`, `setUseSystemTheme`, `setUseSystemLanguage`, `setManualLanguage`) — public surface unchanged.
- The four Left-branch closures inside `SettingsNotifier`'s mutators each contain a comment line that includes both literal substrings `bug 003` and `bug 017`.
- Each Right branch contains the literal pattern `state = state.copyWith(` exactly as before.
- `dart analyze` exits clean on the changed file.
- `flutter test` passes 100% project-wide.
