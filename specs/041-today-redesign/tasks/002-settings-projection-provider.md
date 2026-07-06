# Task 002: Add the `todayIntakeSettings` projection provider

**Agent**: architect
**Review checkpoint**: No
**Files**: `lib/features/meds/presentation/providers/intake_providers.dart` (+ regenerated `intake_providers.g.dart`)
**Depends on**: None
**Blocks**: 004, 005, 009
**Context docs**: `docs/architecture.md`

## Description

Expose the three intake-behavior settings (`intakeWindow`, `gracePeriod`, `allowMarkAhead`) to the meds presentation layer through a `@riverpod` projection in the existing composition seam, so the Today screen/view-model never imports `settings/presentation` directly (constitution §2.1). The projection watches the reactive `settingsNotifierProvider` (kept-alive, synchronous) so a Settings change re-emits and updates Today live. `intake_providers.dart` already imports `settings_provider.dart` for the reconcile use case, so this adds no new cross-feature import.

## Change details

- In `lib/features/meds/presentation/providers/intake_providers.dart`:
  - Add a `@riverpod` function `todayIntakeSettings(Ref ref)` returning a record type
    `({IntakeWindow intakeWindow, GracePeriod gracePeriod, bool allowMarkAhead})`.
  - Body: `final s = ref.watch(settingsNotifierProvider); return (intakeWindow: s.intakeWindow, gracePeriod: s.gracePeriod, allowMarkAhead: s.allowMarkAhead);`
  - Add imports for `IntakeWindow` (`../../../settings/domain/value_objects/intake_window.dart`) and `GracePeriod` (`../../../settings/domain/value_objects/grace_period.dart`). `settingsNotifierProvider` is reachable via the already-imported `settings_provider.dart`.
  - dartdoc: note this is the §2.1-compliant seam that keeps screens/widgets settings-free, and that it is reactive (watches the notifier, not a one-shot repo load).
- Regenerate: `dart run build_runner build --delete-conflicting-outputs` → `todayIntakeSettingsProvider` appears in `intake_providers.g.dart`.

## Contracts

### Expects
- `lib/features/settings/presentation/providers/settings_provider.dart` exports `settingsNotifierProvider` whose value is `AppSettings` with fields `intakeWindow` (`IntakeWindow`), `gracePeriod` (`GracePeriod`), `allowMarkAhead` (`bool`).
- `intake_providers.dart` already imports `settings_provider.dart` (composition seam).

### Produces
- `intake_providers.dart` declares `@riverpod` `todayIntakeSettings` returning a record with fields `intakeWindow` (`IntakeWindow`), `gracePeriod` (`GracePeriod`), `allowMarkAhead` (`bool`), and calls `ref.watch(settingsNotifierProvider)`.
- `intake_providers.g.dart` declares `todayIntakeSettingsProvider`.

## Done when
- [x] `todayIntakeSettingsProvider` is generated and returns the three-field record.
- [x] The provider `ref.watch`es `settingsNotifierProvider` (reactive, not `settingsRepositoryProvider.load()`).
- [x] No screen/widget imports `settings/presentation` (the seam remains the only importer).
- [x] `dart analyze` passes on changed/generated files.

**Spec criteria addressed**: AC-8, AC-14

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-05
**Files changed**: `lib/features/meds/presentation/providers/intake_providers.dart` (+ regenerated `intake_providers.g.dart`)
**Contract**: Expects [2/2 verified] | Produces [2/2 verified — `todayIntakeSettings` record provider + generated `todayIntakeSettingsProvider`]
**Notes**: Reactive `@riverpod` record projection `({IntakeWindow intakeWindow, GracePeriod gracePeriod, bool allowMarkAhead})` watching `settingsNotifierProvider`. Two settings-domain VO imports added (no new presentation cross-feature boundary — seam already imported `settings_provider.dart`). Seam invariant verified: only `intake_providers.dart` imports `settings/presentation`. build_runner clean; `dart analyze` clean.
