# Review Report: 028-form-dependent-fields

**Date**: 2026-06-14
**Spec**: specs/028-form-dependent-fields/spec.md
**Changed files**: 4 source/test (`lib/features/meds/presentation/widgets/add_medication_modal.dart`, `lib/l10n/app_{en,de,uk}.arb`, `test/features/meds/presentation/widgets/add_medication_modal_test.dart`) + 4 regenerated `app_localizations*.dart`

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 5
- **Overall: PASS**

Visual-only iteration: all new values (dose, dose-unit index, quantity, stock remaining/total/warn) are local widget state — never persisted, validated, logged, or transmitted. Save is a confirmed no-op (`add_medication_modal.dart` `onPressed: () {}`). N/A checklist items (auth, network/HTTPS/cert-pinning, remote storage, deps, platform config, deep links/webview/URL schemes) were skipped — none introduced.

- **Info** — `add_medication_modal.dart`: No `print`/`debugPrint`/`developer.log`, no `SharedPreferences`/`secure_storage`/drift/file writes, no `jsonEncode/Decode` (keyword scan: zero matches). Satisfies the constitution privacy-first rules (never log PHI; never use SharedPreferences for medication data). No constitution violation.
- **Info** — Controllers disposed in `dispose()` and cleared in `_resetConditionalFields` — transient input doesn't leak across form switches or outlive the modal. Good hygiene.
- **Info** — Input validation is intentionally absent (raw `TextField`s with only `keyboardType`). Acceptable now (no value crosses a trust boundary). **Forward obligation**: when the data-save iteration wires these to drift/domain, add boundary validation per constitution "validate external input at boundaries". Not a current defect.
- **Info** — No hardcoded secrets/tokens/keys. ARB additions are static UI labels (no placeholders/interpolation → no format-string/injection surface).
- **Info** — No unsafe patterns: no `dart:mirrors`, `Process.run`, path concatenation, or unsafe deserialization. Dropdown keyed by integer index (avoids string-driven lookups).

## Performance Review

- High: 0 | Medium: 1 | Low: 4

Clean for a small static modal (~15 widgets deep). A full `_AddMedicationModalState` rebuild on form-select / stepper-tap / unit-change costs ~0.1–0.3 ms — comfortably within the 16 ms frame budget. No jank risk. Controller lifecycle matches the plan (5 permanent `final` controllers, disposed once, cleared on switch — no per-switch allocation). `const` coverage is correct (no missing sites the `prefer_const_constructors` lint hasn't already enforced).

- **Medium** — `add_medication_modal.dart` `_DoseField.build`: rebuilds a fresh `List<DropdownMenuItem<int>>` (+ closure calls + `Text`s) on every parent `setState`, including stepper taps, while a liquid form is selected (max 3 items). Recommendation: pre-build the items list in `_AddMedicationModalState._onFormSelected` (only changes when `_selectedForm` changes) and pass the prebuilt list. Defer to the data-save iteration.
- **Low** — `onUnitChanged` anonymous closure allocated every `build` (lines ~888–892). Recommendation: extract to a named method `_onDoseUnitChanged` (tear-off, cached per receiver).
- **Low** — `selectedForm?.quantityUnit?.call(context.l10n)` invoked every stepper tap (line ~902); value is constant per form. Recommendation: resolve once in `_onFormSelected`, store in a `String` state field.
- **Low** — `TextStyle.copyWith(...)` in `_QuantityStepper`/`_StockCard` builds (lines ~563, ~635) allocates a `TextStyle` per build. Cosmetic; assign to a local to make explicit.
- **Low/Info** — `const` audit: coverage is correct; no actionable missing `const` sites.

All findings below the threshold for unsolicited edits on a visual-only iteration; M1/L1/L2 worth fixing in the data-save iteration when the build path becomes load-bearing.

## Test Assessment

- AC items with test coverage: **8 of 16 fully covered**; 5 partial; AC-15/16 out of widget-test scope.
- **Verdict: GAPS FOUND** (all gaps are test-thoroughness, not defects — full suite is 305/305 passing; this is a visual-only iteration with no persistence to integration-test)

Fully covered: AC-1 (picker behaviour preserved via spec-027 tests), AC-2 (no fields pre-selection + single TextField), AC-8 (Save no-op), AC-12 (new tests exist), AC-13 (existing tests preserved), AC-14 (suite passes), AC-11 (no-`!`/analyze via static guard).

Gaps by priority:
- **High — AC-5 (Injection & Drops untested)**: the new group only tests Syrup's single `ml` unit. No test selects Injection (3-unit list ml/mg/IU) or Drops (2-unit list drops/ml) to assert the dose field appears with the correct unit list. The new `medsAddUnitUnits` value (IU/IE/МО) is asserted nowhere.
- **High — AC-5 (unit dropdown interaction)**: `onUnitChanged` → `setState` → `_selectedDoseUnitIndex` path has zero coverage; no test changes the selected unit.
- **Medium — AC-4 (Capsule stock card)**: test (c) exercises the Capsule stepper but never asserts the Capsule stock card is present; a dropped `hasStock: true` on capsule would go undetected.
- **Medium — AC-7 (controller text clearing + unit-index reset)**: reset test (f) covers field visibility only; no test types into dose/stock fields, switches form, and verifies they cleared; no test verifies the unit dropdown returns to index 0 after switching a multi-unit form.
- **Medium — AC-6 (Cream & Sachet)**: only Inhaler represents the no-field group; Cream/Sachet untested individually.
- **Low — AC-3 (placement/order)**: no assertion of dose→qty→stock ordering between picker and Save.
- **Low — AC-9/10 (de/uk runtime)**: no test renders the new conditional-field labels under `de`/`uk` (build-time l10n gen is the safety net; existing locale group only checks the AppBar title).
- **Low — W1/W2 (bare-string stock assertions)**: test (b) asserts stock labels via `find.text('Remaining')` etc. instead of the `medsAddStockRemaining`/`Total`/`Warn` keys — currently correct but couples to the en locale and would survive a key deletion. (Code-review carryover.)
