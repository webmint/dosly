# Task 007: Render a real `IntakeStatus.missed` tile + `todayStatusMissed` l10n

**Agent**: mobile-engineer
**Review checkpoint**: No
**Files**: `lib/features/meds/presentation/widgets/today_dose_tile.dart` (modify), `lib/features/meds/domain/entities/intake_status.dart` (modify — stale-comment fix), `lib/l10n/app_en.arb` (modify), `lib/l10n/app_de.arb` (modify), `lib/l10n/app_uk.arb` (modify), `test/features/meds/presentation/widgets/today_dose_tile_test.dart` (modify)
**Depends on**: None
**Blocks**: 009
**Context docs**: `docs/features/meds.md`, `docs/features/i18n.md`

## Description

Replace the placeholder `IntakeStatus.missed => const SizedBox.shrink()` arm in `TodayDoseTile._Actions` with a real, **display-only** rendering: an error-toned localized "Missed" label with no Take/Skip/Undo affordances (a missed dose is locked in this slice — correction is the out-of-scope Manual-Correction flow). The `_Actions` `switch` over `IntakeStatus` stays exhaustive with no `default:`. Add the `todayStatusMissed` key to all three locales. This task is independent of the reconcile engine — it only renders a status the engine will produce.

## Change details

- In `lib/l10n/app_en.arb`: add `"todayStatusMissed": "Missed"` with an `@todayStatusMissed` description ("Status label for a dose whose intake window elapsed without action").
- In `lib/l10n/app_de.arb`: add `"todayStatusMissed": "Verpasst"`.
- In `lib/l10n/app_uk.arb`: add `"todayStatusMissed": "Пропущено"`.
- Regenerate `AppLocalizations` (`flutter gen-l10n` runs via build; ensure `todayStatusMissed` getter exists).
- In `lib/features/meds/presentation/widgets/today_dose_tile.dart`:
  - Change the `IntakeStatus.missed` arm of the `_Actions` `switch` from `const SizedBox.shrink()` to a display-only label — e.g. a small `Text(l10n.todayStatusMissed, style: tt.labelMedium?.copyWith(color: cs.error))` (mirror `_ConfirmedActions`' label treatment but error-colored and with NO Undo/buttons). Keep the switch exhaustive (no `default:`). Update the arm's comment to reflect it is now produced by the auto-miss engine (spec 040) and is intentionally action-free.
- In `lib/features/meds/domain/entities/intake_status.dart` (stale-comment fix, carried over from the Task 004 review): the `missed` value's dartdoc and the library `SLICE NOTE` currently say `missed` is "reserved for a later feature … not produced yet." As of feature 040 the auto-miss engine (`ReconcileMissedIntakes`) DOES produce `missed`. Update those two comments to say `missed` is now written by the auto-miss engine when a dose's intake window elapses without action (constitution §5.2). Do NOT change the enum values or their order (storage-by-name contract).
- In `test/features/meds/presentation/widgets/today_dose_tile_test.dart`:
  - Add a test: a `TodayDose` with `status == IntakeStatus.missed` renders the `todayStatusMissed` text (`cs.error`-styled) and shows NO Take (`todayTake`), Skip (`todaySkip`), or Undo (`todayUndo`) affordance.
  - Add a de + uk render assertion (mirror the existing locale-render pattern in the file) for the missed label.

## Contracts

### Expects
- `today_dose_tile.dart` `_Actions.build` has an exhaustive `switch (dose.status)` whose `IntakeStatus.missed` arm currently returns `const SizedBox.shrink()`.
- `IntakeStatus` includes `missed`; `TodayDose` carries `status`.
- l10n strings are consumed via `context.l10n.*` and defined in `app_en.arb`/`app_de.arb`/`app_uk.arb`.

### Produces
- `app_en.arb`, `app_de.arb`, `app_uk.arb` each contain `todayStatusMissed`; `AppLocalizations` exposes a `todayStatusMissed` getter.
- `today_dose_tile.dart` `IntakeStatus.missed` arm renders `l10n.todayStatusMissed` (not `SizedBox.shrink`) with no Take/Skip/Undo; the `switch` has no `default:`.
- `today_dose_tile_test.dart` asserts the missed label renders (en/de/uk) with no action affordances.

## Done when
- [x] `missed` renders a display-only error-toned "Missed" label; no Take/Skip/Undo present.
- [x] `todayStatusMissed` exists in en (with `@`-desc), de, uk; `AppLocalizations` regenerates cleanly.
- [x] The `_Actions` switch remains exhaustive (no `default:`).
- [x] `flutter test test/features/meds/presentation/widgets/today_dose_tile_test.dart` green; `dart analyze` clean on changed files.

**Spec criteria addressed**: AC-13, AC-14

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-04
**Files changed**: `today_dose_tile.dart`, `intake_status.dart` (comments), `app_en/de/uk.arb` (+ generated `app_localizations*.dart`), `today_dose_tile_test.dart`
**Contract**: Expects [confirmed] | Produces [3/3 verified]
**Notes**: `missed` arm → `Text(l10n.todayStatusMissed, style: tt.labelMedium?.copyWith(color: cs.error))`; display-only, no actions; switch stays exhaustive (no `default:`). `intake_status.dart` comments corrected (values/order byte-unchanged — storage-by-name intact). Added `todayStatusMissed` en "Missed" / de "Verpasst" / uk. **Caught + fixed within task**: uk missed initially "Пропущено" — IDENTICAL to skipped, conflating two §5.2-distinct states; corrected to "Прострочено" (lapsed) + updated the uk test assertion. All 3 locales now pairwise-distinct for missed vs skipped. 16 tests green. Code review: APPROVE. Minor non-blocking Info: a 3-line test call `dart format` would collapse (analyze clean, left as-is per the don't-reflow-untouched-code lesson).
