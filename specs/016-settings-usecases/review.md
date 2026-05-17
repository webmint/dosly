# Review Report: 016-settings-usecases

**Date**: 2026-05-17
**Spec**: [specs/016-settings-usecases/spec.md](spec.md)
**Plan**: [plan.md](plan.md)
**Changed files**: 19 (11 source/test under `lib/` + `test/`, 1 docs, 2 bug front-matter, 1 generated `*.g.dart`, 1 `pubspec.yaml`, 1 `pubspec.lock`, 2 task spec date fixes)

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 8
- **Verdict**: PASS

### Findings

#### Critical
None.

#### High
None.

#### Medium
None.

#### Info (hardening suggestions)

- **`lib/features/settings/data/datasources/settings_local_data_source.dart:76-82`** — `getManualLanguage` correctly delegates to `AppLanguage.fromLanguageCodeOrDefault` after a `null` check. Note: the protective `try/catch` block that `getThemeMode` carries (against legacy `int`-typed values throwing `TypeError` inside `SharedPreferencesWithCache.getString`, per the spec-012 MEMORY lesson) is intentionally absent here because the `manualLanguage` key has only ever been written as `String`. If the key is ever repurposed or migrated, mirror the defensive `try/catch` from `getThemeMode`.
  Recommendation: leave as-is for now; document for future migrations.

- **`lib/features/settings/domain/usecases/cycle_theme_mode.dart:107-114`** — `_propagateLeft` defensively throws `StateError` if called with a `Right`. The public `call()` only invokes it after `isLeft()`, so the throw is unreachable in well-formed code. Acceptable as-is.
  Recommendation: no change.

- **`lib/features/settings/domain/usecases/set_use_system_theme.dart:46-52` and `set_use_system_language.dart:48-56`** — Pre-fill-then-toggle is sequenced as two distinct `SharedPreferences` writes with short-circuit on `Left`. SharedPreferences offers no atomic multi-key transaction; a process kill between the two writes could leave the pair partially applied (`manual = device`, `toggle = old`). The next app launch interprets this as "system mode still on, manual already pre-filled" — benign and self-healing. No security or data-integrity impact (no medication/PII/health data flows here).
  Recommendation: keep the documented dartdoc warning so future contributors don't collapse the writes and break the short-circuit guarantee.

- **`pubspec.yaml:66` and `pubspec.lock:440-447`** — `mocktail ^1.0.4` is correctly scoped to `dev_dependencies`, resolved to `1.0.5` from `pub.dev` (official Bloc-ecosystem package). No supply-chain concern.
  Recommendation: none.

- No `print` / `debugPrint` / `developer.log` calls anywhere in the changed files. Constitution §4.2.1 (no medication-data logging) is trivially satisfied since no logging is introduced.
- No `dynamic`, no `!` null assertion, no `as` casts in the changed paths. Constitution §3.1 clean.
- All five use cases keep `domain/` free of Flutter imports (only `package:fpdart` and feature-internal). Constitution §2.1 / §4.1.1 satisfied.
- Theme and language preferences are non-sensitive UI flags — `SharedPreferences` is explicitly allowed by constitution §4.2.1. MASVS-STORAGE concerns do not apply. No network code, auth, PII, file I/O, deep links, WebView, or JSON deserialization of untrusted input introduced — most MASVS categories not exercised.

## Performance Review

- High: 0 | Medium: 3 | Low: 5
- **Verdict**: WATCH

### Findings

#### High
None.

#### Medium

- **`lib/features/settings/presentation/widgets/theme_selector.dart:33`** — Unscoped `ref.watch(settingsNotifierProvider)` rebuilds the entire `ThemeSelector` on any `AppSettings` field change (including unrelated language changes). The widget only reads `useSystemTheme` and `manualThemeMode`.
  Recommendation:
  ```dart
  final useSystemTheme = ref.watch(settingsNotifierProvider.select((s) => s.useSystemTheme));
  final manualThemeMode = ref.watch(settingsNotifierProvider.select((s) => s.manualThemeMode));
  ```

- **`lib/features/settings/presentation/widgets/language_selector.dart:35`** — Same pattern: unscoped `ref.watch(settingsNotifierProvider)` rebuilds on theme changes even though the widget only reads `useSystemLanguage` and `manualLanguage`. A theme cycle from `ThemePreviewScreen` triggers a spurious rebuild here.
  Recommendation: narrow to two `select` watches on `useSystemLanguage` and `manualLanguage`.

- **`lib/features/theme_preview/presentation/screens/theme_preview_screen.dart:34`** — Same pattern again. Reads only `useSystemTheme` and `manualThemeMode` but watches the whole notifier. Production impact is zero (dev-only screen, scheduled for removal), but the pattern should not propagate.
  Recommendation: narrow to two `select` watches; or accept and document since the screen is slated for deletion.

#### Low (micro-optimizations)

- `cycle_theme_mode.dart:93` — third branch (`dark → system`) constructs a non-`const` `Right(...)` because `currentManualMode` is a runtime parameter. One allocation per tap. Zero frame budget impact.
- `settings_provider.dart:42-63` — five `@riverpod` function-form providers are autoDispose by default. Use cases hold only a `SettingsRepository` reference (value object). Disposal/recreation is correct and cheap. No issue.
- `app_language.dart:36` — `firstWhere` is O(3) for 3 enum values. Not hot. If the language list grows past ~10, switch to a `Map<String, AppLanguage>` lookup.
- `language_selector.dart:81-85` — `DropdownMenuItem` list rebuilt per build via `for` loop (3 items). Could be `static const` but payoff is negligible at this scale.
- `app.dart` four narrow selects already implemented correctly — the new code does NOT alter that pattern.

### Common thread
All three Medium findings share one root cause: two selector widgets and the dev preview screen `watch` the whole notifier rather than `select`-narrowed scalars. `AppSettings` is a small flat struct, so rebuild cost is shallow. But the pattern explicitly contradicts the four narrow `select`s already in place in `app.dart`. A two-line edit per file resolves all three. Not blocking — these are pre-existing patterns this spec did not introduce, but the spec did touch every affected widget without tightening them.

## Test Assessment

- **Verdict**: ADEQUATE

### AC-to-test mapping (only for ACs that prescribe a test)

| AC | Test file | Status | Notes |
|----|-----------|--------|-------|
| AC-4 | `set_use_system_theme_test.dart` | COVERED | `value=false` path uses `verifyInOrder([saveThemeMode(dark), saveUseSystemTheme(false)])` and asserts `Right(null)`. |
| AC-5 | `set_use_system_theme_test.dart` | COVERED | `value=true` test asserts `verifyNever(() => repo.saveThemeMode(any()))`. |
| AC-6 | `set_use_system_language_test.dart` | COVERED | Mirror of AC-4/5 for `saveManualLanguage`/`saveUseSystemLanguage`. |
| AC-7 | `cycle_theme_mode_test.dart` | COVERED | Three tests for `(true,*)`, `(false,light)`, `(false,dark)`. Return records verified via `result.fold`. |
| AC-12 | `app_language_test.dart` | COVERED | Five tests: `'en'`, `'de'`, `'uk'`, `'xx'`, `''`. |
| AC-15 | (all test files) | COVERED | `flutter test` reported 227/227 in Task 006 integration gate. |
| AC-17 | `theme_selector_test.dart`, `language_selector_test.dart` | COVERED | Pre-fill behaviour + system-on disabled-selection display both verified. |
| AC-18 | `settings_provider_test.dart` | COVERED | Error-stream test group covers all four mutator failure paths + no-emission-on-success + multi-emission sequencing. |

### Coverage Gaps (Warnings — none are AC failures)

- **`CycleThemeMode` second-write failure** _(Priority: Low)_: Only the system-on branch has a two-write sequence. The test covers first-write failure on that branch, but not the case where `saveThemeMode(light)` succeeds and `saveUseSystemTheme(false)` fails. The short-circuit logic is shared with `SetUseSystemTheme`, which already has full two-step coverage — risk is low.
- **`setUseSystemTheme(value: true)` failure path in `settings_provider_test.dart`** _(Priority: Low)_: Provider error-stream test exercises `value=false` only. With `value=true` there's only one write (`saveUseSystemTheme`), so the test indirectly covers it, but no explicit `value=true` failure scenario exists.
- **AC-9 / AC-10**: Both labeled "Verified by reading file" in spec. Each selector has two `notifier` call sites (toggle `onChanged` + segmented/dropdown `onSelectionChanged`/`onChanged`), each containing exactly one notifier call. No widget test asserts "tapping the switch calls exactly one notifier method"; observational gap only.
- **AC-11**: Spec says "Verified by reading file." A higher-level integration test (`tapping Theme preview navigates to the preview and cycling theme mode works`) provides light behavioral coverage.

All gaps are coverage-breadth issues on edge paths already protected at the use-case layer. None represent an untested acceptance criterion.

## Aggregate Outcome

- **Security**: PASS (0/0/0/8 Info)
- **Performance**: WATCH (0/3/5) — three Medium findings on widget watch-scoping, all a single-pattern issue with a two-line fix per file
- **Test coverage**: ADEQUATE — every testable AC has direct coverage; gaps are edge-path breadth, not contract violations

No Critical findings. No blocking issues. The Performance Medium findings are worth a follow-up `/fix` before `/finalize` — they're cheap, local, and align the new code with the existing narrow-`select` pattern already in `app.dart`. Alternatively, accept and document.

Next: Run `/verify` to validate acceptance criteria and render the verdict.
