# Review Report: 009-theme-settings

**Date**: 2026-04-27
**Spec**: specs/009-theme-settings/spec.md
**Changed files**: 22 source + 6 test files

## Security Review

- Critical: 0 | High: 0 | Medium: 1 | Info: 4

- **Medium** — `lib/features/settings/presentation/providers/settings_provider.dart:50-52,69-71`: Silent failure swallowing on persistence errors. The `fold` left branch is an empty callback. While theme data is not sensitive, this touches the constitution's "never swallow errors" spirit. Recommendation: Log via structured logger or surface a snackbar so the user knows save failed.

- **Info** — SharedPreferences scoped to `allowList: {'themeMode', 'useSystemTheme'}` in `main.dart` — correct defense-in-depth against accidental medication data storage.
- **Info** — No INTERNET permission additions, no new network-capable deps, no secrets found.
- **Info** — Zero `!` null assertions, zero `dynamic` types, zero `print()`/`debugPrint()` across all files.
- **Info** — `shared_preferences` and `fpdart` are well-maintained pub.dev packages.

## Performance Review

- High: 0 | Medium: 1 | Low: 1

- **Medium** — `lib/app.dart:58`: `DoslyApp` watches full `settingsProvider` (the entire `AppSettings` object). Any state write — including `useSystemTheme` toggle that doesn't change `effectiveThemeMode` — triggers a `MaterialApp.router` rebuild. Recommendation: Use `.select()` to scope the watch: `ref.watch(settingsProvider.select((s) => s.effectiveThemeMode))`.

- **Low** — `lib/features/settings/presentation/screens/settings_screen.dart:46-49`: `Theme.of(context)` called twice in same `build`. Assign once to a local variable.

## Test Assessment

- AC items with test coverage: 6 of 11 (AC-9/10/11 are build gates, not test targets)
- Verdict: **GAPS FOUND**

### Gaps

| AC | Gap | Priority |
|----|-----|----------|
| AC-1 | "Appearance" subheader not tested in any locale | High |
| AC-5 | Persistence round-trip (save + reload fresh instance) not tested | High |
| AC-8 | "Appearance" header not checked in UK/DE locale (only AppBar title tested) | Medium |
| AC-2 | Disabled SegmentedButton tap-while-disabled not behaviorally tested | Low |
| AC-6 | AppSettings extensibility (default-field safety on old prefs) not tested | Low |
