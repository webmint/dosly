# Spec: Intake-Behavior Settings

**Date**: 2026-07-03
**Status**: Complete
**Author**: Claude + Mykola

## 1. Overview

Add three user-configurable **intake-behavior preferences** to the Settings feature: **intake window** (how long after a dose's scheduled time it stays actionable, default 120 min, range 15–240), **grace period** (how long a confirmed dose can be undone, default 5 min, range 0–30), and a new **allow mark-ahead** toggle (whether doses may be marked before their window opens, default off). These are persisted via `SharedPreferences` mirroring the existing theme/language pattern, exposed on the Settings screen as stepper + switch controls, and modeled with two clamping value objects (`IntakeWindow`, `GracePeriod`).

This is **foundation only** — the first of a three-spec chain (see `research/2026-07-03-today-hourly-grouping-full-fidelity.md`). It stores and surfaces the settings; **wiring any consumer** (the redesigned Today screen, the auto-miss engine, and rewiring the existing hardcoded undo-grace constant) is explicitly deferred to Specs B and C. Grounded in the constitution §5.1/§5.2 which already pre-define these knobs, their defaults, and their ranges.

## 2. Current State

### The Settings feature (the pattern to mirror — fully built)
A complete Clean-Architecture vertical slice under `lib/features/settings/`, currently carrying **two** concern groups only (Appearance/theme + Language):

- **Domain entity** — `domain/entities/app_settings.dart`: a `@freezed` `AppSettings` with four fields, each with a `@Default`: `useSystemTheme` (`true`), `manualThemeMode` (`AppThemeMode.light`), `useSystemLanguage` (`true`), `manualLanguage` (`AppLanguage.en`). Pure Dart — **no Flutter SDK types** (constitution §2.1); the Flutter mapping lives at the `lib/app.dart` seam.
- **Domain value/enum types** — `domain/entities/app_theme_mode.dart`, `app_language.dart`: domain-owned enums with a stable `code` string and a `fromCodeOrDefault` graceful-fallback helper. There are **no `value_objects/` under settings yet**.
- **Repository contract** — `domain/repositories/settings_repository.dart`: `Either<Failure, AppSettings> load()` (sync) plus four `Future<Either<Failure, void>> saveX(...)` mutators (`saveThemeMode`, `saveUseSystemTheme`, `saveUseSystemLanguage`, `saveManualLanguage`).
- **Use cases** — `domain/usecases/set_theme_mode.dart`, `set_use_system_theme.dart`, `set_use_system_language.dart`, `set_manual_language.dart`: each a thin pass-through class with a `call(...)` forwarding to the matching repo `saveX` (constitution §4.1.1 — screens never call repos directly).
- **Data layer**:
  - `data/datasources/settings_local_data_source.dart` — thin wrapper over `SharedPreferencesWithCache`. Reads are **synchronous** (`getString`/`getBool`); writes return a `Future`. `getThemeMode()` is guarded (catches a legacy `int→String` `TypeError` and falls back to default); `getManualLanguage()` is deliberately unguarded (a wrong-type throw propagates to `load()`'s single `catch`). Each getter falls back to a per-field default when the key is absent.
  - `data/repositories/settings_repository_impl.dart` — `load()` builds `AppSettings` from the four getters inside one `try/catch` (→ `Left(Failure.unknown(e, st))`); each `saveX` wraps its data-source write in `try/catch`.
- **Presentation**:
  - `presentation/providers/settings_provider.dart` — `settingsRepositoryProvider` wires the data source; four `@riverpod` use-case providers; `@Riverpod(keepAlive: true, name: 'settingsNotifierProvider')` `SettingsNotifier` holds `AppSettings` state (seeded from `repo.load().fold(default, id)`), exposes a broadcast `errors` stream, and one mutator per setting (`fold(err→_errors.add, ok→state = state.copyWith(...))`). `settingsErrorsProvider` re-exposes the stream. **`name:` on the annotation is load-bearing** — codegen would otherwise strip `Notifier` and emit `settingsProvider` (MEMORY, Feature 015).
  - `presentation/screens/settings_screen.dart` — a `ListView` of section headers (`labelSmall`, primary, uppercased) each followed by a widget: `ThemeSelector`, `LanguageSelector`. `ref.listen(settingsErrorsProvider, …)` shows a floating error SnackBar (`settingsPersistenceError`).
  - `presentation/widgets/theme_selector.dart`, `language_selector.dart` — the section control widgets.

### The prefs-key single source of truth
`lib/core/providers/settings_prefs_keys.dart` — a constants-only library holding the four key strings **and** the `settingsPrefsKeys` `Set<String>`. `lib/core/providers/shared_preferences_provider.dart` builds the app-wide `SharedPreferencesWithCache` with `allowList: settingsPrefsKeys` — so **adding a key to the set automatically extends the cache allowlist** (they cannot drift). Any read/write of a key NOT in the allowlist is dropped by the cache.

### Constitution contract (already authored — this spec implements it)
`constitution.md §5.1/§5.2`:
- `Settings` = `{ gracePeriodMinutes (default 5), intakeWindowMinutes (default 120), notificationLeadMinutes (default 0), quietHoursStart, quietHoursEnd }`. `value_objects/` (§ line 45) names **`IntakeWindow`** as an anticipated wrapper type.
- **Grace period**: default 5 min, adjustable in Settings, **range 0–30**.
- **Intake window**: default 120 min, adjustable in Settings, **range 15–240**. "An intake remains `pending` from `scheduledAt − notificationLeadMinutes` until `scheduledAt + intakeWindowMinutes`; after the window closes it auto-transitions to `missed`." (The consuming behavior is Specs B/C.)
- `allowMarkAhead` is **NOT** in the §5.1 enumeration — this spec introduces it as an **additive amendment** (governs whether a dose is actionable before its window opens).

### Existing grace constant (NOT rewired here)
`lib/features/meds/domain/value_objects/intake_grace.dart` defines `kIntakeUndoGracePeriod` (a hardcoded `Duration` of 5 min), consumed by `today_view_model.dart` and `undo_intake.dart`. This spec **does not** rewire that constant to read the new `gracePeriod` setting — that is a Spec C consumer change.

### Relevant MEMORY.md lessons
- **Interface-change blast radius** (Feature 037): adding a method to `SettingsRepository` breaks every hand-written test fake that `implements` it; per-task changed-file `dart analyze` won't catch it. Enumerate all implementers and run **project-wide** `dart analyze`. Confirmed implementers below.
- **Riverpod codegen strips `Notifier`** (Feature 015): keep the `name:` argument shape when touching the notifier.
- **`flutter pub add`, never hand-edit `pubspec.yaml`** (Feature 030) — no new deps expected here.

## 3. Desired Behavior

### 3.1 Value objects (pure domain)
Two immutable value objects under the settings domain, each with **value equality** and a **clamping smart constructor**:
- **`IntakeWindow`** — wraps `int minutes`, clamped to **[15, 240]**. `IntakeWindow(10).minutes == 15`, `IntakeWindow(500).minutes == 240`, `IntakeWindow(120).minutes == 120`. Exposes a const default of **120**.
- **`GracePeriod`** — wraps `int minutes`, clamped to **[0, 30]**. `GracePeriod(-1).minutes == 0`, `GracePeriod(99).minutes == 30`, `GracePeriod(5).minutes == 5`. Exposes a const default of **5**.

No Flutter/drift imports. These become the canonical representation of the two numeric settings (a deliberate refinement of the constitution's "int" fields — semantically equivalent, but type-safe and self-clamping).

### 3.2 Entity extension
`AppSettings` gains three fields with defaults:
- `intakeWindow: IntakeWindow` — default `IntakeWindow(120)`
- `gracePeriod: GracePeriod` — default `GracePeriod(5)`
- `allowMarkAhead: bool` — default `false`

A default-constructed `AppSettings()` returns those three defaults alongside the existing four fields.

### 3.3 Persistence
- Three new keys in `settings_prefs_keys.dart` (`intakeWindowMinutes`, `gracePeriodMinutes`, `allowMarkAhead`), added to the `settingsPrefsKeys` set (auto-extends the cache allowlist).
- Data-source read/write pairs:
  - `getIntakeWindow()` / `setIntakeWindow(IntakeWindow)` — persist the `int minutes`; on read, **clamp to nearest valid** (500→240, 3→15) and return default (120) when the key is absent.
  - `getGracePeriod()` / `setGracePeriod(GracePeriod)` — persist the `int minutes`; on read clamp (99→30, −5→0), default (5) when absent.
  - `getAllowMarkAhead()` / `setAllowMarkAhead(bool)` — default `false` when absent.
- Reads are synchronous (cache-backed); writes return a `Future`. The value object's smart constructor is the single clamp implementation the getters reuse — so any out-of-range stored value is normalized on the way out.

### 3.4 Repository + use cases
- `SettingsRepository` gains three abstract mutators: `saveIntakeWindow(IntakeWindow)`, `saveGracePeriod(GracePeriod)`, `saveAllowMarkAhead(bool)` — each `Future<Either<Failure, void>>`.
- `SettingsRepositoryImpl.load()` populates the three new `AppSettings` fields from the new getters (still inside the one `try/catch`); three new `saveX` overrides wrap their writes in `try/catch → Either`.
- Three new pass-through use cases: `SetIntakeWindow`, `SetGracePeriod`, `SetAllowMarkAhead`, each forwarding `call(...)` to the matching repo method.

### 3.5 Provider + notifier
- Three new `@riverpod` use-case providers (`setIntakeWindow`, `setGracePeriod`, `setAllowMarkAhead`).
- Three new `SettingsNotifier` mutators (`setIntakeWindow`, `setGracePeriod`, `setAllowMarkAhead`), each mirroring the existing idiom: `await` the use case, `fold(err → _errors.add(err), ok → state = state.copyWith(...))`. On failure the in-memory state is **not** changed.

### 3.6 Settings screen UI
A new **"Intake"** section on `SettingsScreen` (header styled like the existing Appearance/Language headers), placed after Language, containing:
- **Intake window** stepper row: label + current value ("120 min") + `−`/`+` icon buttons. Step **15 min**; `−` disabled at 15, `+` disabled at 240. Tapping persists via `settingsNotifierProvider.setIntakeWindow(...)` and updates the displayed value.
- **Grace period** stepper row: same pattern. Step **5 min**; `−` disabled at 0, `+` disabled at 30.
- **Allow mark-ahead** switch row: label + subtitle + a `Switch`/`SwitchListTile`, wired to `setAllowMarkAhead(...)`.
- Persistence failures surface through the existing `settingsErrorsProvider` SnackBar (no new error surface).

### 3.7 Localization
New ARB keys in `app_en.arb` (with `@`-descriptions) + parity in `app_de.arb` and `app_uk.arb`: the section header, the two numeric labels, a `{minutes}`-placeholder value string ("{minutes} min"), the mark-ahead label + subtitle, and increment/decrement button tooltips (accessibility).

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Value objects | `lib/features/settings/domain/value_objects/intake_window.dart`, `grace_period.dart` | **Create new** — clamping VOs with value equality |
| Entity | `lib/features/settings/domain/entities/app_settings.dart` | Add 3 fields + defaults; regenerate `.freezed.dart` |
| Prefs keys | `lib/core/providers/settings_prefs_keys.dart` | Add 3 key constants + add to `settingsPrefsKeys` set (auto-extends cache allowlist) |
| Data source | `lib/features/settings/data/datasources/settings_local_data_source.dart` | Add 3 getter/setter pairs; clamp-on-read via the VOs |
| Repo contract | `lib/features/settings/domain/repositories/settings_repository.dart` | Add 3 abstract `saveX` methods |
| Repo impl | `lib/features/settings/data/repositories/settings_repository_impl.dart` | Populate 3 fields in `load()`; add 3 `saveX` overrides |
| Use cases | `lib/features/settings/domain/usecases/set_intake_window.dart`, `set_grace_period.dart`, `set_allow_mark_ahead.dart` | **Create new** — pass-through use cases |
| Provider | `lib/features/settings/presentation/providers/settings_provider.dart` | Add 3 use-case providers + 3 notifier mutators; regenerate `.g.dart` |
| Screen | `lib/features/settings/presentation/screens/settings_screen.dart` | Add "Intake" section header + controls |
| Widgets | `lib/features/settings/presentation/widgets/intake_settings_controls.dart` (+ a reusable stepper row) | **Create new** — two steppers + one switch |
| l10n | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` | Add section/label/value/subtitle/tooltip keys (regenerates `AppLocalizations`) |
| Test fakes (blast radius) | `test/app_bootstrap_test.dart`, `test/widget_test.dart`, `test/core/routing/app_router_test.dart`, `test/features/settings/presentation/screens/settings_screen_test.dart`, `.../providers/settings_provider_test.dart` (×2 fakes), `.../widgets/theme_selector_test.dart`, `.../widgets/language_selector_test.dart` | Add no-op overrides for the 3 new methods to the **8 hand-written `implements SettingsRepository` fakes** (the 4 `extends Mock` mocks auto-satisfy) |
| New tests | `test/features/settings/domain/value_objects/…`, `.../data/datasources/…`, `.../data/repositories/…`, `.../domain/usecases/…`, `.../presentation/providers/…`, `.../presentation/widgets/…` | **Create new** — VO clamp, data-source round-trip+clamp, repo, use cases, notifier mutators, widget |

## 5. Acceptance Criteria

- [x] **AC-1**: `AppSettings()` (all defaults) has `intakeWindow == IntakeWindow(120)`, `gracePeriod == GracePeriod(5)`, and `allowMarkAhead == false`, while the existing four fields keep their current defaults.
- [x] **AC-2**: `IntakeWindow` clamps its input to [15, 240]: `IntakeWindow(10).minutes == 15`, `IntakeWindow(500).minutes == 240`, `IntakeWindow(120).minutes == 120`; two instances with equal `minutes` are `==`.
- [x] **AC-3**: `GracePeriod` clamps its input to [0, 30]: `GracePeriod(-1).minutes == 0`, `GracePeriod(99).minutes == 30`, `GracePeriod(5).minutes == 5`; value equality holds.
- [x] **AC-4**: Both value objects are pure Dart — no `package:flutter`, `package:drift`, or data-layer imports (they pass a domain-purity import check).
- [x] **AC-5**: `settings_prefs_keys.dart` defines the 3 new key constants and includes all 3 in the `settingsPrefsKeys` set (so the cache allowlist covers them).
- [x] **AC-6**: Data source round-trips: after `setIntakeWindow(IntakeWindow(90))`, `getIntakeWindow() == IntakeWindow(90)`; after `setGracePeriod(GracePeriod(10))`, `getGracePeriod() == GracePeriod(10)`; after `setAllowMarkAhead(true)`, `getAllowMarkAhead() == true`.
- [x] **AC-7**: Clamp on read — a raw stored `intakeWindowMinutes` of `500` reads back as `IntakeWindow(240)`, `3` reads back as `IntakeWindow(15)`; a raw `gracePeriodMinutes` of `99` reads back as `GracePeriod(30)`, `-5` as `GracePeriod(0)`.
- [x] **AC-8**: Missing keys read back as defaults: `getIntakeWindow() == IntakeWindow(120)`, `getGracePeriod() == GracePeriod(5)`, `getAllowMarkAhead() == false`.
- [x] **AC-9**: `SettingsRepository.load()` returns `Right(AppSettings)` with the 3 new fields populated from the data source; when a data-source read throws, it returns `Left(Failure.unknown)` (existing single-catch behavior preserved).
- [x] **AC-10**: Each new repo mutator (`saveIntakeWindow`/`saveGracePeriod`/`saveAllowMarkAhead`) returns `Right(null)` on a successful write and `Left(Failure.unknown)` when the write throws.
- [x] **AC-11**: Each new use case (`SetIntakeWindow`/`SetGracePeriod`/`SetAllowMarkAhead`) forwards `call(...)` to the matching repo method and returns its `Either` unchanged.
- [x] **AC-12**: Each new `SettingsNotifier` mutator, on repo success, updates `state` via `copyWith` (only the target field changes); on repo failure, `state` is unchanged and the `Failure` is emitted on the `errors` stream.
- [x] **AC-13**: `SettingsScreen` renders a new "Intake" section (localized header) after Language, containing an intake-window stepper, a grace-period stepper, and an allow-mark-ahead switch reflecting current `AppSettings` values.
- [x] **AC-14**: The intake-window stepper `+` advances by 15 (120→135) and persists; `−` decrements by 15; `−` is disabled at 15 and `+` at 240. The grace stepper steps by 5, disabled at 0 (`−`) and 30 (`+`). The switch toggles `allowMarkAhead`.
- [x] **AC-15**: A persistence failure from any new control surfaces the existing localized error SnackBar (via `settingsErrorsProvider`); the displayed value does not change on failure.
- [x] **AC-16**: All 3 new ARB keys (+ the `{minutes}` value string, mark-ahead subtitle, tooltips) exist in `app_en.arb`, `app_de.arb`, and `app_uk.arb`, and `AppLocalizations` regenerates cleanly.
- [x] **AC-17**: The 8 hand-written `implements SettingsRepository` fakes are updated with no-op overrides for the 3 new methods; project-wide `dart analyze` is clean and the full existing suite still compiles and passes.

## 6. Out of Scope

- **NOT included**: Any consumer of the new settings — the **Today-screen redesign** (Spec C), the **auto-miss engine** (Spec B), and **rewiring `kIntakeUndoGracePeriod`/`undo_intake.dart`/`today_view_model.dart`** to read the new `gracePeriod`. These settings are stored and displayed only; nothing reads them yet.
- **NOT included**: `notificationLeadMinutes`, `quietHoursStart`, `quietHoursEnd` (other constitution §5.1 fields) — not added in this spec.
- **NOT included**: Any drift/database schema change or migration — these are `SharedPreferences`, not PHI.
- **NOT included**: Notifications, reminders, background jobs, or the "Manual Correction" audit-logged edit flow.
- **NOT included**: Reset-to-defaults control, per-medication overrides, or import/export of settings.
- **NOT included**: New locales beyond en/de/uk.

## 7. Technical Constraints

- **Clean Architecture + `Either`/fpdart**: every fallible op returns `Either<Failure, T>`; the data-source `catch` boundary and repo `try/catch` idiom are preserved (constitution §3.2).
- **Domain purity (§2.1)**: `IntakeWindow`/`GracePeriod` and `AppSettings` stay Flutter-free; the freezed entity keeps no SDK types.
- **Riverpod codegen**: new providers via `@riverpod`; the `SettingsNotifier`'s `name: 'settingsNotifierProvider'` argument must remain (MEMORY, Feature 015). Run `dart run build_runner build` after annotation/freezed changes.
- **Prefs single source of truth**: new keys go through `settings_prefs_keys.dart` → `settingsPrefsKeys`; never hand-add to the cache allowlist elsewhere.
- **Clamping is centralized**: the value-object smart constructor is the one clamp; the data-source getters reuse it (defense in depth — never surface an out-of-range value).
- **freezed `@Default` needs a compile-time constant**: `IntakeWindow`/`GracePeriod` must expose `const` default instances (e.g. `const IntakeWindow.raw(120)` / a `static const` default) usable in `@Default(...)`. Resolve the exact const-construction mechanism in `/plan`.
- **Interface-change blast radius (MEMORY, Feature 037)**: adding 3 methods to `SettingsRepository` breaks the 8 hand-written fakes — update all, and run **project-wide** `dart analyze`, not just changed-file analyze.
- **Constitution amendment**: `allowMarkAhead` is additive to §5.1; update the §5.1 Settings enumeration (and note the VO representation of the two numerics) as part of implementation/docs.
- **24-hour / units**: display values as "N min" via a localized `{minutes}` placeholder; no time-of-day formatting involved.

## 8. Open Questions

- **OQ-1 (VO placement)**: `lib/features/settings/domain/value_objects/` (chosen — keeps the slice cohesive) vs a shared/core location, given Spec C's Today screen (in the `meds` feature) will consume these VOs (a domain→domain cross-feature import). Default to settings; `/plan` may relocate if it prefers a neutral home.
- **OQ-2 (grace step)**: grace stepper increment of **5** (chosen — 0/5/…/30, ≤7 taps) vs 1 (finer, 31 values). Window step is 15.
- **OQ-3 (constitution text)**: update §5.1 now (add `allowMarkAhead`, note VO representation) vs in a later docs pass.
- **OQ-4 (data-source clamp guarding)**: whether the new int getters need `getThemeMode`-style `try/catch` for legacy wrong-type values, or the unguarded-then-`load()`-catch approach (like `getManualLanguage`) suffices. Lean unguarded (no legacy int keys exist for these brand-new keys).

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Adding 3 methods to `SettingsRepository` breaks the 8 hand-written fakes → whole suite stops compiling | High | Med | Enumerated in Affected Areas; add no-op overrides to all 8; run project-wide `dart analyze` (AC-17). |
| `@Default` with a value-object field fails to compile (needs const) | Med | Med | Provide `const` default constructors/instances (Technical Constraints); decide the exact form in `/plan`. |
| Cross-feature domain import when Spec C consumes the VOs | Low | Low | Domain→domain imports are permitted (pure Dart, no cycle); revisit placement in OQ-1 if it becomes awkward. |
| Steppers allow out-of-range taps at the boundary | Low | Low | Disable `−` at min and `+` at max; VO clamp is the backstop (AC-14). |
| `notificationLeadMinutes` referenced by the window formula but not built | Low | Low | Explicitly out of scope; the window's `− notificationLeadMinutes` term is a Spec B/C consumer concern, not stored here. |
