# Tasks: Add-Medication Form-Dependent Fields (visual-only, iteration 3)

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-06-14
**Total tasks**: 3
**Status**: VERIFIED COMPLETE (2026-06-14) — 16/16 AC PASS · 305 tests · analyze clean · apk built · Security PASS (0 Crit) · Perf 0 High/1 Med · Tests GAPS-FOUND (AC-5/6/7 partial, non-blocking). Verdict APPROVED. Ready for `/summarize` → `/finalize`.

## Dependency Graph

```
001 (l10n keys) ──→ 002 (conditional fields) ──→ 003 (tests)
```

Strictly sequential. The widgets in 002 read `context.l10n.medsAddDose*/Quantity*/Stock*/Unit*`, which do not exist until 001 regenerates the bindings. The tests in 003 drive the fields mounted by 002 (locating them by the `ValueKey`s 002 produces).

## Task Index

| # | Title | Agent | Depends on | Review checkpoint | Status |
|---|-------|-------|-----------|-------------------|--------|
| 001 | Add the 14 form-field l10n keys | mobile-engineer | None | No | Complete |
| 002 | Hoist form selection and add the conditional fields | mobile-engineer | 001 | Yes | Complete |
| 003 | Widget tests for the form-dependent fields | qa-engineer | 002 | No | Complete |

## Additions to Spec

None. The task File Impact exactly matches the spec's Affected Areas (modal widget, 3 ARB files + regenerated bindings, modal test). No new files; no `domain/`/`data/`/`pubspec.yaml` changes. The three new widgets (`_DoseField`/`_QuantityStepper`/`_StockCard`) live **inside** the existing modal library.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Mechanical, additive ARB extension (3-locale pattern, MEMORY F006); nothing consumes the keys yet so the project stays green. Watch: actually run `flutter gen-l10n`; a missing locale key surfaces as an untranslated-message warning. |
| 002 | Med | Substantial change touching the spec-027 picker (callback hoist) + 3 new widgets + controller lifecycle. Correctness points: preserve the picker's observable behaviour so 027 tests stay green; conditional fields **absent** until a form is selected (keeps the spec-026 single-`TextField` test valid); `minus`/`plus` + stock/warning Lucide names (Material fallback per spec §7); controllers disposed; `InputDecorator` floating label for the stepper; reset-on-switch; no `!`/Riverpod/domain/data. Impact stays Low (isolated, presentation-only, no persistence). |
| 003 | Low–Med | Post-selection `find.byType(TextField)` ambiguity — use keyed/icon/text finders (Task 002 emits the `ValueKey`s); off-stage finder gotcha (MEMORY Bug 020) — drive state changes with `pump()` before asserting; keep all spec-011/026/027 tests green. |

## Review Checkpoints

| Before completing Task | Reason | What to Review |
|------------------------|--------|----------------|
| 002 | Higher risk + substantive change touching the existing picker; user values HTML-design fidelity | Picker hoist preserves spec-027 behaviour (tap chevron → expand; tap option → select+collapse+display update); per-form matrix matches the HTML `FORM_FIELDS` (tablet/capsule → qty+stock; injection/syrup/drops → dose+units; inhaler/cream/sachet → none); stepper min/step/format (0.5/0.5, 1/1; minus clamps; no trailing `.0`); fields absent before selection; reset-on-switch; controllers disposed; all colors theme-driven; strings via `context.l10n`; no `!`/Riverpod/domain/data; Save still a no-op. |

## Contract Chain Integrity

- **001 Produces** the 14 `medsAdd{Dose,Quantity,Stock,Unit}*` getters in `app_localizations.dart` → **consumed by 002 Expects** (and **003 Expects** for EN strings). ✅
- **001 Produces** the 14 ARB keys + en-only `@`-metadata → map directly to **AC-9 / AC-10**. ✅
- **002 Expects** the 14 getters + the spec-027 picker/`_MedFormOption`/`_medFormOptions` → satisfied by **001 Produces** + existing codebase (spec 027). ✅
- **002 Produces** the `onFormSelected` callback, the extended `_MedFormOption` config, `_DoseField`/`_QuantityStepper`/`_StockCard`, parent state + disposed controllers, gated insertion, and the 8 test-target `ValueKey`s; no `!`/Riverpod/domain/data → **consumed by 003 Expects** and map to **AC-1…AC-8, AC-10, AC-11, AC-15**. ✅
- **003 Expects** the mounted fields + `ValueKey`s + 14 EN getters → satisfied by **002 / 001 Produces**. ✅
- **003 Produces** the form-dependent-fields test group + preserved existing groups → map to **AC-12 / AC-13 / AC-14**. ✅
- No orphaned Produces, no unsatisfied Expects.

## Acceptance-Criteria Coverage

| AC | Task(s) |
|----|---------|
| AC-1 (hoist + preserve picker behaviour) | 002 |
| AC-2 (no conditional fields before selection; single `TextField`) | 002 (impl) · 003 (test) |
| AC-3 (placement/order dose→qty→stock between picker and Save) | 002 · 003 |
| AC-4 (tablet/capsule qty+stock; min/step/format/clamp) | 002 · 003 |
| AC-5 (injection/syrup/drops dose + unit lists) | 002 · 003 |
| AC-6 (inhaler/cream/sachet → none) | 002 · 003 |
| AC-7 (reset on form change) | 002 · 003 |
| AC-8 (local state, no persistence, Save no-op, no domain/data) | 002 |
| AC-9 (14 keys in 3 ARBs) | 001 |
| AC-10 (`@`-meta en-only) | 001 |
| AC-11 (`context.l10n`, no `!`, theme colors, controllers disposed, `dart analyze`) | 001 · 002 · 003 |
| AC-12 (new conditional-field tests a–f) | 003 |
| AC-13 (existing 011/026/027 tests preserved) | 003 (and 002 preserves the picker contract) |
| AC-14 (`flutter test`) | 003 |
| AC-15 (`flutter build apk --debug`) | 002 |
| AC-16 (manual theme/locale) | /verify (code-read) |

All 16 ACs covered.
