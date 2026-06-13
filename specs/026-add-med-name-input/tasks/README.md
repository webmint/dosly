# Tasks: Add-Medication Name Field + Save Button (visual-only, iteration 1)

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-06-11
**Total tasks**: 2

## Dependency Graph

```
001 (l10n keys) ──→ 002 (modal field + Save button + test)
```

Strictly sequential: the widget in 002 references `context.l10n.medsAddNameLabel` /
`medsAddSaveButton`, which do not exist until 001 regenerates the bindings.

## Task Index

| # | Title | Agent | Depends on | Review checkpoint | Status |
|---|-------|-------|-----------|-------------------|--------|
| 001 | Add medsAddNameLabel + medsAddSaveButton l10n keys | mobile-engineer | None | No | Complete |
| 002 | Add name field + no-op Save button to AddMedicationModal (+ update test) | mobile-engineer | 001 | Yes | Complete |

## Additions to Spec

None. The task File Impact exactly matches the spec's Affected Areas (modal widget, 3 ARB files + regenerated bindings, modal test).

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Mechanical ARB additions following the established 3-locale pattern; nothing consumes the keys yet, so the project stays green. Only watch-item: actually running `flutter gen-l10n`. |
| 002 | Low–Med | First text input / first `StatefulWidget`-with-controller in the project; the existing empty-body test must be updated in-task so it doesn't falsely fail. Controller disposal + no-op documentation are the correctness points. Impact stays Low (isolated, presentation-only). |

## Review Checkpoints

| Before completing Task | Reason | What to Review |
|------------------------|--------|----------------|
| 002 | Substantive visual change; user values HTML-design fidelity (spec 011 precedent) | Field is an outlined M3 `TextField` labeled "Medication name"; Save is a full-width filled button with the Lucide save icon; layout matches `dosly_m3_template.html` Screen 3; Save is a documented no-op; controller is disposed. |

## Contract Chain Integrity

- **001 Produces** `medsAddNameLabel` / `medsAddSaveButton` getters in `app_localizations.dart` → **consumed by 002 Expects**. ✅
- **001 Produces** the ARB keys + `@`-metadata → map directly to **AC-6 / AC-7**. ✅
- **002 Expects** the two getters → satisfied by **001 Produces**. ✅
- **002 Produces** (StatefulWidget, disposed controller, `TextField` + `FilledButton.icon`, no `SizedBox.shrink` body, updated test) → map to **AC-1…AC-5, AC-8, AC-10**. ✅
- No orphaned Produces, no unsatisfied Expects.

## Acceptance-Criteria Coverage

| AC | Task(s) |
|----|---------|
| AC-1 (StatefulWidget + dispose controller) | 002 |
| AC-2 (scrollable body; 1 field + 1 FilledButton; AppBar unchanged) | 002 |
| AC-3 (field labelText + OutlineInputBorder) | 002 |
| AC-4 (FilledButton.icon + LucideIcons.save + label, full-width) | 002 |
| AC-5 (Save enabled, no-op, documented) | 002 |
| AC-6 (keys in all 3 ARBs) | 001 |
| AC-7 (`@`-metadata only in en) | 001 |
| AC-8 (strings via `context.l10n`, no `!`) | 002 |
| AC-9 (`dart analyze` clean) | 001, 002 |
| AC-10 (test updated; old empty-body assertion removed) | 002 |
| AC-11 (`flutter test` passes) | 002 |
| AC-12 (`flutter build apk --debug`) | 002 |
| AC-13 (manual theme/locale) | /verify (manual) |

All 13 ACs covered.

## Verification (2026-06-12, re-verified after on-device run)

Both tasks Complete. `/verify` verdict: **APPROVED** (with non-blocking warnings).
- AC: 12/12 automatable PASS · AC-13 PARTIAL (user-confirmed on-device: boots, modal opens, input outlined).
- `dart analyze`: clean · `flutter test`: **295 pass** · `flutter build apk --debug`: built · **on-device boot: confirmed**.
- Review (full branch): Security PASS (0 Crit/High) · Performance 1 Medium (latent/unreachable) + 2 Low · Test GAPS FOUND (warnings only).
- **Out-of-spec fixes mixed into the branch** (user-authorized): `fix(startup)` (resolved a latent first-device-run crash — nested-scope override didn't propagate; see MEMORY) and `fix(theme)` (inputs outlined/transparent instead of filled-gray).
- Full report: `../verify.md` · Review: `../review.md`.
