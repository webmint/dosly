## Feature Summary: 028 — Add-Medication Form-Dependent Fields

### What was built
Iteration 3 of the add-medication form: the input fields shown now depend on the selected medication form. Picking **tablet/capsule** reveals a quantity-per-intake stepper and a pack-stock card; **injection/syrup/drops** reveal a dose field with a form-specific unit dropdown; **inhaler/cream/sachet** show no extra fields. Visual-only — the Save button remains a no-op and nothing is persisted (deferred to a later data-save iteration).

### Changes
- **Task 1**: Add the 14 form-field l10n keys — dose/quantity/stock labels + 6 unit abbreviations across en/de/uk (`@`-meta en-only).
- **Task 2**: Hoist form selection + conditional fields — picker selection lifted to the modal via a `ValueChanged<_MedFormOption>` callback; added `_DoseField`, `_QuantityStepper`, `_StockCard` gated by per-form config on `_MedFormOption`; reset-on-form-change; 4 new controllers disposed.
- **Task 3**: Widget tests — new `form-dependent fields` group (6 tests a–f) covering the visibility matrix, stepper math + clamp, and reset-on-switch.
- **Post-task**: unit "units" resolved to International Units (en `IU` / de `IE` / uk `МО`).

### Files changed
- `lib/features/meds/presentation/widgets/` — 1 file modified (modal: hoist + 3 widgets + config/state, +542)
- `lib/l10n/` — 3 ARBs modified + 4 generated bindings regenerated (14 new keys)
- `test/features/meds/presentation/widgets/` — 1 file modified (+255, 6 new tests)

[Total: 9 files changed, 1073 insertions, 21 deletions]

### Key decisions
- **Hoist via callback, not full state-lift** — picker keeps its own selection state; preserved the spec-027 picker tests unchanged.
- **Per-form config on `_MedFormOption`** (hasDose/hasQuantity/hasStock/doseUnits/qty step+min+unit) — single source of truth, no `switch` over a String key.
- **Controllers as permanent State fields, cleared (not recreated) on form change** — eliminates use-after-dispose/leak risk.
- **Conditional fields gated on `_selectedForm?.hasX ?? false`** — absent before selection, preserving the spec-026 single-`TextField` test.
- **Units localized** — all unit abbreviations are ARB keys; injection "units" = International Units (IU/IE/МО) per user choice.

### Acceptance criteria
- [x] AC-1: Selected form hoisted to the modal; picker behaviour preserved
- [x] AC-2: No conditional fields before selection (single name TextField)
- [x] AC-3: Fields render dose→qty→stock between picker and Save
- [x] AC-4: Tablet/capsule → stepper (min/step/format/clamp) + stock card
- [x] AC-5: Injection/syrup/drops → dose field + form-specific unit dropdown
- [x] AC-6: Inhaler/cream/sachet → no conditional fields
- [x] AC-7: Switching form resets the conditional block to defaults
- [x] AC-8: Local state only; no persistence; Save no-op; no domain/data
- [x] AC-9: 14 l10n keys in all 3 locales
- [x] AC-10: `@`-description metadata en-only
- [x] AC-11: `context.l10n` everywhere; no `!`; theme colors; controllers disposed
- [x] AC-12: New conditional-field tests (a–f) added
- [x] AC-13: Existing 011/026/027 tests preserved
- [x] AC-14: `flutter test` passes (305 tests)
- [x] AC-15: `flutter build apk --debug` succeeds
- [x] AC-16: Theme/locale correctness (code-read; runtime manual deferred)

### Notes
- Verify verdict: **APPROVED** (16/16 AC, security PASS, perf clean). Non-blocking follow-ups for the data-save iteration: backfill AC-5 Injection/Drops + unit-dropdown tests; perf M1 (pre-build dropdown items); add boundary validation when values are persisted.
