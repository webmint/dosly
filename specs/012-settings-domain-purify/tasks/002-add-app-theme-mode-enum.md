### Task 002: Add `AppThemeMode` domain enum + pure-Dart test

**Agent**: architect
**Files**:
- `lib/features/settings/domain/entities/app_theme_mode.dart` (create)
- `test/features/settings/domain/entities/app_theme_mode_test.dart` (create)

**Depends on**: None (independent of Task 001 — `AppThemeMode` is plain Dart, no codegen)
**Blocks**: 003
**Context docs**: None (the constitution + spec/data-model.md fully describe the shape)
**Review checkpoint**: No

**Description**:
Introduce the new domain-owned enum `AppThemeMode` with two values
(`light`, `dark`) plus a `code: String` field for stable string
persistence and a static `fromCodeOrDefault(String? code)` helper. The
enum is pure Dart — no `package:flutter/*` import. It will replace
Flutter's `ThemeMode` in the settings domain layer in Task 003.

Cardinality is two values, not three: `system` is owned by the orthogonal
`useSystemTheme: bool` flag on `AppSettings`. This matches the existing
`AppSettings.manualThemeMode` field's documented contract ("Only
`ThemeMode.light` and `ThemeMode.dark` are semantically valid here") and
makes it impossible to ever persist a `system` value as a manual override.
See spec §3.1, plan "Key Design Decisions" row 1, research.md "AppThemeMode
enum cardinality".

The companion test file exercises `fromCodeOrDefault` across five inputs:
`'light'`, `'dark'`, `null`, `''` (empty string), `'unknown'`. This is
the AC-16 pure-Dart-domain-test obligation for the enum half (the
`AppSettings.copyWith` half is added in Task 004 once `AppSettings`
itself is rewritten).

**Change details**:
- In `lib/features/settings/domain/entities/app_theme_mode.dart` (NEW):
  - Library doc comment describing the enum's role and why it is
    2-valued (reference the constitution §3.1 contract on `manualThemeMode`).
  - `enum AppThemeMode { light(code: 'light'), dark(code: 'dark'); const AppThemeMode({required this.code}); final String code; }`
  - Static `static AppThemeMode fromCodeOrDefault(String? code) =>
    AppThemeMode.values.firstWhere((m) => m.code == code, orElse: () => AppThemeMode.light);`
  - Dartdoc on the enum, the `code` field, and the static helper.
  - **Do NOT import** `package:flutter/*`. Use only `dart:core` (implicit).
- In `test/features/settings/domain/entities/app_theme_mode_test.dart` (NEW):
  - `import 'package:flutter_test/flutter_test.dart';` is acceptable for
    `expect`/`group`/`test` (the project standard); the test body itself
    must be runnable as pure Dart logic.
  - `group('AppThemeMode.fromCodeOrDefault', () { ... })` with 5 cases:
    1. `'light'` → `AppThemeMode.light`
    2. `'dark'` → `AppThemeMode.dark`
    3. `null` → `AppThemeMode.light`
    4. `''` (empty string) → `AppThemeMode.light`
    5. `'unknown'` → `AppThemeMode.light`
  - One additional test asserting `AppThemeMode.values.length == 2` so a
    future drive-by 3-value addition is caught.

**Done when**:
- [x] `lib/features/settings/domain/entities/app_theme_mode.dart` exists,
      has zero `package:flutter/*` imports, defines the enum with `code`
      field and `fromCodeOrDefault` static method.
- [x] `test/features/settings/domain/entities/app_theme_mode_test.dart`
      exists with 6 tests (5 `fromCodeOrDefault` cases + 1 cardinality guard).
- [x] `dart analyze 2>&1 | head -40` reports zero issues.
- [x] `flutter test test/features/settings/domain/entities/` exits 0
      with all 6 new tests passing.
- [x] `flutter test` (full suite) continues to pass — pre-existing tests
      are unaffected.

**Spec criteria addressed**: AC-3, partial AC-16 (the AppThemeMode half)

## Completion Notes
**Status**: Complete
**Completed**: 2026-04-30
**Files changed**: lib/features/settings/domain/entities/app_theme_mode.dart (created), test/features/settings/domain/entities/app_theme_mode_test.dart (created)
**Contract**: Expects 3/3 verified | Produces 6/6 verified
**Notes**:
- 2-value cardinality enforced by both code (`enum AppThemeMode { light, dark }` with no `system` member) and a dedicated test (`AppThemeMode.values.length == 2` + `containsAll`).
- Followed the `AppLanguage` precedent for the enhanced-enum-with-`code` style. Minor refinement: `AppThemeMode` uses a named-param constructor (`const AppThemeMode({required this.code})`) rather than `AppLanguage`'s positional form — this aligns with constitution §4.1.1 ("always use named parameters for any constructor or function with more than one parameter") and is a strict improvement, even though `AppLanguage` itself still uses the older positional form. No back-port to `AppLanguage` in this spec — out of scope.
- Pure Dart confirmed: zero `package:flutter/*` imports.
- Test imports `package:flutter_test/flutter_test.dart` for the test runner (idiomatic project convention; re-exports `package:test/test.dart`).
- Test count: 6/6 passing; full suite 190/190 (was 184; +6).
- `dart analyze`: zero issues.
- Code review verdict: APPROVE (zero Critical/Warning; 6 Info notes — none actionable).

## Contracts

### Expects
- `lib/features/settings/domain/entities/` directory exists with
  `app_language.dart` and `app_settings.dart` already in it.
- `dart analyze` is currently clean across the codebase.
- `test/features/settings/domain/entities/` directory does not yet exist
  (or exists empty) — this task creates the first file in it.

### Produces
- `lib/features/settings/domain/entities/app_theme_mode.dart` exists.
- The file declares `enum AppThemeMode { light, dark }` with each value
  carrying a `String code` field whose value is the literal lowercase
  name (`'light'` for `AppThemeMode.light`, `'dark'` for `AppThemeMode.dark`).
- The file declares a static method
  `AppThemeMode.fromCodeOrDefault(String? code)` returning `AppThemeMode`.
- The file imports nothing from `package:flutter/*`.
- `test/features/settings/domain/entities/app_theme_mode_test.dart`
  exists with at least one `group('AppThemeMode.fromCodeOrDefault', …)`
  block and at least 5 `test(…)` cases inside it covering `'light'`,
  `'dark'`, `null`, `''`, `'unknown'`.
- The new test file passes under `flutter test`.
