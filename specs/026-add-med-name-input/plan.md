# Plan: Add-Medication Name Field + Save Button (visual-only, iteration 1)

**Date**: 2026-06-11
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Convert `AddMedicationModal` from `StatelessWidget` to a plain `StatefulWidget` that owns a single `TextEditingController`, and replace its `SizedBox.shrink` body with a scrollable, padded `Column` holding an outlined medication-name `TextField` and a full-width `FilledButton.icon` Save button whose `onPressed` is a documented no-op. Two new localization keys (`medsAddNameLabel`, `medsAddSaveButton`) are added across the three ARB files. The change is confined entirely to the `presentation/` layer plus l10n — no `domain/`, `data/`, routing, theme, or dependency changes.

## Technical Context

**Architecture**: Clean Architecture — this iteration touches **only** the meds `presentation/` layer (one widget) plus the shared `lib/l10n/` ARB assets. No domain/data layers are introduced (deferred to the data-save iteration).
**Error Handling**: Not applicable — there is no fallible operation this iteration (the Save button performs no work), so no `Either<Failure, T>` and no try/catch are introduced.
**State Management**: Local widget state via `StatefulWidget` + `TextEditingController`. **No Riverpod** — there is no shared/app state to expose this iteration (spec §6).

## Constitution Compliance

| Rule | Status |
|------|--------|
| §2.1 layer boundaries (presentation never imports `data/`) | Compliant — only `flutter/material`, `lucide_icons_flutter`, and the local `l10n_extensions` are imported. |
| Domain purity (no Flutter in `domain/`) | N/A — no domain code touched. |
| Every fallible op returns `Either<Failure, T>` | N/A — no fallible op (no-op Save, no persistence). |
| Validate external input at boundaries | Deferred — no validation this iteration (spec §6); the field captures text but nothing consumes it. |
| No `!` null assertion | Compliant — strings via `context.l10n`; no `!` at call sites. |
| Dartdoc on public widgets | Compliant — `AddMedicationModal` dartdoc updated to describe the new body + intentional no-op. |
| Never leave bare TODOs / never swallow | Compliant — the no-op `onPressed` carries an inline comment referencing spec 026 and the iteration roadmap; it is an intentional empty callback, not a swallowed error. |
| `dart analyze` clean, no lint-suppression | Required — `dispose_fields`/controller-disposal and strict-mode lints must pass with zero issues. |
| Theme-driven styling (no hard-coded colors) | Compliant — `OutlineInputBorder` + `FilledButton.icon` derive all colors from the global M3 theme. |
| L10n pattern (3 ARBs, `@`-meta in en only, `context.l10n`) | Compliant — keys added to all three ARBs, metadata only in `app_en.arb`, regenerated via `flutter gen-l10n`. |
| No new dependencies | Compliant — `pubspec.yaml` untouched; `lucide_icons_flutter` already present. |

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Domain | — (none) | — |
| Data | — (none) | — |
| Presentation | Stateful modal: controller lifecycle + field + Save button (no-op) | `lib/features/meds/presentation/widgets/add_medication_modal.dart` (Modify) |
| L10n (shared assets) | Two new keys + en metadata, regenerated bindings | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (Modify); `app_localizations*.dart` (Regenerate) |
| Tests | Replace empty-body assertions; add field/button/no-op assertions; keep locale/back-arrow/typography tests | `test/features/meds/presentation/widgets/add_medication_modal_test.dart` (Modify) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Widget type | Plain `StatefulWidget` | Needs a `TextEditingController` (must be disposed); no shared state to expose | `ConsumerStatefulWidget` (speculative — no Riverpod need yet, KISS); keeping `StatelessWidget` (can't own/dispose a controller cleanly) |
| Body layout | `SingleChildScrollView` → `Padding(16h)` → `Column(crossAxisAlignment: stretch)` | Keyboard-safe (field scrolls above keyboard, no overflow); `stretch` makes the Save button full-width without a `SizedBox(width: infinity)` | Plain `Column` (overflows when keyboard opens); `ListView` (heavier than needed for 2 children); pinned bottom-footer button (deferred styling, spec §8) |
| Name field | `TextField` + `InputDecoration(labelText, border: OutlineInputBorder())` | Direct 1:1 map of the HTML `.fi` outlined field; no `Form`/validator needed (no validation this iteration) | `TextFormField` (pulls in `Form`/validation semantics not wanted yet) |
| Save button | `FilledButton.icon(icon: Icon(LucideIcons.save), label: Text(...))`, non-null no-op `onPressed` | Maps the HTML `.btn-filled` (filled + leading save glyph); enabled appearance requires a non-null callback | Disabled button (`onPressed: null`) — renders greyed, doesn't match the design; `ElevatedButton`/`TextButton` — wrong M3 emphasis |
| Save icon | `LucideIcons.save` | **Verified present** in `lucide_icons_flutter 3.1.12` (`lucide_icons.dart:60655`); matches the project icon set | `Icons.save_outlined` (spec §8 fallback — not needed, `save` compiles); a new icon package (forbidden) |
| No-op marker | Empty `onPressed: () {}` with an inline comment referencing spec 026 + the data-save iteration | Satisfies "no bare TODO / never swallow"; keeps the button visibly enabled per design; explicit that no behavior is intended | A `TODO` (bare TODO forbidden); throwing/snackbar (that is behavior, out of scope) |
| Controller lifecycle | Field initializer `final _nameController = TextEditingController();` + `dispose()` calls `_nameController.dispose()` | Standard Flutter idiom; satisfies disposal lint and prevents leak | Lazy `initState` creation (no benefit here); not disposing (lint failure + leak) |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Modify | `StatelessWidget` → `StatefulWidget` + `State`; add `_nameController` (disposed in `dispose`); body becomes `SingleChildScrollView` → padded `Column` with the name `TextField` and the full-width `FilledButton.icon` Save (no-op `onPressed`); AppBar unchanged; dartdoc updated (library + class) to describe the new body and intentional no-op. |
| `lib/l10n/app_en.arb` | Modify | Add `medsAddNameLabel` ("Medication name") + `medsAddSaveButton` ("Save") with `@`-description blocks. |
| `lib/l10n/app_de.arb` | Modify | Add `medsAddNameLabel` ("Medikamentenname") + `medsAddSaveButton` ("Speichern"), values only. |
| `lib/l10n/app_uk.arb` | Modify | Add `medsAddNameLabel` ("Назва ліків") + `medsAddSaveButton` ("Зберегти"), values only. |
| `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_de.dart`, `app_localizations_uk.dart` | Regenerate | Produced by `flutter gen-l10n` after ARB edits — not hand-edited. |
| `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Modify | Replace the `body is empty (SizedBox.shrink)` test with: field-present-with-localized-label, Save-button-present-with-localized-label-and-`LucideIcons.save`, and no-op-tap-is-harmless (no throw, modal not popped). Keep en/de/uk title tests, back-arrow-leading test, and title-typography test passing unchanged. |

### Documentation Impact

No documentation changes expected this iteration — `docs/features/meds.md` does not exist yet, and the modal is still a visual placeholder with no behavior to document. Feature docs will be authored by `/finalize`/tech-writer once the form gains real behavior in a later iteration. (Carried as a note, not a task.)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Existing `body is empty` test breaks | High | Low | Bundle the widget change + test update in one task (spec AC-10); breakage stays internal to that task. |
| `flutter gen-l10n` not run after ARB edits → `context.l10n.medsAddNameLabel` undefined | Med | Med | The task's "done when" includes regenerating bindings (`flutter gen-l10n` / `flutter pub get`) and a green `dart analyze` before completion. |
| Controller not disposed → leak / lint failure | Low | Med | AC-1 + `dispose()`; the disposal lint and code-review step cover it. |
| No-op Save read as a bug by reviewer/future reader | Med | Low | Inline comment references spec 026 + roadmap (spec AC-5 makes the no-op explicit and testable). |
| Keyboard overlaps field/button on small screens | Low | Low | `SingleChildScrollView` body (spec AC-2). |
| `crossAxisAlignment: stretch` unexpectedly stretches the `TextField` height or the button oddly | Low | Low | `TextField` height is fixed by the M3 outlined decoration; only horizontal stretch applies. Verified visually in AC-13. |

## Dependencies

None. No packages to install, no services to configure, no environment variables. `lucide_icons_flutter ^3.1.12` (already present) supplies `LucideIcons.save`.

## AC → Implementation Coverage (Phase 2.5 cross-reference)

| AC | Covered by |
|----|-----------|
| AC-1 (StatefulWidget + controller dispose) | modal Modify — `State` + `_nameController` + `dispose()` |
| AC-2 (body scrollable; 1 field + 1 FilledButton; AppBar unchanged) | modal Modify — `SingleChildScrollView`/`Column`; AppBar untouched |
| AC-3 (field labelText + OutlineInputBorder, no overrides) | modal Modify — `InputDecoration` |
| AC-4 (FilledButton.icon + `LucideIcons.save` + label, full-width) | modal Modify — Save button; icon verified present |
| AC-5 (Save enabled, no-op, documented) | modal Modify — non-null `onPressed: () {}` + comment |
| AC-6 (keys in all 3 ARBs) | ARB Modify ×3 |
| AC-7 (`@`-metadata only in en) | `app_en.arb` Modify |
| AC-8 (strings via `context.l10n`, no `!`) | modal Modify — `context.l10n.*` |
| AC-9 (`dart analyze` clean) | task "done when" gate |
| AC-10 (test updated; old empty-body assertion removed; locale/back-arrow/typography kept) | test Modify |
| AC-11 (`flutter test` passes) | task "done when" gate |
| AC-12 (`flutter build apk --debug`) | task "done when" gate |
| AC-13 (manual theme/locale) | /verify code-reading + manual check |

All 13 ACs have a concrete implementation path. The File Impact list adds no files beyond the spec's Affected Areas (exact match).

## Supporting Documents

- No `research.md` — no signals (core Flutter widget; Lucide already a dependency; sole architecture choice settled in the spec).
- No `data-model.md` — no entities this iteration.
- No `contracts.md` — no API surface.
