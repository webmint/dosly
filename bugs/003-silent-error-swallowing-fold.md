# Bug 003: Silent error swallowing in `Either.fold` Left branch (× 4 mutators)

**Status**: Open
**Severity**: Critical
**Source**: audit (audits/2026-04-30-audit.md) — RECURRING from spec 009
**Reported**: 2026-04-30
**Fixed**:

## Description

Constitution §4.2 [universal]: "Never swallow errors silently. Empty `catch`
blocks are forbidden. If you catch an error, you must either: (a) handle it
meaningfully, (b) re-throw it, or (c) log it and explain why you're suppressing
it."

The Left branch of every `Either.fold` in `SettingsNotifier` is a no-op in
production builds. The only side-effect (`debugPrint`) is wrapped in
`if (kDebugMode)`. In release the branch executes nothing — no UI feedback, no
error event, no rethrow. Same shape repeats × 4 across all `setX` mutators.

UI consequence: if SharedPreferences writes start failing silently (e.g., disk
full, corrupted store), the in-memory state stays at old values, the toggle
appears to have responded, but the user's intent is not persisted. The user
discovers the loss only after restart.

Spec 009 review flagged this as Medium and noted it was unfixed. Audit
escalated to Critical because constitution §4.2 explicitly forbids silent
swallowing and the fix has been deferred across 2 specs (009 → 010 → still open).

## File(s)

| File | Detail |
|------|--------|
| lib/features/settings/presentation/providers/settings_provider.dart | Lines 51–55 (setThemeMode); 70–74 (setUseSystemTheme); 89–93 (setUseSystemLanguage); 107–111 (setManualLanguage) |

## Evidence

`lib/features/settings/presentation/providers/settings_provider.dart:51–60`:
```
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
```

Existing tests verify state is NOT updated on failure (correct — that's the
"don't lie about success" half), but no test verifies the production-build
behavior is intentional. The contract "silent in prod" is unverified.

Reported by audit (code-reviewer F2, qa-engineer F1).

## Fix Notes

Suggested approach (to be confirmed in `/fix`):

Option A (preferred): Convert `SettingsNotifier` from `Notifier<AppSettings>`
to `AsyncNotifier<AppSettings>` so failures surface as `AsyncValue.error`.
Widgets read via `.when(data:, error:, loading:)`.

Option B: Keep `Notifier`, but add an error-signal field — either change the
state to a sealed `freezed` union (`Loaded | Error`) or expose a separate
`StreamProvider<Failure>` that the SettingsScreen drains into a snackbar.

In either case:
- Remove the four `debugPrint` calls (closes bug 002 simultaneously).
- Add a contract test asserting that the failure path produces some observable
  signal (closes the qa-engineer F1 finding).
- The pre-fill business rule in `language_selector.dart` and `theme_selector.dart`
  should also move into use cases (bug 005) so a single test covers the
  invariant.

This bug naturally bundles with bug 002 — fixing them together (one PR) is the
sensible scope. Splitting would leave the codebase in a half-fixed state.
