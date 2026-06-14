# Tasks: Add-Medication Form Picker (visual-only, iteration 2)

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-06-13
**Total tasks**: 3
**Status**: Complete — verified 2026-06-14 (16/16 AC PASS, 299 tests, apk build PASS, review: Security 0 Crit / Perf all-Low / Tests ADEQUATE)

## Dependency Graph

```
001 (l10n keys) ──→ 002 (picker widget) ──→ 003 (picker tests)
```

Strictly sequential. The widget in 002 references `context.l10n.medsAddForm*`, which
do not exist until 001 regenerates the bindings. The tests in 003 drive the picker
mounted by 002.

## Task Index

| # | Title | Agent | Depends on | Review checkpoint | Status |
|---|-------|-------|-----------|-------------------|--------|
| 001 | Add the 19 medication-form l10n keys | mobile-engineer | None | No | Complete |
| 002 | Build the form picker and insert it into AddMedicationModal | mobile-engineer | 001 | Yes | Complete |
| 003 | Widget tests for the form picker | qa-engineer | 002 | No | Complete |

## Additions to Spec

None. The task File Impact exactly matches the spec's Affected Areas (modal widget, 3 ARB files + regenerated bindings, modal test). No new files; no `domain/`/`data/`/`pubspec.yaml` changes.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Mechanical ARB additions following the established 3-locale pattern (MEMORY F006); nothing consumes the keys yet, so the project stays green. Watch-items: actually running `flutter gen-l10n`; 19 keys × 3 locales is a sizeable surface — a missing locale key shows as an untranslated-message warning. |
| 002 | Med | Substantial new widget; user values HTML-design fidelity (spec 011/026 precedent). Correctness points: `cream`/`sachet` Lucide names (Material fallback per spec §7), `InputDecorator` floating-label behavior without a real input (`isEmpty: false`), no `!` when reading the selected option, implicit animations (no `AnimationController` to dispose), conditional-build of the grid for clean collapse. Impact stays Low (isolated, presentation-only, no persistence). |
| 003 | Low–Med | Off-stage finder gotcha (MEMORY Bug 020) — expand before locating options; conditional-build makes collapsed `findsNothing` clean. Must keep all spec-026 tests green and assertions self-validating. |

## Review Checkpoints

| Before completing Task | Reason | What to Review |
|------------------------|--------|----------------|
| 002 | High-ish risk + substantive visual change; user values HTML-design fidelity | Display row matches `.form-picker-display` (outlined, floating "Medication form" label, secondary-container icon chip, name + sub, rotating chevron); grid matches `.form-picker-grid-card` (primary-container card, "Common forms" title, 2-column, 8 options, selected = primary/on-primary); tap toggles; select highlights one + updates display + collapses; local `setState` only (no Riverpod/domain/data); Save still a no-op; selection intentionally unconsumed; colors theme-driven; no `!`. |

## Contract Chain Integrity

- **001 Produces** the 19 `medsAddForm*` getters in `app_localizations.dart` → **consumed by 002 Expects**. ✅
- **001 Produces** the 19 ARB keys + en-only `@`-metadata → map directly to **AC-9 / AC-10**. ✅
- **002 Expects** the 19 getters → satisfied by **001 Produces**. ✅
- **002 Produces** `_MedicationFormPicker`, `_MedFormOption` + 8-item `_medFormOptions`, picker mounted between field and Save, l10n usage, no Riverpod/`!`/domain/data → **consumed by 003 Expects** and map to **AC-1, AC-2, AC-5, AC-6, AC-7, AC-8, AC-11**. ✅
- **003 Expects** the mounted picker + 19 EN getters → satisfied by **002 / 001 Produces**. ✅
- **003 Produces** the `form picker` test group + preserved existing groups → map to **AC-13 / AC-14**. ✅
- No orphaned Produces, no unsatisfied Expects.

## Acceptance-Criteria Coverage

| AC | Task(s) |
|----|---------|
| AC-1 (placement below field, above Save) | 002 |
| AC-2 (display row: label, icon chip, name, sub, chevron) | 002 |
| AC-3 (collapsed + placeholder on first open) | 002 (impl) · 003 (test) |
| AC-4 (tap toggles; title + 8 options 2-col; chevron) | 002 · 003 |
| AC-5 (localized name + Lucide icon, Material fallback) | 002 (+ 001 strings) |
| AC-6 (select → highlight, update display, collapse) | 002 · 003 |
| AC-7 (local setState, no Riverpod, Save no-op) | 002 |
| AC-8 (presentation-only forms, no domain/data, pubspec unchanged) | 002 |
| AC-9 (19 keys in 3 ARBs) | 001 |
| AC-10 (`@`-meta en-only) | 001 |
| AC-11 (context.l10n, no `!`, theme colors) | 002 |
| AC-12 (`dart analyze` clean) | 001 · 002 · 003 |
| AC-13 (widget tests a–d + 026 preserved) | 003 |
| AC-14 (`flutter test`) | 003 |
| AC-15 (`flutter build apk --debug`) | 002 |
| AC-16 (manual theme/locale) | /verify (code-read) |

All 16 ACs covered.
