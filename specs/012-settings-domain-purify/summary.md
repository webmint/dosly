## Feature Summary: 012 — Settings Domain Purify

### What was built

The Settings feature's `domain/` and `data/` layers no longer depend on Flutter SDK types — they're pure Dart, just like the constitution mandates. A new domain enum `AppThemeMode` replaces direct use of Flutter's `ThemeMode` for the user's manual theme override; `AppSettings` is now a `@freezed` class with proper value equality; theme persistence switched from `int` (`ThemeMode.index`) to a stable `String` code (`'light'`/`'dark'`); and all `Flutter SDK ↔ domain` type mapping is confined to a single seam in `lib/app.dart` (four narrow `.select()` calls + a `_toFlutterThemeMode` switch). This unblocks pure-Dart domain testing for the Settings feature and resets the project's first `freezed` + `build_runner` codegen pipeline for downstream specs to build on.

### Changes

- **Task 001**: Established `freezed` + `build_runner` codegen pipeline (3 packages added via `flutter pub add`); brought `analysis_options.yaml` into constitution §7.4 compliance (strict-casts/strict-inference/strict-raw-types modes + freezed exclude globs + 18 lint rules — 2 deferred with documented rationale).
- **Task 002**: Added `AppThemeMode { light, dark }` domain enum with `code` field and `fromCodeOrDefault` static helper, plus 6 pure-Dart unit tests.
- **Task 003**: Cascaded the migration across 9 source files — `AppSettings` rewritten as `@freezed abstract class`; Flutter import dropped from settings `domain/` and `data/`; theme persisted as `String`; `effectiveThemeMode`/`effectiveLocale` getters removed; presentation seam in `lib/app.dart` added.
- **Task 004**: Updated 7 test files for the type cascade + added `app_settings_test.dart` (7 pure-Dart tests for `copyWith` + equality); added AC-8 legacy-int migration test. **Defect fix**: caught a launch-day crash on devices with pre-spec `int` themeMode data (spec assumed `getString` returns null on type-mismatched keys; it actually throws `TypeError`) — added a `try/catch` in `getThemeMode()`. Final integration gate: `flutter test` 196/196 + `flutter build apk --debug` PASS.
- **Task 005**: Updated `docs/features/settings.md` (Domain section + Presentation seam + 5 inline updates), `docs/features/i18n.md` (3 stale `effectiveLocale` references rewritten — caught at /review time), and `docs/architecture.md` (spec-012 pull-quote + DoslyApp code sample refresh + allowList expansion to current 4 keys).

### Files changed

Spec/branch totals: **58 files changed, 4,541 insertions, 278 deletions**.

Source code (production):
- `lib/features/settings/domain/` — 1 new (`app_theme_mode.dart`), 1 generated (`app_settings.freezed.dart`, 280 lines, committed), 2 modified (`app_settings.dart`, `settings_repository.dart`)
- `lib/features/settings/data/` — 2 modified (data source, repo impl)
- `lib/features/settings/presentation/` — 2 modified (provider, theme selector)
- `lib/features/theme_preview/` — 1 modified (cycle logic + display mapping)
- `lib/app.dart` — modified (presentation seam: 4 narrow `.select()` calls + `_toFlutterThemeMode`)
- Tooling — `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`

Tests:
- 2 new (`app_theme_mode_test.dart`, `app_settings_test.dart`) — 13 pure-Dart unit tests
- 7 modified (cascade fixture updates + AC-8 legacy-int test)
- Test count: 184 → 196 (+12)

Docs:
- `docs/features/settings.md`, `docs/features/i18n.md`, `docs/architecture.md`

Spec artifacts:
- `specs/012-settings-domain-purify/` — spec.md, plan.md, research.md, data-model.md, 5 task files + README, review.md, verify.md, summary.md

### Key decisions

- **`AppThemeMode` is 2-value (`{ light, dark }`), not 3** — `system` stays in the orthogonal `useSystemTheme: bool` flag. Mirrors the existing `manualThemeMode` field's "only `light`/`dark` are semantically valid" contract; impossible to persist `system` as a manual override.
- **`effectiveThemeMode`/`effectiveLocale` getters removed entirely** (not retyped to domain). The seam in `lib/app.dart` watches the four raw entity fields via `.select(...)` and computes Flutter `themeMode` and `locale` inline. Domain stays free of "what does effective mean" presentation semantics.
- **Theme persistence as stable string code** (not `int.index`) — order-independent across SDK changes; matches the existing `docs/features/settings.md` documented contract that the implementation had drifted from.
- **Auto-fallback for legacy `int` data** — `try/catch` in `getThemeMode()` catches the platform `TypeError` and degrades to default. One-time visual reset on first launch after upgrade is acceptable for this 1-user personal app; no multi-step migration code.

### Deviations from plan

- **Task 001 addendum (constitution §7.4 drift)**: spec/plan/research assumed `analysis_options.yaml` already had the strict-casts modes + `**/*.freezed.dart` exclude glob; verification revealed the file was the bare Flutter scaffold default with no `analyzer:` block at all. Task 001's scope was amended in-place to include bringing the file into compliance — required before Task 003 generated the first `*.freezed.dart`.
- **Task 003 (`freezed` 3.x discovery)**: spec/plan/research showed the freezed 2.x form `@freezed class AppSettings with _$AppSettings`. freezed 3.x requires `@freezed abstract class AppSettings with _$AppSettings`. Architect agent caught this at the analyze-after-codegen step and fixed inline.
- **Task 004 defect (platform-behavior assumption failed)**: spec §3.6 / research.md / AC-8 assumed `_prefs.getString` returns `null` for int-typed keys. qa-engineer verified it actually throws `TypeError`. AC-8 was implemented with a workaround (`'1'` string seed) and escalated; architect added a `try/catch (_)` in `getThemeMode()` and AC-8 was restored to use the genuine `int 1` legacy seed. Without this fix, any pre-spec-012 device upgrading would have crashed on launch.
- **Task 005 scope expansion (i18n.md stale references)**: original task scope listed only `settings.md` and `architecture.md`. Code-reviewer at `/review` time found 3 stale `AppSettings.effectiveLocale` references in `docs/features/i18n.md` presented as current API — constitution §6.4 mandated the doc update. Task 005 was amended in-place to include `i18n.md`.

### Acceptance criteria

- [x] AC-1: Zero `package:flutter` imports in `lib/features/settings/domain/`
- [x] AC-2: Zero `package:flutter` imports in `lib/features/settings/data/`
- [x] AC-3: `app_theme_mode.dart` defines `enum AppThemeMode { light, dark }` with `code` + `fromCodeOrDefault`
- [x] AC-4: `AppSettings` is `@freezed`; `.freezed.dart` committed; `dart analyze` clean
- [x] AC-5: `effectiveThemeMode` / `effectiveLocale` getters removed
- [x] AC-6: `saveThemeMode` parameter type is `AppThemeMode`
- [x] AC-7: Theme persists as `String`; round-trip works
- [x] AC-8: Legacy `int` themeMode reads back as `AppThemeMode.light` (graceful fallback)
- [x] AC-9: Only `lib/app.dart` (and theme_preview for display) maps `AppThemeMode → ThemeMode`
- [x] AC-10: `lib/app.dart` no longer references the removed getters; uses 4 `.select()` + `_toFlutterThemeMode`
- [x] AC-11: `pubspec.yaml` lists `freezed_annotation`, `freezed`, `build_runner`
- [x] AC-12: `dart analyze` clean
- [x] AC-13: `flutter test` passes (196/196)
- [x] AC-14: `flutter build apk --debug` succeeds
- [x] AC-15: `docs/features/settings.md` Domain section references `AppThemeMode`
- [x] AC-16: Pure-Dart test for `AppSettings.copyWith` + `AppThemeMode.fromCodeOrDefault`
- [ ] AC-17: Real-device run shows graceful theme reset (manual — deferred to user post-merge)
