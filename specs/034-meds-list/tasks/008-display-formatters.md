# Task 008: Display formatters (dose / times / stock)

**Agent**: mobile-engineer
**Files**: `lib/features/meds/presentation/widgets/medication_display.dart` (new), `test/features/meds/presentation/widgets/medication_display_test.dart` (new)
**Depends on**: 006
**Blocks**: 010
**Context docs**: `specs/034-meds-list/data-model.md`
**Review checkpoint**: No

**Description**:
Create the pure presentation-layer formatters that build the tile subtitle segments from domain values + localized strings. Kept out of `domain/` (they touch l10n / `TimeOfDay` formatting). Each returns a ready string (or `null` when the segment is absent), so the tile just joins non-null segments with ` · `.

**Change details**:
- `medication_display.dart` (functions take an `AppLocalizations`/`BuildContext` for localized units):
  - `String? formatDose(Dosage? dose, AppLocalizations l10n)` → `"20 mg"`-style: amount with no trailing `.0` (`20`, not `20.0`; keep meaningful decimals) + `doseUnit*` abbreviation; `null` when `dose == null`.
  - `String formatTimes(List<TimeSlot> slots)` → slots sorted by `minuteOfDay`, each rendered `HH:mm` (zero-padded, 24h, local), comma-joined.
  - `String? formatStock(PackStock? stock, AppLocalizations l10n)` → `medsListStock(remaining, total)`; `null` when `stock == null`.
  - `bool isLowStock(PackStock? stock)` → `stock != null && stock.remaining <= stock.warnAt` (drives the error-color styling in the tile).
  - a `doseUnitAbbrev(DoseUnit unit, AppLocalizations l10n)` helper with an exhaustive switch mapping each `DoseUnit` to its `doseUnit*` getter.
- `medication_display_test.dart`: amount trailing-`.0` trimming; multi-slot sort + `HH:mm` padding (e.g. `8` → `08:00`); stock string; `isLowStock` boundary (`remaining == warnAt` is low); null dose/stock → null segment.

**Done when**:
- [x] All formatter functions exist with exhaustive unit switch; no `!`.
- [x] Unit tests cover trailing-zero trimming, time sort/pad, low-stock boundary, null segments — green.
- [x] `dart analyze` clean.

**Spec criteria addressed**: AC-8

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: medication_display.dart (new), medication_display_test.dart (new, 26 tests)
**Contract**: Expects 1/1 verified | Produces 1/1 verified
**Notes**: Pure formatters; exhaustive `DoseUnit` switch; immutable sort copy in `formatTimes`; trailing-`.0` trim via `amount == amount.roundToDouble()`. Tests load `AppLocalizations` synchronously via `AppLocalizations.delegate.load(const Locale('en'))` (no widget pump). 26/26 green; analyze clean.

## Contracts

### Expects
- Task 006 `Produces` (`doseUnit*`, `medsListStock` getters on `AppLocalizations`).
- `Dosage` (`amount`, `unit`), `DoseUnit`, `PackStock` (`remaining`, `total`, `warnAt`), `TimeSlot` (`minuteOfDay`) exist in domain.

### Produces
- `medication_display.dart` exports `formatDose`, `formatTimes`, `formatStock`, `isLowStock`, `doseUnitAbbrev`.
