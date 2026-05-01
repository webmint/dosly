# Bug 002: `debugPrint` in committed code (× 4 sites)

**Status**: Open
**Severity**: Critical
**Source**: audit (audits/2026-04-30-audit.md) — RECURRING from spec 010
**Reported**: 2026-04-30
**Fixed**:

## Description

Constitution §4.2.1 [enforced]: "Never use `print()` or `debugPrint()` in
committed code. Use the typed logger from `core/logging/`. The `avoid_print`
lint must remain enabled."

`lib/features/settings/presentation/providers/settings_provider.dart` contains
four `kDebugMode`-guarded `debugPrint` calls — one inside the Left branch of
each `Either.fold` for the four `SettingsNotifier` mutators. The
`kDebugMode` guard is irrelevant to the rule — the prohibition is unconditional.

The typed logger (`lib/core/logging/logger.dart`, prescribed by constitution
§7.1 step #3) does not exist yet, which is itself a separate gap. Once it
lands, all four sites should route through it (with a sanitize layer per §4.2.1
PHI rule).

This finding was flagged in spec 010 review and remains unfixed.

## File(s)

| File | Detail |
|------|--------|
| lib/features/settings/presentation/providers/settings_provider.dart | Lines ~53, ~72, ~91, ~110 (four identical `debugPrint` sites) |
| lib/core/logging/logger.dart | (does not exist — should be created per constitution §7.1) |

## Evidence

`lib/features/settings/presentation/providers/settings_provider.dart:48–60`:
```
  Future<void> setThemeMode(ThemeMode mode) async {
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

The same pattern is duplicated in `setUseSystemTheme` (lines 67–80),
`setUseSystemLanguage` (lines 86–99), and `setManualLanguage` (lines 104–117).

Reported by audit (code-reviewer F1, architect F3, security-reviewer F1).

## Fix Notes

Likely fixed together with bug 003 (silent error swallowing) — the right
remediation is to surface failures to the UI via `AsyncNotifier`/`AsyncValue.error`
or an explicit error-state field on the notifier, AND remove the `debugPrint`
calls. Until the typed logger lands in `core/logging/`, there is no compliant
"log it" option — the only way to satisfy both §4.2.1 (no debugPrint) and §4.2
(no silent swallow) is to propagate the failure to the UI.

Optional-but-recommended supplement: create `lib/core/logging/logger.dart` per
constitution §7.1 step #3 with a sanitize layer (PHI scrubbing for medication
names, dosages, intake history per §4.2.1).
