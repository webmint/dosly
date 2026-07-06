# Task 001: Add Today-redesign localization keys (en/de/uk)

**Agent**: mobile-engineer
**Review checkpoint**: No
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_uk.arb`
**Depends on**: None
**Blocks**: 006, 007, 008, 009
**Context docs**: None

## Description

Add the new user-facing strings the redesigned Today screen needs — the countdown card, the all-done state, the group state badges, the group dose-count sub-label, and the Mark-all button — to all three locales, with `@`-descriptions in `app_en.arb`. Reuse (do NOT duplicate) the existing keys `medsListTypeContinuous`, `medsListTypeCourseDay`, `medsListStock`, `todayStatusTaken/Skipped/Missed`, `todayUndo`, `todaySkip`, `todayMarkTaken`, `todayActionError`. Regenerate `AppLocalizations`.

## Change details

- In `lib/l10n/app_en.arb` (add keys + `@`-descriptions):
  - `todayNextIntakeLabel`: `"Next intake"`
  - `todayNextIntakeIn`: `"in {hours}h {minutes}m"` — placeholders `hours` (int), `minutes` (int)
  - `todayNextIntakeInMinutes`: `"in {minutes}m"` — placeholder `minutes` (int) (sub-hour target)
  - `todayAllDone`: `"All done for today"`
  - `todayGroupBadgeNow`: `"Now"`
  - `todayGroupBadgeFuture`: `"Future"`
  - `todayGroupTakenCount`: `"{taken}/{total}"` — placeholders `taken` (int), `total` (int) (the widget prepends the ✓ icon)
  - `todayGroupDoseCount`: `"{count, plural, =1{1 dose} other{{count} doses}}"` — placeholder `count` (int)
  - `todayMarkAllInGroup`: `"Mark all"`
- In `lib/l10n/app_de.arb` and `lib/l10n/app_uk.arb`: add the same keys with locale-appropriate translations (uk: use the existing translation style; keep the `{count, plural, ...}` ICU form with correct `one/few/many/other` categories for Ukrainian).
- Regenerate: run `flutter gen-l10n` (or the project's `flutter pub get`/build step) so `AppLocalizations` exposes the new getters/methods.

## Contracts

### Expects
- `lib/l10n/app_en.arb` defines `todayStatusTaken`, `todayStatusMissed`, `medsListTypeCourseDay`, `medsListStock`.
- The project's l10n pipeline generates `AppLocalizations` from the three ARB files (existing `todayTitle` etc. are already generated).

### Produces
- `app_en.arb`, `app_de.arb`, `app_uk.arb` each define `todayNextIntakeLabel`, `todayNextIntakeIn`, `todayNextIntakeInMinutes`, `todayAllDone`, `todayGroupBadgeNow`, `todayGroupBadgeFuture`, `todayGroupTakenCount`, `todayGroupDoseCount`, `todayMarkAllInGroup`.
- Generated `AppLocalizations` exposes `todayNextIntakeLabel`, `todayAllDone`, `todayGroupBadgeNow`, `todayGroupBadgeFuture`, `todayMarkAllInGroup` (getters) and `todayNextIntakeIn(int, int)`, `todayNextIntakeInMinutes(int)`, `todayGroupTakenCount(int, int)`, `todayGroupDoseCount(int)` (methods).

## Done when
- [x] All 9 new keys exist in en/de/uk with matching placeholders; en carries `@`-descriptions.
- [x] The Ukrainian `todayGroupDoseCount` uses correct ICU plural categories.
- [x] `AppLocalizations` regenerates cleanly (no gen-l10n errors).
- [x] `dart analyze` passes on changed/generated files.

**Spec criteria addressed**: AC-4, AC-2, AC-10, AC-16

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-05
**Files changed**: `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (+ regenerated `app_localizations.dart`, `_en.dart`, `_de.dart`, `_uk.dart`)
**Contract**: Expects [2/2 verified] | Produces [2/2 verified — 9 keys ×3 locales; generated getters/methods present]
**Notes**: 9 keys appended after `todayActionError` in en (with `@`-descriptions + placeholder metadata); de/uk key-only. uk `todayGroupDoseCount` uses full `one/few/many/other` ICU categories. `flutter gen-l10n` clean; `dart analyze` clean.
