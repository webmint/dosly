# Task 010: Localized Save strings (en/de/uk)

**Agent**: mobile-engineer
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_uk.arb`
**Depends on**: None
**Blocks**: 011
**Context docs**: None
**Review checkpoint**: No

**Description**:
Add the user-facing strings the wired Save flow needs — a success message and one message per validation/error case — to all three locales. Generated `AppLocalizations` is refreshed by `flutter gen-l10n` (runs during build). No hardcoded UI strings allowed (constitution).

**Change details**:
- Add to each ARB (with `@`-metadata descriptions in `app_en.arb`), keys:
  - `medsAddSaveSuccess` — e.g. EN "Medication saved"
  - `medsAddSaveErrorName` — e.g. EN "Enter a medication name"
  - `medsAddSaveErrorTimes` — e.g. EN "Add at least one intake time"
  - `medsAddSaveErrorDuration` — e.g. EN "Course duration must be at least 1 day"
  - `medsAddSaveErrorGeneric` — e.g. EN "Couldn't save medication. Please try again."
- Provide accurate `de` and `uk` translations consistent with existing tone/keys.
- Keep ARB key ordering/style consistent with the existing files.

**Done when**:
- [ ] all five keys exist in `app_en.arb`, `app_de.arb`, `app_uk.arb`
- [ ] `flutter gen-l10n` (or build) regenerates `AppLocalizations` exposing the five getters with no errors
- [ ] `dart analyze` passes

## Contracts
### Expects
- `lib/l10n/app_{en,de,uk}.arb` exist with the medsAdd* key family (current state)
### Produces
- `AppLocalizations` exposes `medsAddSaveSuccess`, `medsAddSaveErrorName`, `medsAddSaveErrorTimes`, `medsAddSaveErrorDuration`, `medsAddSaveErrorGeneric` in all three locales

**Spec criteria addressed**: AC-21

## Completion Notes
**Completed**: 2026-06-17
**Status**: Complete
**Files changed**: app_en.arb, app_de.arb, app_uk.arb (+ regenerated app_localizations*.dart)
**Contract**: Produces 1/1 (5 getters in all 3 locales)
**Notes**: Keys: medsAddSaveSuccess, medsAddSaveErrorName, medsAddSaveErrorTimes, medsAddSaveErrorDuration, medsAddSaveErrorGeneric. de/uk translations match existing medsAdd* tone. gen-l10n clean.
