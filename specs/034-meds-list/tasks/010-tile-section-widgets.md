# Task 010: Medication tile + section widgets

**Agent**: mobile-engineer
**Files**: `lib/features/meds/presentation/widgets/medication_tile.dart` (new), `lib/features/meds/presentation/widgets/medication_section.dart` (new)
**Depends on**: 006, 007, 008, 009
**Blocks**: 011
**Context docs**: `specs/034-meds-list/spec.md` (§3.3 tile anatomy)
**Review checkpoint**: Yes

**Description**:
Build the dumb display widgets per the `#s-meds` design. `MedicationTile` renders one `MedListItem`; `MedicationSection` renders a localized header + a list of tiles (or an inline empty placeholder). Pure-display, theme-driven (Material 3 tokens, no hardcoded colors except the stock error color which comes from `colorScheme.error`). Not tappable.

**Change details**:
- `medication_tile.dart` — `MedicationTile({required MedListItem item})`:
  - leading icon: `medicationFormIcon(item.medication.form)`, tinted `colorScheme.primary` when `item.medication.type is ContinuousType` else `colorScheme.tertiary`.
  - title: `item.medication.name`.
  - subtitle: join non-null `[formatDose(dosePerIntake, l10n), formatTimes(schedule.slots), formatStock(stock, l10n)]` with ` · `; the stock segment styled `colorScheme.error` when `isLowStock(stock)`.
  - chips: status chip — `medsListStatusActive` (positive tone) when `activity == active`, else `medsListStatusCompleted` (neutral); type chip — `medsListTypeContinuous` for continuous; for courses, `medsListTypeCourseDay(progress.currentDay, progress.totalDays)` when `progress.phase == activeWindow`, else `medsListTypeCoursePaused`.
  - trailing: a chevron icon, **non-interactive** (no `onTap`/`InkWell`).
  - Give the tile a stable `Key` (e.g. `ValueKey('medTile-${item.medication.id.value}')`) for tests.
- `medication_section.dart` — `MedicationSection({required String title, required List<MedListItem> items})`: localized header; if `items` empty render the `medsListSectionEmpty` placeholder; else a `Column`/`ListView.builder` of `MedicationTile` separated by dividers (per design). Use `ListView.builder` only if nested-scroll-safe; otherwise a `Column` (the screen owns the scroll).

**Done when**:
- [x] Tile renders icon (correct variant tint), name, joined subtitle (low-stock in error color), status + type chips, non-interactive chevron.
- [x] Section renders header + tiles, or the inline empty placeholder when `items` is empty.
- [x] No hardcoded colors (theme tokens only); `dart analyze` clean.

**Spec criteria addressed**: AC-8, AC-9, AC-12, AC-13

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: medication_tile.dart (new), medication_section.dart (new)
**Contract**: Expects 4/4 verified | Produces 2/2 verified
**Notes**: Low-stock stock segment via `Text.rich` `cs.error`; `progress` guarded with `if (x != null)` (no `!`); non-interactive (no onTap/InkWell); `ValueKey('medTile-<id>')`. **Code-reviewer (convergence checkpoint): APPROVE WITH WARNINGS** → fixed all 3: `_StatusChip`/`_TypeChip` now exhaustive `switch` expressions (was if/else, §4.1.1); text-style fallbacks made type-safe. Reviewer's Fix-3 premise (TextTheme non-nullable) was WRONG for this SDK (3.41.4 → `TextStyle?`); repair verified via `dart analyze` and kept `?.copyWith(...) ?? TextStyle(...)`. analyze clean, 0 `default:`.

## Contracts

### Expects
- Task 006 (`medsListStatus*`, `medsListType*`, `medsListSectionEmpty` getters), Task 007 (`medicationFormIcon`), Task 008 (`formatDose`/`formatTimes`/`formatStock`/`isLowStock`), Task 009 (`MedListItem`, `CoursePhase`).

### Produces
- `medication_tile.dart` exports `class MedicationTile` taking a `MedListItem`, with a `ValueKey('medTile-...')` and a non-interactive trailing chevron.
- `medication_section.dart` exports `class MedicationSection` taking `title` + `List<MedListItem>`, rendering the empty placeholder when the list is empty.
