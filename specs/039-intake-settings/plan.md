# Plan: Intake-Behavior Settings

**Date**: 2026-07-03
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Extend the existing Settings vertical slice with three intake-behavior preferences, modeled as two self-clamping value objects (`IntakeWindow`, `GracePeriod`) plus an `allowMarkAhead` bool, persisted through the established `SharedPreferences` → data-source → repository → use-case → notifier chain, and surfaced on the Settings screen as a new "Intake" section (two −/+ steppers + one switch). No consumer of the settings is wired — this is foundation for Specs B (auto-miss) and C (Today redesign).

## Technical Context

**Architecture**: Clean Architecture, all three layers of `lib/features/settings/` (domain → data → presentation), plus the shared `lib/core/providers/settings_prefs_keys.dart` and `lib/l10n/` ARBs.
**Error Handling**: `Either<Failure, T>` (fpdart). Data-source `catch` boundary + repo `try/catch → Left(Failure.unknown)`; notifier `fold(err → errors stream, ok → state)`.
**State Management**: Riverpod codegen (`@riverpod` use-case providers + the kept-alive `SettingsNotifier`, `name: 'settingsNotifierProvider'` preserved).

## Constitution Compliance

- **§2.1 domain purity** — `IntakeWindow`/`GracePeriod`/`AppSettings` stay pure Dart (no Flutter/drift). ✅ compliant.
- **§2.3 `flutter pub add`** — no new dependency (freezed/riverpod/shared_preferences/fpdart all present). ✅ N/A.
- **§3.2 Either at boundaries** — all new fallible ops return `Either`. ✅ compliant.
- **§4.1.1 screens never call repos** — UI → notifier → use case → repo. ✅ compliant.
- **§4.2.1 system of record** — these are preferences (not PHI) → `SharedPreferences`, not drift. ✅ compliant (mirrors theme/language).
- **§5.1 Settings enumeration** — `intakeWindowMinutes`/`gracePeriodMinutes` are listed; **`allowMarkAhead` is not** → **requires an additive amendment** to §5.1 (attention). Handled as a docs/constitution edit in File Impact.
- **MEMORY — interface-change blast radius** — adding 3 abstract methods to `SettingsRepository` breaks 8 hand-written fakes → all patched + project-wide `dart analyze` (attention, planned).
- **MEMORY — Riverpod `name:` load-bearing** — keep `name: 'settingsNotifierProvider'`. ✅ planned.

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Domain | 2 clamping value objects | `settings/domain/value_objects/intake_window.dart` (new), `grace_period.dart` (new) |
| Domain | Entity +3 fields | `settings/domain/entities/app_settings.dart` (modify) + `.freezed.dart` (regen) |
| Domain | Repo contract +3 methods | `settings/domain/repositories/settings_repository.dart` (modify) |
| Domain | 3 pass-through use cases | `settings/domain/usecases/set_intake_window.dart`, `set_grace_period.dart`, `set_allow_mark_ahead.dart` (new) |
| Core | 3 prefs keys + set | `core/providers/settings_prefs_keys.dart` (modify) → auto-extends cache allowlist |
| Data | 3 getter/setter pairs | `settings/data/datasources/settings_local_data_source.dart` (modify) |
| Data | `load()` +3 fields, +3 `saveX` | `settings/data/repositories/settings_repository_impl.dart` (modify) |
| Presentation | 3 use-case providers + 3 notifier mutators | `settings/presentation/providers/settings_provider.dart` (modify) + `.g.dart` (regen) |
| Presentation | "Intake" section | `settings/presentation/screens/settings_screen.dart` (modify) |
| Presentation | Controls widget + reusable stepper row | `settings/presentation/widgets/intake_settings_controls.dart` (new) |
| l10n | 10 keys ×3 locales | `l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (modify) → regen `AppLocalizations` |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| VO implementation | **Hand-rolled immutable class**: private `const _(this.minutes)` + public clamping `factory`, `static const min/max/defaultValue`, hand-rolled `==`/`hashCode`/`toString` | A clamping smart constructor is a factory with a body → **never `const`**, but `@Default` on the VO field **requires** a const value. A hand `static const defaultValue = _(120)` provides it cleanly; single-field equality is trivial | **freezed** (the `IntakeId` idiom): its generated const factory can't clamp, and layering a clamping factory + a const-default `static` on top is codegen gymnastics with repeated freezed/const friction (MEMORY) — no equality benefit for one field |
| Clamp location | **Single clamp inside the VO factory**; data-source getters pass the raw stored int straight through the factory | DRY — one authority for the range; getters become `IntakeWindow(getInt(key) ?? 120)` | Duplicating `clamp(...)` in the data source (two sources of truth for the range) |
| VO placement | `settings/domain/value_objects/` | Keeps the slice cohesive; Settings owns the preference. Spec C consuming them is a permitted domain→domain import | `core/` shared home — premature; only the settings feature references them today (revisit if a second consumer feels awkward) — OQ-1 |
| Data-source getter guarding | **Unguarded** `getInt`/`getBool` (throw → `load()`'s single catch) | Brand-new keys have no legacy wrong-type data; mirrors the deliberately-unguarded `getManualLanguage` | Per-getter `try/catch` like `getThemeMode` — only needed for the documented legacy `int→String` case, which doesn't apply here (OQ-4) |
| Numeric control | **One file-private reusable `_IntakeStepperTile`** (label, value, −/+, enabled flags, onStep) used by both numeric rows; `SwitchListTile` for the bool | DRY across the two identical steppers (2 real consumers justify the extraction) | Two bespoke rows (repetition); a new shared `core/widgets` stepper (speculative generality — MEMORY) |
| Steps & bounds | Window **step 15**, range [15, 240]; grace **step 5**, range [0, 30]; `−` disabled at min, `+` at max | Defaults (120, 5) land on both grids; ≤ ~15 / 7 taps to traverse; VO clamp is the backstop | Step 1 for grace (31 values — too many taps) — OQ-2 |
| `allowMarkAhead` in constitution | **Amend §5.1** additively (add the field; note the VO representation of the two numerics) | Constitution is law; the field must be recorded there | Leaving §5.1 stale (future audits would flag the divergence) |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `settings/domain/value_objects/intake_window.dart` | Create | Hand-rolled clamping VO, range [15,240], `defaultValue = _(120)` |
| `settings/domain/value_objects/grace_period.dart` | Create | Hand-rolled clamping VO, range [0,30], `defaultValue = _(5)` |
| `settings/domain/entities/app_settings.dart` | Modify | +3 `@Default` fields (`intakeWindow`, `gracePeriod`, `allowMarkAhead`); regen freezed |
| `core/providers/settings_prefs_keys.dart` | Modify | +3 key consts, +3 into `settingsPrefsKeys` set |
| `settings/data/datasources/settings_local_data_source.dart` | Modify | +`getIntakeWindow`/`setIntakeWindow`, `getGracePeriod`/`setGracePeriod`, `getAllowMarkAhead`/`setAllowMarkAhead` |
| `settings/domain/repositories/settings_repository.dart` | Modify | +3 abstract `saveX` methods |
| `settings/data/repositories/settings_repository_impl.dart` | Modify | `load()` populates 3 fields; +3 `saveX` overrides (`try/catch → Either`) |
| `settings/domain/usecases/set_intake_window.dart` | Create | Pass-through use case |
| `settings/domain/usecases/set_grace_period.dart` | Create | Pass-through use case |
| `settings/domain/usecases/set_allow_mark_ahead.dart` | Create | Pass-through use case |
| `settings/presentation/providers/settings_provider.dart` | Modify | +3 use-case providers, +3 notifier mutators; regen `.g.dart` |
| `settings/presentation/screens/settings_screen.dart` | Modify | +"Intake" section header + `IntakeSettingsControls` |
| `settings/presentation/widgets/intake_settings_controls.dart` | Create | 2 steppers + 1 switch, wired to the notifier |
| `l10n/app_en.arb` / `app_de.arb` / `app_uk.arb` | Modify | +10 keys (header, 2 labels + 2 descriptions, mark-ahead label + description, `{minutes}` value, 2 tooltips) |
| `constitution.md` | Modify | Amend §5.1: add `allowMarkAhead`; note `IntakeWindow`/`GracePeriod` VO representation |
| `test/**` (8 hand-written fakes) | Modify | Add no-op overrides for the 3 new repo methods (see Risk) |
| `test/features/settings/**` (new) | Create | VO clamp/equality, data-source round-trip+clamp+default, repo, 3 use cases, 3 notifier mutators, controls widget |

**Additions discovered during planning** (not in the spec's Affected Areas): `constitution.md` §5.1 amendment — surfaced from the §5.1 compliance check.

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/features/settings.md` | Update | Add the "Intake" group; extend the `AppSettings` fields table with the 3 new fields + the 2 VOs and their ranges/defaults |
| `constitution.md` | Update | §5.1 amendment (also listed in File Impact — it is both a rule and a doc) |

No `docs/api/` change (local prefs, no API). No `docs/architecture.md` change (no new pattern — mirrors theme/language).

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Adding 3 methods to `SettingsRepository` breaks the 8 hand-written `implements` fakes → suite won't compile | High | Med | Patch all 8 with no-op `async => const Right(null)` overrides (import the 2 VOs); run **project-wide** `dart analyze`, not changed-file only (MEMORY F037). The 4 `extends Mock` mocks auto-satisfy. |
| freezed `@Default` rejects the VO default (not const) | Low | Med | Hand-rolled VO exposes `static const defaultValue` built via the private const ctor — provably const. Resolved by the VO design decision. |
| `getInt` throws on a legacy wrong-type value | Low | Low | New keys have no legacy data; unguarded getter's throw is contained by `load()`'s existing catch → `Left(Failure.unknown)`. |
| Constitution amendment overlooked | Low | Low | Explicit File Impact + Documentation Impact rows; include in breakdown as its own task. |
| AC coverage gap | — | — | Cross-reference below shows all 17 ACs mapped. |

## AC → Implementation Cross-Reference

| AC | Covered by |
|----|-----------|
| AC-1 (entity defaults) | `app_settings.dart` `@Default` fields + `defaultValue` consts |
| AC-2 / AC-3 (VO clamp + equality) | `intake_window.dart` / `grace_period.dart` factory + hand `==` |
| AC-4 (VO purity) | VOs are plain Dart in `domain/value_objects/` |
| AC-5 (prefs keys in set) | `settings_prefs_keys.dart` +3 consts +set |
| AC-6 (round-trip) | data-source getter/setter pairs |
| AC-7 (clamp on read) | getters route stored int through VO factory |
| AC-8 (missing → default) | `getInt(key) ?? defaultValue.minutes`, `getBool(key) ?? false` |
| AC-9 (`load()` + fields / catch) | `settings_repository_impl.dart` `load()` |
| AC-10 (`saveX` Either) | 3 new repo overrides |
| AC-11 (use cases forward) | 3 new use-case classes |
| AC-12 (notifier mutators) | 3 new `SettingsNotifier` methods (fold idiom) |
| AC-13 (Intake section renders) | `settings_screen.dart` + `intake_settings_controls.dart` |
| AC-14 (stepper step/bounds/switch) | `_IntakeStepperTile` step+enabled logic; `SwitchListTile` |
| AC-15 (error SnackBar, no state change on fail) | existing `settingsErrorsProvider` listen; notifier leaves state on Left |
| AC-16 (ARB parity + regen) | 3 ARB files + `AppLocalizations` regen |
| AC-17 (fakes patched, analyze clean) | 8 fake patches + project-wide analyze |

## Dependencies

None. All packages present (`freezed`, `riverpod_generator`, `shared_preferences`, `fpdart`). Requires a `dart run build_runner build --delete-conflicting-outputs` after freezed/riverpod annotation changes, and `flutter gen-l10n` (implicit in build) after ARB edits.

## Supporting Documents

- [Data Model](data-model.md) — the 2 new VOs, the `AppSettings` extension, and the persistence mapping.
- No `research.md` (no external/technology signals — all within the current stack).
- No `contracts.md` (no API surface — local `SharedPreferences` only).
