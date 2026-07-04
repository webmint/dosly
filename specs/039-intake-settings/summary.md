## Feature Summary: 039 — Intake-Behavior Settings

### What was built
Three new user preferences on the Settings screen that will govern how doses are tracked: an **intake window** (how long after a scheduled time a dose stays actionable, default 120 min), a **grace period** (how long a dose can be undone after marking, default 5 min), and an **Allow marking ahead** toggle (default off). They appear as a new "Intake" section with −/+ steppers and a switch, persist across restarts, and are fully localized (en/de/uk). This is *foundation only* — the settings are stored and surfaced but not yet consumed; they unblock the upcoming auto-miss engine (Spec B) and the Today-screen redesign (Spec C).

### Changes
- Task 001: Value objects — hand-rolled, self-clamping `IntakeWindow` (15–240) and `GracePeriod` (0–30) with const defaults.
- Task 002: Prefs keys + data source — 3 SharedPreferences keys (auto-added to the cache allowlist) with clamp-on-read getters/setters.
- Task 003: Entity + constitution — added the 3 fields to `AppSettings`; amended constitution §5.1 for `allowMarkAhead`.
- Task 004: Repo contract + impl + fakes — 3 `saveX` methods, `load()` population, and patched all 8 hand-written `SettingsRepository` fakes.
- Task 005: Use cases — `SetIntakeWindow`/`SetGracePeriod`/`SetAllowMarkAhead` pass-throughs.
- Task 006: Providers + notifier — 3 `@riverpod` use-case providers + 3 `SettingsNotifier` mutators.
- Task 007: l10n — 10 keys across en/de/uk (incl. the `{minutes}` value placeholder + stepper tooltips).
- Task 008: UI — `IntakeSettingsControls` (2 steppers + switch via a reusable stepper row) wired into `SettingsScreen`.
- Tasks 009–011: Tests — value objects, use cases, data source, repository, notifier mutators, and the controls widget.

### Files changed
- `lib/features/settings/` — 12 files (7 domain incl. 2 new VOs + 3 new use cases; 2 data; 3 presentation incl. new controls widget)
- `lib/core/providers/` — 1 file (prefs keys)
- `lib/l10n/` — 3 ARBs (+ 4 regenerated `AppLocalizations` sources)
- `test/features/settings/` — 13 files (8 new, 5 extended) + 3 unrelated fakes patched (`app_bootstrap`, `app_router`, `widget_test`)
- `constitution.md` — §5.1 amendment
- [Total: 57 files changed, +3775 / −77, across 41 WIP commits]

### Key decisions
- **Hand-rolled value objects (not freezed)**: a clamping smart constructor can't be `const`, but freezed `@Default` requires a const value — a `static const defaultValue` via a private const constructor solves it.
- **Single clamp in the VO factory**, reused by the data-source getters (`IntakeWindow(getInt(key) ?? 120)`) — one authority for the range, clamp-on-read for free.
- **Unguarded data-source getters**: a wrong-type persisted value throws into `load()`'s single catch → `Left(Failure.unknown)` → defaults (mirrors the existing `getManualLanguage`).
- **`allowMarkAhead` amends constitution §5.1** (additive) since it wasn't in the original Settings enumeration.

### Deviations from plan
- Task 004: also fixed `settings_repository_impl_test.dart`'s hardcoded `SharedPreferencesWithCache` allowLists (they listed only the old keys → 14 tests reddened once `load()` read the new keys) — a runtime break invisible to `dart analyze`.
- Task 008: adding a 3rd `SwitchListTile` broke 2 positional `find.byType(...).last` test finders → re-scoped to `LanguageSelector`; also extracted a `_SectionHeader` widget (the header block hit the 3× DRY threshold).
- Task 010: the first qa agent's connection dropped after only setup prep → a second agent completed the 28 data-layer tests.
- Post-verify `/fix`: `/review` found top-of-stack coverage gaps → +8 tests (screen-integration mount, 3 failure→SnackBar, `allowMarkAhead` true→false, de/uk render) and corrected a comment that falsely claimed coverage existed.

### Acceptance criteria
- [x] AC-1: `AppSettings()` defaults 120/5/false; existing 4 fields unchanged
- [x] AC-2: `IntakeWindow` clamps [15,240] + value equality
- [x] AC-3: `GracePeriod` clamps [0,30] + value equality
- [x] AC-4: value objects are pure Dart (no Flutter/drift/data imports)
- [x] AC-5: 3 prefs keys declared + in `settingsPrefsKeys`
- [x] AC-6: data-source round-trip (window/grace/bool)
- [x] AC-7: clamp-on-read (500→240, 3→15; 99→30, −5→0)
- [x] AC-8: missing key → default (120/5/false)
- [x] AC-9: `load()` → Right(AppSettings) with 3 fields; Left on throw
- [x] AC-10: each `saveX` → Right(null) / Left on throw
- [x] AC-11: each use case forwards to its repo method
- [x] AC-12: notifier mutators — success updates only the target field; failure leaves state + emits on errors
- [x] AC-13: Settings screen renders the "Intake" section
- [x] AC-14: stepper step/bounds (±15/±5, disabled at bounds); switch toggles
- [x] AC-15: persistence failure → error SnackBar; displayed value unchanged
- [x] AC-16: 3 ARB keys (+ `{minutes}`/tooltips) in en/de/uk; `AppLocalizations` regenerates
- [x] AC-17: 8 fakes patched; project-wide `dart analyze` clean; full suite passes

**Verification**: `/review` — security PASS (0 findings), performance clean, tests GAPS FOUND → closed by `/fix`. `/verify` — **APPROVED**, all 17 ACs PASS, full suite 764/764 green, `dart analyze` clean.
