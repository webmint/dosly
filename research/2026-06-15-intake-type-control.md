# Research: Add-Medication Intake-Type Control (Continuous vs. Course)

**Date**: 2026-06-15
**Topic**: Add the HTML template's "Тип прийому" (intake-type: all-time vs. by-course) control to the Add-medication modal
**Verdict**: Feasible — a clean continuation of the established visual-only iteration pattern (specs 026→029)

## Summary

The HTML template's "Тип прийому" control is a **two-option segmented button** — **Постійний** (Continuous/ongoing) vs. **Курс** (Course) — that, when *Course* is selected, reveals a **course-parameters card** (duration in days, pause in days, start date via a date picker, and a computed date-range info chip). This maps directly onto the incremental "visual-only iteration" approach the Add-medication modal has been built with: specs 026 (name) → 027 (form picker) → 028 (form-dependent fields) → 029 (intake-time chips). This would be **iteration 5**. Everything needed already exists in the project — `SegmentedButton` is already used in `theme_selector.dart`, `showDatePicker` is the date analog of spec 029's `showTimePicker`, and the course card mirrors the existing `_StockCard` container pattern. No domain/data code, no persistence — Save stays a no-op. Highly feasible.

## What the HTML control actually is

From `dosly_m3_template.html` (control at **lines 2188–2230**, CSS at **923–943** + **966–1010**, JS `selectType()` at **2897–2903**):

```
Тип прийому  (section title)
┌─────────────────────────────────────┐
│  [🌙 Постійний] │ [🔁 Курс ✓]        │   ← .seg-btn / .seg-opt (segmented button)
└─────────────────────────────────────┘
   (when "Курс" selected → reveal:)
┌─────────────────────────────────────┐
│ 🔁 Параметри курсу                   │   ← .course-card (surface-low container)
│ ┌──────────────┐ ┌──────────────┐    │
│ │Тривалість(дні)│ │ Пауза (дні)  │    │   ← duration + pause, side by side (.f-row)
│ │      7        │ │      0       │    │
│ └──────────────┘ └──────────────┘    │
│ ┌─────────────────────────────────┐  │
│ │ Дата початку      📅            │  │   ← start-date field → showDatePicker
│ │ 26 берез. 2026                  │  │
│ └─────────────────────────────────┘  │
│ ⓘ Курс: 26 бер — 1 квіт 2026 (7 днів)│   ← .info-chip (tertiary-container)
└─────────────────────────────────────┘
```

Behavior (from JS):
- `selectType('perm')` → highlight "Постійний", **hide** course-card.
- `selectType('course')` → highlight "Курс", **show** course-card.
- The info chip text is **computed**: `start date` + `duration` → end date, e.g. `Курс: 26 бер — 1 квіт 2026 (7 днів)`.
- In the HTML, the section sits **after the intake-time chips and before the Save button** — the same slot it should occupy in the Flutter modal.

## Codebase Findings

### Existing Related Code
| Area | Files | Relevance |
|------|-------|-----------|
| The target modal | `lib/features/meds/presentation/widgets/add_medication_modal.dart` (1118 lines) | Add the new section here, after `_TimeChips`, before the Save `FilledButton.icon` |
| SegmentedButton precedent | `lib/features/settings/presentation/widgets/theme_selector.dart:75` | Project already uses `SegmentedButton<T>` — direct pattern to mirror for Постійний/Курс |
| Container-card precedent | `_StockCard` in the modal (lines 580–670) | The course-parameters card is structurally identical (titled container with fields) — copy its shape |
| Date-picker precedent | `_pickTime` / `showTimePicker` (lines 924–933, spec 029) | `showDatePicker` is the built-in date analog; same "wrap, await, mounted-guard, commit" idiom |
| Localization | `lib/l10n/app_{en,uk,de}.arb` (74 `medsAdd*` keys) | New `medsAdd*` keys go in **all three** arb files |
| Iteration template | `specs/029-intake-time-chips/spec.md` | Exact precedent for a "visual-only" modal section spec |

### Patterns Available
- **Private widget in the same library** (`_IntakeTypeSelector`, `_CourseCard`) driven by parent local state + `onChanged` callbacks — same as `_MedicationFormPicker`, `_DoseField`, etc.
- **Conditional rendering** gated on state (`if (_intakeType == IntakeType.course) ...[ _CourseCard(...) ]`) — exactly how `_DoseField`/`_QuantityStepper`/`_StockCard` are gated on `_selectedForm`.
- **Outlined floating-label frame** via `InputDecorator(isEmpty: false, ...)` / `TextField` — reuse for the duration/pause/start-date inputs.
- `showDatePicker` with a `mounted` guard after `await` — mirror `_addTime`/`_editTime`.

### Gaps
- **None blocking.** One minor new piece: the computed info-chip ("Курс: … (N днів)") needs simple date math (start + duration → end). The constitution puts date helpers in `lib/core/utils/`, but for a visual-only iteration a local private helper is acceptable (matches how spec 029 kept `_formatQuantity` local).

## Constitution Constraints

| Rule | Impact on This Idea |
|------|---------------------|
| Visual-only iteration convention (specs 026–029) | Save stays a no-op; new state is **local only** (`_intakeType`, duration/pause controllers, `_startDate`). No `domain/`/`data/` code. |
| §2.1 layer boundaries | Pure presentation change — no boundary risk. |
| Strict lint (no `!`, no `dynamic`, typed) | Use an enum (e.g. `_IntakeType { continuous, course }`) for the segmented value; null-safe date handling. |
| L10n in all 3 arbs | Every new label (section title, "Continuous", "Course", "Duration (days)", "Pause (days)", "Start date", info-chip template) → en + uk + de. |
| Icons/colors/typography from theme | `LucideIcons.*`, `Theme.of(context)` — no hardcoded values (info-chip uses `tertiaryContainer`/`onTertiaryContainer`). |
| Date math → `core/utils` | The end-date computation *may* warrant a tiny `core/utils` helper; decide during `/specify`. |

## Approaches

### Option A: Full visual-only iteration (segmented control + course-parameters card) — Recommended
- **Description**: Add `_IntakeTypeSelector` (`SegmentedButton`, Continuous/Course) + conditionally-rendered `_CourseCard` (duration, pause, start-date picker, computed info chip), all local state, Save unchanged.
- **Pros**: Faithful to the HTML design; consistent with the 026–029 iteration cadence; everything reuses existing patterns; low risk.
- **Cons**: Slightly larger than prior iterations (adds a date picker + a small date computation).
- **Complexity**: Low–Medium

### Option B: Segmented toggle only (defer the course card)
- **Description**: Ship just the Постійний/Курс `SegmentedButton`; leave course parameters for a later iteration.
- **Pros**: Smallest possible step.
- **Cons**: Low design fidelity — the toggle does nothing visible without the card it reveals; likely needs an immediate follow-up.
- **Complexity**: Low

### Option C: Build with real persistence now
- **Description**: Introduce `IntakeType` domain entity + course schedule fields and wire Save.
- **Pros**: Real functionality.
- **Cons**: Breaks the deliberate visual-first sequencing; pulls in domain/data/drift schema decisions that the modal has intentionally deferred; much larger scope.
- **Complexity**: High

**Recommended approach**: **Option A** — it matches the established iteration-5 shape, keeps the diff in one presentation file + 3 arb files, and fully reproduces the design.

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | Low | One widget file (`add_medication_modal.dart`) + 3 arb files; possibly one tiny `core/utils` date helper |
| New dependencies | None | `SegmentedButton` and `showDatePicker` are built-in Flutter |
| Risk | Low | Visual-only, local state, no persistence/layer changes |

## Recommendation

**Proceed.** This is a natural iteration 5 of the Add-medication form. Run:

```
/specify "Add an intake-type control to the Add-medication modal (visual-only, iteration 5): a SegmentedButton for Постійний (Continuous) vs Курс (Course), placed after the intake-time chips and before Save. Selecting Course reveals a course-parameters card with Duration (days), Pause (days), a Start date field using showDatePicker, and a computed date-range info chip. Local state only; Save stays a no-op; new l10n keys in en/uk/de."
```

`/specify` will pin down the open questions (enum naming, whether the date-range helper lives in `core/utils`, exact l10n strings, and date-format/locale handling for the info chip).
