# Research: Add-Medication Form — Name Input + Save Button (visual-only, iteration 1)

**Date**: 2026-06-11
**Topic**: Start the add-medication form slowly — put a medication-name input and a Save button into the existing placeholder modal. **Visual only** this iteration: no data is saved/handled. Designs in `dosly_m3_template.html`.
**Verdict**: Feasible — small, well-scoped UI increment that fits cleanly into existing infrastructure.

## User Constraints (confirmed)

- Build **only the visual** this iteration — the entered data is **not** saved or handled.
- The form will be built across **several iterations**; the **last** iteration is the actual data save (domain entity + repository + drift).
- **Save button action this iteration: no-op** (`onPressed` does nothing — purely decorative). Chosen over "close the modal" to be most literally visual-only.

## Summary

The placeholder modal already exists and is wired end-to-end (FAB → `Navigator.push(fullscreenDialog)` → `AddMedicationModal`). Today its body is `SizedBox.shrink()`. This iteration replaces that empty body with **one outlined `TextField` (medication name)** and **one `FilledButton` (Save)** — matching the HTML "Screen 3" design's first form field (`Назва ліків`) and its `.btn-filled` save button. No new dependencies: `TextField` is core Flutter, the Save icon is `LucideIcons.save` from the already-installed `lucide_icons_flutter`, and M3 theming is automatic. Per the user's constraint, **Save is a no-op** — no persistence, no domain/data layer, no `Either`, no validation-for-save. The only structural change is converting the modal from `StatelessWidget` to `StatefulWidget` so it can own and dispose the `TextEditingController`.

## Codebase Findings

### Existing Related Code
| Area | Files | Relevance |
|------|-------|-----------|
| The modal to edit | `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Currently a `StatelessWidget` → `Scaffold(AppBar + SizedBox.shrink())`. The **only** file that meaningfully changes. |
| FAB trigger | `lib/features/meds/presentation/screens/meds_screen.dart:61` | Already opens the modal — **no change needed**. |
| Modal test | `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Asserts body is `SizedBox.shrink` with no other widgets — **will need updating** in the same task. |
| Localization | `lib/l10n/app_{en,de,uk}.arb` + `l10n_extensions.dart` | Established 3-locale ARB pattern; `context.l10n` is the single sanctioned access point. Two new keys needed. |
| HTML design | `dosly_m3_template.html:2000-2005` (field), `:2229-2235` (Save btn), `:879-908` (`.tf`/`.fi` CSS) | Field = M3 outlined text field w/ floating label; Save = filled button + save icon. |

### Patterns Available (everything needed already exists)
- **Outlined text field** → the HTML `.fi` (56px, 2px primary border, floating label on `--md-surface`) is a textbook **Material 3 `TextField` with `OutlineInputBorder` + `labelText`** — Flutter renders this for free from the global theme.
- **Filled save button** → `FilledButton.icon(icon: Icon(LucideIcons.save), label: Text(...))`. The HTML save SVG path is the canonical Lucide `save` glyph.
- **Lucide icons** → precedent established (`LucideIcons.plus`, `.arrowLeft` already used in this exact modal). _Note: `save` isn't in MEMORY's verified-name list — quick compile-check; fallback `Icons.save_outlined` if it surprises._
- **3-locale ARB + `context.l10n`** → identical to how `medsAddTitle`/`medsAddFabTooltip` were added in spec 011.

### Gaps (all intentional, deferred to later iterations)
- **No text input exists anywhere in the app yet** — this is the project's *first* `TextField`/`TextEditingController`. The modal must become a `StatefulWidget` to own and `dispose()` the controller.
- **No persistence layer** — `drift`/`sqlite` are **not in `pubspec.yaml`** yet (despite being the planned DB in the constitution). No `Medication` entity, repository, or provider exists. Persistence is the **final** iteration, not this one.

## Constitution Constraints

| Rule | Impact on this iteration |
|------|--------------------------|
| Clean Architecture (domain/data/presentation) | **Not triggered yet** — a UI-only iteration with no fallible operation touches only `presentation/`. Domain+data land in the final (save) iteration. |
| Every fallible op returns `Either<Failure, T>` | A no-op Save has **no** fallible op, so no `Either` needed now. |
| Validate at boundaries | Not applicable this iteration (no data leaves the widget). Validation arrives with the save iteration. |
| New public widgets need dartdoc `///` | The modal already has dartdoc; keep it accurate when the body changes. |
| No `!` null assertion | Reach strings via `context.l10n`; no `AppLocalizations.of(context)!` at call sites. |
| Strict-mode `dart analyze`, no lint-suppression | Must stay green (PostToolUse hook enforces). |
| New strings in all 3 ARBs + `@`-meta in `app_en.arb` only | Add `medsAddNameLabel` + `medsAddSaveButton` (×3 locales). |

## Approaches

### Option A — Visual-only: name field + no-op Save _(SELECTED)_
- **Description**: Convert `AddMedicationModal` to `StatefulWidget`. Body = scrollable padded `Column` with one outlined `TextField` (label "Medication name") + a `FilledButton.icon` "Save" using `LucideIcons.save`. Save's `onPressed` is a no-op. No domain/data/persistence/validation.
- **Pros**: Truly "start slowly"; one-file change + test + ARB; zero new deps; zero speculative architecture (honors KISS / "minimal changes"); keyboard-safe with a scroll view.
- **Cons**: Save does nothing — pure scaffold. Acceptable and intended for a multi-iteration build.
- **Complexity**: **Low**

### Option B — In-memory: Save adds the name to a Riverpod list _(deferred)_
- **Description**: Option A + a minimal `@Riverpod(keepAlive: true)` notifier holding `List<String>`. Save appends and pops.
- **Pros**: Real save→state loop; introduces Riverpod-in-meds wiring incrementally.
- **Cons**: Expands beyond "visual only"; in-memory data vanishes on restart — throwaway before drift. Contradicts this iteration's constraint.
- **Complexity**: **Medium**

### Option C — Full persistence (drift entity + repository + use case) _(final iteration)_
- **Description**: Add `drift` to `pubspec`, define `Medications` table + migration, `Medication` entity, `MedicationRepository` (+ Impl returning `Either<Failure, T>`), `AddMedication` use case, provider.
- **Pros**: The "real" architecture; data survives restarts.
- **Cons**: A whole `/specify` of its own; first drift integration, migrations, full Clean Architecture stack. This is the **last** iteration, by design.
- **Complexity**: **High**

**Recommended approach**: **Option A** — matches the user's request literally (input + Save button, visual only) and defers all data handling to later iterations.

## Iteration Roadmap (informational)

1. **Iteration 1 (this one)** — visual: medication-name `TextField` + no-op Save button.
2. **Iteration 2+** — layer in the rest of the HTML Screen-3 form, visual-first: form picker (8 forms), dose + unit, quantity stepper, stock card, time chips, intake type (Permanent/Course) + course params.
3. **Final iteration** — wire actual data save: `Medication` entity, drift table + migration, repository (`Either<Failure, T>`), `AddMedication` use case, provider; validation at the boundary.

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | **Low** | 1 widget file + 1 test file + 3 ARB files (+ regenerated bindings). |
| New dependencies | **None** | `TextField` is core Flutter; Lucide already installed. |
| Risk | **Low** | Watch-items: `StatefulWidget` controller disposal, keyboard overflow (use a scroll view), `LucideIcons.save` name check, and updating the existing modal test that asserts an empty body. |

## Recommendation

**Proceed** with a tightly-scoped, visual-only spec:

```
/specify "Iteration 1 (visual-only) of the add-medication form. In the existing AddMedicationModal, replace the empty SizedBox.shrink body with: (1) an outlined Material 3 TextField labeled 'Medication name', and (2) a FilledButton.icon 'Save' using LucideIcons.save — styled per dosly_m3_template.html Screen 3 (Назва ліків field + Зберегти button). PURELY VISUAL: no persistence, no domain/data layer, no Either, no validation; the Save button's onPressed is a no-op. Convert the modal to a StatefulWidget to own/dispose the TextEditingController. Body is a scrollable padded Column (keyboard-safe). Add ARB keys medsAddNameLabel + medsAddSaveButton across en/de/uk with @-metadata in app_en.arb, via context.l10n. Update add_medication_modal_test.dart. This is the first of several visual iterations; the final iteration adds actual data save."
```

When ready for the data round-trip, that is the **final** iteration — `Medication` entity + drift table + repository + `AddMedication` use case (Option C), where `Either<Failure, T>` and the domain layer finally enter the meds feature.
