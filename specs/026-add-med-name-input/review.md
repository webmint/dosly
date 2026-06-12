# Review Report: 026-add-med-name-input

**Date**: 2026-06-12
**Spec**: specs/026-add-med-name-input/spec.md
**Changed files**: 3 source/test + 4 regenerated l10n bindings (review scope; `.claude/**` and `specs/**` excluded)

Reviewed source/test:
- `lib/features/meds/presentation/widgets/add_medication_modal.dart`
- `test/features/meds/presentation/widgets/add_medication_modal_test.dart`
- `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (+ regenerated `app_localizations*.dart`)

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 4 — **Overall: PASS**

No exploitable vulnerabilities, no PHI-leak path, no insecure pattern, no constitution violation introduced.

- **Info** — `add_medication_modal.dart:39/76`: `_nameController` text is captured but has **no consumer** — `onPressed: () {}` reads nothing, there is no `print`/`debugPrint`/`logger` reference in the file, and the launch site (`meds_screen.dart:65`) constructs `const AddMedicationModal()` with no arguments. The entered med name never leaves the widget → satisfies the PHI no-logging rule. No action.
- **Info** — The two new l10n values (`medsAddNameLabel`, `medsAddSaveButton`) are static UI labels with no placeholders/PHI interpolation. Safe.
- **Info** — Controller correctly disposed (`dispose()` at :42–45) → no retention path for the transient PHI string.
- **Info (forward-looking, out of scope)** — When the data-save iteration wires persistence, ensure the save path (a) never passes the med name into a `logger`/`print`, (b) keeps it out of notification text, (c) routes storage through the local `drift` DB only (no network/telemetry). Current code introduces no obstacle to that.

## Performance Review

- High: 0 | Medium: 0 | Low: 1 (informational — no action)

- **Low (informational)** — `add_medication_modal.dart:66–69`: `InputDecoration(labelText: context.l10n.medsAddNameLabel, ...)` cannot be `const` (runtime-localized value), so it is reallocated each `build()`. For a tiny modal that rebuilds only on keyboard show/hide, allocation frequency is negligible. Expected language constraint, not a defect.
- `const`-correctness otherwise: **Pass** — every widget that can be `const` is (`SizedBox(height:16)`, both `Icon`s, `EdgeInsets.all(16)`, `OutlineInputBorder()`). Controller created once as a field, disposed in `dispose()` — correct lifecycle. `SingleChildScrollView` is the appropriate keyboard-safe choice. No 60fps/app-size concern.

## Test Assessment

- AC items with at least one direct test assertion: **5 of 10** testable ACs (AC-4 full; AC-2, AC-3, AC-5, AC-6 partial)
- Verdict: **GAPS FOUND**

**Material gaps:**
- **AC-1 (controller disposal) — untested.** No test pumps then tears down the modal to verify `_nameController.dispose()` runs. A removed `dispose()` / missing `super.dispose()` would silently pass all current tests. Priority: medium (memory-safety). Suggested: pump the modal, then `pumpWidget(const SizedBox())` and assert no disposed-controller `FlutterError`.
- **AC-5 (no-op proof) — weak.** The "tapping Save doesn't pop the modal" test only proves the widget is still in the tree. The harness has no Navigator route below the modal, so a `pop()` would silently no-op anyway → not a rigorous navigation proof. It also doesn't assert `onPressed != null` (enabled). Acceptable as a documented tradeoff for a literal `onPressed: () {}`, but not rigorous. Suggested: `expect(button.onPressed, isNotNull)` and/or a Navigator-with-route-below harness.
- **AC-6 (DE/UK values) — untested.** `medsAddNameLabel`/`medsAddSaveButton` asserted only under EN; DE ("Medikamentenname"/"Speichern") and UK ("Назва ліків"/"Зберегти") verified by code-read only. A copy-paste ARB error would go undetected. The file already has a DE/UK title-test pattern to extend. Priority: low for a visual iteration.

**Lower-priority gaps:**
- **AC-3** — `OutlineInputBorder` not asserted (test reads `labelText` but not `decoration?.border`). One-line `isA<OutlineInputBorder>()` check would close it.
- **AC-2** — no exact `findsOneWidget` count assertions for `TextField` / `FilledButton`.

**Out-of-scope by spec design (do NOT add tests):** reading the field value on Save, validation, `Navigator.pop` after Save, SnackBar/feedback — all deferred to later iterations.

**Static/CI-gated ACs (not unit-testable here):** AC-7 (`@`-metadata en-only), AC-8 (`context.l10n`, no `!`), AC-9 (`dart analyze`), AC-11/12 (`flutter test` / build), AC-13 (manual theme/locale).
