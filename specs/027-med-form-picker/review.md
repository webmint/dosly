# Review Report: 027-med-form-picker

**Date**: 2026-06-14
**Spec**: specs/027-med-form-picker/spec.md
**Changed files**: 5 source/test (`add_medication_modal.dart`, `app_{en,de,uk}.arb` + 4 generated bindings, `add_medication_modal_test.dart`)

All 3 tasks are **Complete**. Full suite: **299 tests pass**, `dart analyze` clean, `flutter build apk --debug` succeeds.

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 1

**Overall: PASS.** Presentation-only iteration — no persistence, no domain/data, no Riverpod, no network, no new dependencies (pubspec unchanged), no secrets, no `dart:io`/platform channels/parsing, no `!` null-assertion. The 19 new strings are generic pharmaceutical form names + UI chrome (not PHI). No logging path introduced (no `print`/`debugPrint`/logger). The name `TextField` controller is never read/logged/transmitted. Selection is local `setState`, intentionally unconsumed.

- **Info** — `add_medication_modal.dart` (`_selectedIndex`, ~line 137): the selected medication form is held in local state and not persisted/consumed (correct for this scope). **When the future data-save iteration wires this to persistence/notifications, re-apply the constitution PHI rules** (no medication names in logs or notification bodies) at that boundary.
  Recommendation: no action now; carry the PHI constraint into the data-save iteration's spec.

## Performance Review

- High: 0 | Medium: 0 | Low: 6

**Performant as-is** for an 8-item static picker (no I/O, no async, no large lists). No finding rises above Low. Three are worth a trivial fix before the data-save iteration; the rest are not worth touching at this scale.

- **Low** — `add_medication_modal.dart:144-145` (and `:240-241`, `:300-301`): `Theme.of(context)` called twice per build at three sites. It's an O(1) `InheritedWidget` lookup, so the cost is negligible, but it's an idiom/readability nit.
  Recommendation: resolve once — `final theme = Theme.of(context);` then read `.colorScheme` / `.textTheme`.
- **Low** — `add_medication_modal.dart:334`: `_buildChip` re-resolves `context.l10n` though `_buildGrid` already has a local `l10n` in scope (8 redundant lookups on open).
  Recommendation: pass `l10n` into `_buildChip` or use the enclosing variable.
- **Low** — `add_medication_modal.dart:272, 311`: two missing `const` (`BorderRadius.vertical(bottom: Radius.circular(16))` and `EdgeInsets.symmetric(horizontal: 10, vertical: 8)`) — tiny per-build heap allocs.
  Recommendation: add `const`. (`dart analyze` did NOT flag these, so they're optional.)
- **Low** — `add_medication_modal.dart:245-265`: `_buildGrid` rebuilds the `rows` list + 4 `Row`s on each open. Bounded (grid is live ~1 frame on select). Fragile only if a future "open without selecting" toggle is added.
  Recommendation: if the picker ever grows >~20 items or `_isOpen` decouples from selection, switch to `GridView.count`/`Wrap`. Not now.
- **Low** — `add_medication_modal.dart:281-285, 337-341`: `TextStyle.copyWith` allocates per build (8 chips). Below profiling threshold at this scale.
  Recommendation: none now; revisit if chip count grows.
- **Low** — `add_medication_modal.dart:228`: `AnimatedSize` clip + conditional-build is the correct tradeoff (keeps 8 chips out of the tree when collapsed); `AnimatedRotation` chevron is GPU-composited. No concern — noted as validated.

## Test Assessment

- AC items with direct test coverage: AC-3, AC-4 (partial), AC-6 (partial), AC-7, AC-13 (a–d) — the spec-required tests are all present and honest.
- ACs covered by code-reading only: AC-1 (order), AC-2 (icon chip), AC-5 (icon half), AC-8 (no-domain constraint), AC-11 (no-`!`/theme colors).
- **Verdict: ADEQUATE.** AC-13 explicitly scoped the required tests to (a)–(d); all four exist, are self-validating, and named honestly (e.g. test (b) matches the rendered uppercased "COMMON FORMS"). All remaining gaps are **nice-to-have** for a visual-only iteration.

Coverage gaps (all **[nice-to-have]**, none AC-required):
- **[nice-to-have]** AC-4: chevron rotation state (`AnimatedRotation.turns` 0↔0.5) not asserted; 2-column layout and exact option ORDER not asserted (only the 8 names' presence).
- **[nice-to-have]** AC-5: per-option Lucide icon (`find.byIcon(LucideIcons.tablets)` etc.) not asserted (names are).
- **[nice-to-have]** AC-6: display-row icon update (placeholder `shapes` → selected form's icon) and selected-chip styling (`primary` background) not asserted.
- **[nice-to-have]** AC-2: icon-chip presence and sub-line-absent-before-selection not explicitly asserted.
- **[nice-to-have]** Re-selecting the same option (idempotent) not tested; picker not opened under `de`/`uk` locale or dark theme.
- **[nice-to-have]** AC-1: widget order (TextField → picker → Save) inferred from code, not asserted (such a test would be brittle).

## Notes for /verify
- No Critical/High findings anywhere. Security PASS; Performance all-Low; Tests ADEQUATE.
- AC-16 is manual (theme/locale on the live picker) — verify by code-reading (theme-driven colors via `colorScheme`, strings via `context.l10n`).
- Open item for the user (not a defect): UK `medsAddFormCapsule` = "Капсули" (plural) is the verbatim design value (spec §3.6/§8) — translator's call.
