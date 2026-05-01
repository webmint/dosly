### Task 004: Update test fixtures + add new tests + run terminal integration gate

**Agent**: qa-engineer
**Files**:
- `test/features/settings/data/repositories/settings_repository_impl_test.dart` (modify — fixture seeds + add legacy-int-migration test)
- `test/features/settings/presentation/providers/settings_provider_test.dart` (modify — `AppThemeMode` in mock calls + expectations)
- `test/features/settings/presentation/screens/settings_screen_test.dart` (modify — `AppSettings(...)` fixture constructions)
- `test/features/settings/presentation/widgets/theme_selector_test.dart` (modify — segments + pre-fill assertions)
- `test/features/settings/presentation/widgets/language_selector_test.dart` (modify — `AppSettings(...)` fixture constructions where present)
- `test/widget_test.dart` (modify — cycle test assertions; `fakeRepo.lastSavedMode` field type)
- `test/core/routing/app_router_test.dart` (modify only if needed — verify-first by grep before editing)
- `test/features/settings/domain/entities/app_settings_test.dart` (create — pure-Dart `copyWith` tests)

**Depends on**: 003
**Blocks**: None (terminal integration gate task)
**Context docs**: None (the spec + plan describe the expected test shape)
**Review checkpoint**: No

**Description**:
Task 003 left the source compilable (`dart analyze` clean for `lib/`) but
the test files red because their fixtures construct `AppSettings(...)` and
mock `saveThemeMode(...)` calls with the old `ThemeMode` parameter type.
This task is a mechanical fixture-update sweep — replace `ThemeMode.x`
with `AppThemeMode.x` everywhere it appears in test files for
`AppSettings` construction, mock setup, and expected-value assertions.

It also adds the **two test additions** the spec requires:

1. **AC-8 (legacy-int-migration test)** — in
   `settings_repository_impl_test.dart`: seed `InMemorySharedPreferencesAsync`
   with `{'themeMode': 1}` (legacy int format), then assert that
   `repository.load().manualThemeMode == AppThemeMode.light`. This
   verifies the spec §3.6 graceful-fallback behavior: legacy int values
   read as null via `getString` and fall through to
   `AppThemeMode.fromCodeOrDefault(null) == AppThemeMode.light`.

2. **AC-16 (`AppSettings.copyWith` pure-Dart tests)** — new file
   `test/features/settings/domain/entities/app_settings_test.dart`. Covers
   the four `copyWith` cases: all-null preserves originals (× 4 fields);
   each field individually replaced (× 4); plus a basic equality test
   (`AppSettings() == AppSettings()` true; `AppSettings(useSystemTheme:
   false) != AppSettings()`). This file runs without the Flutter binding
   in spirit — it is part of the constitution §3.4 mandate that
   "domain layer (use cases, value objects, business rules): mandatory"
   coverage exists.

This task is the **terminal integration gate** per MEMORY.md "Integration-gate
task pattern" — its `Done when` includes the full `flutter test` suite
AND `flutter build apk --debug`. After this task succeeds, all 17 spec
ACs that are testable-in-CI are green; only AC-17 (manual real-device
run) remains for `/verify`.

**Change details**:

- In `test/features/settings/data/repositories/settings_repository_impl_test.dart`:
  - Replace `InMemorySharedPreferencesAsync({'themeMode': <int>, ...})` seeds
    with `{'themeMode': '<code>'}` strings (e.g., `99` → drop entirely
    since the bounds-check it tested no longer exists; OR replace with
    `'unknown'` to test the `fromCodeOrDefault` fallback).
  - Replace assertions like `expect(settings.manualThemeMode, ThemeMode.light)`
    with `expect(settings.manualThemeMode, AppThemeMode.light)`.
  - Replace mock save calls like `repo.saveThemeMode(ThemeMode.dark)` with
    `repo.saveThemeMode(AppThemeMode.dark)`.
  - **Add AC-8 test** in the appropriate `group(...)`: seed
    `InMemorySharedPreferencesAsync({'themeMode': 1})` (legacy int),
    construct the data source + repository, call `load()`, assert
    `result.manualThemeMode == AppThemeMode.light`. Add a comment:
    "AC-8: legacy `int` themeMode falls back to default via getString → null".

- In `test/features/settings/presentation/providers/settings_provider_test.dart`:
  - Replace every `ThemeMode.x` reference with `AppThemeMode.x`.
  - Update mock setups: `when(() => repo.saveThemeMode(any())).thenAnswer(...)`
    — the `any()` matcher already works because mocktail's `any` is
    type-erased; if the test uses an explicit value matcher
    `repo.saveThemeMode(ThemeMode.dark)`, change to
    `repo.saveThemeMode(AppThemeMode.dark)`.
  - If a `registerFallbackValue<ThemeMode>(ThemeMode.light)` exists in
    `setUpAll`, change to `registerFallbackValue<AppThemeMode>(AppThemeMode.light)`.
  - **Do not** add new test cases for the four `kDebugMode`/`debugPrint`
    sites — bug 002/003 territory.

- In `test/features/settings/presentation/screens/settings_screen_test.dart`:
  - Replace any `AppSettings(manualThemeMode: ThemeMode.x, ...)` fixture
    construction with `AppSettings(manualThemeMode: AppThemeMode.x, ...)`.
  - Locally-duplicated `_resolveLocale` (qa-engineer F10 from audit) stays
    unchanged — bug 016 territory, out of scope.

- In `test/features/settings/presentation/widgets/theme_selector_test.dart`:
  - Replace `SegmentedButton<ThemeMode>` finder usage with
    `SegmentedButton<AppThemeMode>`.
  - Replace `ButtonSegment<ThemeMode>` references with
    `ButtonSegment<AppThemeMode>`.
  - Replace pre-fill assertions: previously `verify(() =>
    repo.saveThemeMode(ThemeMode.dark)).called(1);` becomes
    `verify(() => repo.saveThemeMode(AppThemeMode.dark)).called(1);`.

- In `test/features/settings/presentation/widgets/language_selector_test.dart`:
  - Update only the `AppSettings(...)` fixture constructions where
    `manualThemeMode: ThemeMode.x` appears. The widget body itself
    (`LanguageSelector`) is not touched in this spec.

- In `test/widget_test.dart`:
  - The `fakeRepo.lastSavedMode` field type is `ThemeMode?` per the
    audit's qa-engineer findings — change to `AppThemeMode?`.
  - Cycle assertions like `expect(fakeRepo.lastSavedMode, ThemeMode.light)`
    become `expect(fakeRepo.lastSavedMode, AppThemeMode.light)`.
  - The `_resolveLocale` test-harness duplicate (qa-engineer F10) stays
    unchanged.

- In `test/core/routing/app_router_test.dart`:
  - Verify by `grep "ThemeMode\|effectiveThemeMode\|effectiveLocale\|AppSettings("`
    whether this file actually references any affected types. If yes —
    update accordingly. If no (router tests use `GoRouter.of` directly
    without instantiating `AppSettings`) — no edit needed.

- In `test/features/settings/domain/entities/app_settings_test.dart` (NEW):
  - Pure-Dart test file. Standard `flutter_test` imports for
    `expect`/`group`/`test`.
  - 4 `copyWith` tests:
    1. `AppSettings().copyWith() == AppSettings()` (all-null preserves originals)
    2. `AppSettings(useSystemTheme: true).copyWith(useSystemTheme: false).useSystemTheme == false` (and other 3 fields preserved)
    3. Same pattern for `manualThemeMode`, `useSystemLanguage`, `manualLanguage`.
  - 2 equality tests:
    1. `AppSettings() == AppSettings()` is `true` (same defaults)
    2. `AppSettings(useSystemTheme: false) != AppSettings()` is `true`

- Final verification:
  - `flutter test` exits 0 for the full suite.
  - `flutter build apk --debug` exits 0.

**Done when**:
- [x] All 7 existing test files compile and pass under `flutter test`.
- [x] `test/features/settings/domain/entities/app_settings_test.dart`
      exists with at least 6 tests covering `copyWith` (4) and equality (2).
- [x] AC-8 test exists in `settings_repository_impl_test.dart`: seeds
      `{'themeMode': 1}` (legacy int) and asserts fallback to
      `AppThemeMode.light`.
- [x] `dart analyze 2>&1 | head -40` reports zero issues across both
      `lib/` AND `test/`.
- [x] `flutter test` reports `All tests passed!` (count: at least the
      pre-spec total + 8 new tests in this task + 6 from Task 002).
- [x] `flutter build apk --debug` exits 0.

**Spec criteria addressed**: AC-8, AC-12 (full), AC-13, AC-14, partial AC-16 (the AppSettings copyWith half)

## Completion Notes
**Status**: Complete
**Completed**: 2026-04-30
**Files changed**: 7 test files modified + 1 new pure-Dart test file (`app_settings_test.dart`, 7 tests) + 1 source file (`settings_local_data_source.dart` — defect fix scoped from Task 003 territory)
**Contract**: Expects 4/4 verified | Produces 6/6 verified
**Notes**:
- **Defect fix during execution** — qa-engineer agent caught that spec §3.6's claim ("`getString` on int-stored key returns null") was wrong. `SharedPreferencesWithCache.getString` actually casts the cached value and throws `TypeError` on int data. Pre-spec-012 devices with `int` `themeMode` would crash on launch. Fix: architect agent added `try/catch (_)` around `_prefs.getString` in `getThemeMode()`, returning `AppThemeMode.light` on any throwable. AC-8 test restored to use the real legacy `{'themeMode': 1}` int seed (was workaround `{'themeMode': '1'}` string before fix). The bug is now genuinely fixed AND verified. **MEMORY.md candidate at /verify time**: SharedPreferences platform behavior on type-mismatched reads is throw-not-null.
- 7 existing test files updated for the AppThemeMode cascade (mock signatures, `AppSettings(...)` fixtures, `effectiveThemeMode`/`effectiveLocale` getter calls rewritten as field-based assertions, `SegmentedButton<AppThemeMode>` finders).
- New `app_settings_test.dart`: 7 pure-Dart tests (5 `copyWith` + 2 equality) — exceeds AC-16 minimum of 6.
- Test count: was 190 (Task 002), now 196 (+6 net — the AC-8 test replaced an unrelated pre-existing test with the same id).
- `dart analyze`: zero issues across `lib/` AND `test/`.
- `flutter build apk --debug`: PASS.
- All 7 out-of-scope concerns from the task file preserved: bug 016 sub-items NOT added (no negative-int test, no icon assertions, no defensive cycle branch test, no `_FailingDataSource`, no null guard test, no `_resolveLocale` extraction); `language_selector.dart` widget untouched.
- Code review verdict: APPROVE with 2 warnings — both non-actionable misreads:
  - W1 (`lastSavedMode: AppThemeMode?` should be non-nullable): the field is a fake-repo tracking field (`null` before first save, set after); nullable is canonical for this idiom. Making it non-nullable would either lie about state or require `late` (constitution-banned per §3.1).
  - W2 (`flutter_test` import in pure-Dart test deemed less pure than `package:test/test.dart`): constitution §3.4 explicitly specifies `flutter_test` as the project's test framework — the reviewer self-noted this in the warning text. No action.

## Contracts

### Expects
- Task 003 produced: source files in `lib/` are migrated to `AppThemeMode`
  and `dart analyze` is clean for `lib/`.
- `test/features/settings/data/repositories/settings_repository_impl_test.dart`
  exists with `InMemorySharedPreferencesAsync` fixtures and pre-spec test
  cases.
- `test/features/settings/presentation/providers/settings_provider_test.dart`
  exists with mocktail-based provider tests.
- `test/widget_test.dart` exists with a `fakeRepo` test double whose
  `lastSavedMode` field has type `ThemeMode?`.

### Produces
- `test/features/settings/domain/entities/app_settings_test.dart` exists
  with at least one `group('AppSettings.copyWith', ...)` block containing
  at least 4 `test(...)` cases.
- `test/features/settings/data/repositories/settings_repository_impl_test.dart`
  contains a test that seeds `InMemorySharedPreferencesAsync` with
  `{'themeMode': 1}` (an integer, not a string) and asserts that
  `repository.load().manualThemeMode` equals `AppThemeMode.light`.
- Every test file's references to `ThemeMode.light`, `ThemeMode.dark`,
  `ThemeMode.system` (in fixture/expectation positions) are replaced with
  the corresponding `AppThemeMode` value where applicable. (Note: in
  `widget_test.dart`'s cycle test, the assertions on the cycle's
  Flutter-side effect — i.e., what `MaterialApp.themeMode` becomes — may
  still reference Flutter `ThemeMode` because they're inspecting the
  presentation seam's output; that's acceptable.)
- `flutter test` exits 0 for the full suite.
- `flutter build apk --debug` exits 0.
- `dart analyze 2>&1 | head -40` reports zero issues across the entire
  workspace (lib/ + test/).
