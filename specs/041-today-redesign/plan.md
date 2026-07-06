# Plan: Today Screen Redesign — Hourly Groups, Countdown, Checkbox Model

**Date**: 2026-07-05
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Redesign the Today screen to template SCREEN 1 fidelity by (1) extending the **pure view model** to bucket doses into hourly groups with a derived group state, per-dose window/enablement, and a countdown target; (2) rebuilding the screen around a **countdown card + collapsible groups** driven by a generalized **one-shot rescheduling `Timer`**; (3) restyling the dose tile with a **checkbox + trailing skip icon**, status chips, and inline low-stock; and (4) rewiring the undo grace window from the hardcoded `kIntakeUndoGracePeriod` to the `gracePeriod` **setting**, surfaced to the meds layer through a settings **projection provider** in the existing composition seam. All new behavior is derivation-driven and unit-testable with a fixed clock; nothing new is persisted.

## Technical Context

**Architecture**: Clean Architecture — this spec touches **domain** (`UndoIntake` grace param; remove `intake_grace.dart`), **presentation view-model** (`today_view_model.dart` grouping/enablement/countdown), **presentation providers** (settings projection + undo wiring in `intake_providers.dart`), and **presentation widgets/screen** (tile, new group + countdown widgets, screen layout + timer). No data/DB layer change.
**Error Handling**: `Either<Failure, T>` at every use-case boundary; screen folds results and shows the existing `todayActionError` SnackBar. Pure derivations don't fail (total functions).
**State Management**: Riverpod codegen. Screen `ref.watch`es `medicationsListProvider`, `intakesListProvider`, and a new `todayIntakeSettingsProvider`; `ref.read`s use cases in callbacks. Group collapse is ephemeral local `StatefulWidget` state keyed by hour.

## Constitution Compliance

| Rule | Status |
|------|--------|
| §2.1 domain purity (no Flutter/drift in domain) | Compliant — `UndoIntake` takes a plain `Duration`; `today_view_model` stays pure Dait presentation (domain + VO imports only). |
| §2.1 cross-feature import (`meds/presentation` must not import `settings/presentation`) | Compliant — the settings read is confined to the **composition seam** `intake_providers.dart` (already permitted to import settings, spec 040); the screen watches a meds-side projection provider, not `settings/presentation` directly. |
| §3.1 no `!`, no unchecked `as`, exhaustive `switch` | Compliant — `switch` over `IntakeStatus`, `TodayGroupState`, `DoseWindowState`, `MedicationType` stays exhaustive, no `default:`. |
| §3.2 `Either` on every fallible op | Compliant — use-case contracts unchanged; `UndoIntake` keeps `Either`. |
| §3.5 no dead code | Compliant — `kIntakeUndoGracePeriod` (and `intake_grace.dart`) removed once its two consumers read the configured `Duration`. |
| §4.2.1 `mounted` after `await`; `Clock.now()`; UTC store/local display; one-shot Timer | Compliant — timer stays one-shot (never `Timer.periodic`), cancelled on dispose/reschedule; all time math via injected `clock.now()` in UTC. |
| §4.3.1 tap targets ≥48 dp | Compliant — checkbox + skip `IconButton` sized ≥48 dp. |
| M3 tokens (no deprecated `surfaceVariant`) | Compliant — `surfaceContainerHighest`/`surfaceContainerHigh`/container roles only. |

## Implementation Approach

### Layer Map

| Layer | What | Files |
|-------|------|-------|
| Domain | `UndoIntake` reads grace from a supplied `Duration`; delete redundant grace constant | `domain/usecases/undo_intake.dart` (mod), `domain/value_objects/intake_grace.dart` (delete) |
| Presentation — view model | Hourly grouping, `TodayGroupState`/`DoseWindowState`, per-dose `windowState`/`actionable`, `undoable` via `gracePeriod`, `nextIntake` target | `presentation/view_models/today_view_model.dart` (mod) |
| Presentation — providers | Settings projection provider (seam); pass `gracePeriod` `Duration` to undo callers | `presentation/providers/intake_providers.dart` (mod) |
| Presentation — screen | Countdown card + collapsible groups layout; generalized one-shot boundary timer; check/uncheck→take/undo, skip-icon→skip, mark-all→N×take; watch projected settings | `presentation/screens/today_screen.dart` (mod) |
| Presentation — widgets | Checkbox+skip tile restyle; new group section; new countdown card; shared type chip | `presentation/widgets/today_dose_tile.dart` (mod), `today_hour_group.dart` (new), `today_countdown_card.dart` (new), `med_type_chip.dart` (new), `medication_tile.dart` (refactor to shared chip) |
| Localization | Countdown/all-done/group-badge/count/mark-all keys ×3 locales | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` |
| Tests | New VM/widget/screen tests; update blast-radius callers/fakes | `test/features/meds/presentation/...` |

### Key Design Decisions

| Decision | Chosen Approach | Why | Rejected |
|----------|----------------|-----|----------|
| Settings → meds seam | `todayIntakeSettingsProvider` in `intake_providers.dart` projecting `settingsNotifierProvider` → a record `(IntakeWindow, Duration grace, bool allowMarkAhead)`; screen watches it | Keeps §2.1: only the seam imports settings; reactive (notifier) so Settings edits reflect live (AC-8/AC-14); mirrors spec 040 discipline | Direct `ref.watch(settingsNotifierProvider)` in screen (violates §2.1 cross-feature presentation import) |
| Grace param type on `UndoIntake` | `call(... required Duration gracePeriod)` | Keeps meds domain settings-VO-agnostic; per-call so it tracks the current setting; preserves `Either` + inclusive boundary | Constructor-injected `GracePeriod` (couples domain to settings VO; not reactive per-call) |
| `kIntakeUndoGracePeriod` fate | Delete constant + `intake_grace.dart`; default now `GracePeriod.defaultValue` (settings) | No dead code (§3.5); single source of default | Keep as redundant default (dead once rewired) |
| View-model shape | Explicit `groups` + `nextIntake` on `TodayView` (see data-model.md) | Testable derivation without pumping widgets (mirrors existing pure VMs) | Flat `doses` + derive groups in widget (untestable in isolation) |
| Group state source | Aggregate of per-dose `DoseWindowState` (time-only), not the raw hour vs current hour | A 14:00 dose with a 120-min window is still "open"/actionable at 15:30; hour-only would mislabel it "past" while its checkbox is enabled | Hour-vs-now comparison (inconsistent with checkbox enablement) |
| "Open" boundary | Inclusive at `windowClose` (`now <= windowClose`) | Dovetails with spec 040's strict `now > windowClose` missed rule — no gap/overlap (AC-9) | Exclusive (creates a 0-width unreachable/duplicated state) |
| Live refresh | Generalize `_scheduleGraceRefresh` → `_scheduleNextBoundaryRefresh`: one-shot to min future boundary (next open / next windowClose / next grace-expiry); on fire `setState` re-derives, **no DB writes** | Countdown + badges + enablement update live without polling; never `Timer.periodic` (keeps `pumpAndSettle`); no reconcile loop | Adding reconcile on the timer (spec 040 deferred; loop risk); `Timer.periodic` (breaks tests) |
| Skip affordance | Trailing `IconButton` (Lucide `skipForward`) left of the checkbox, shown for `pending && actionable`; keyed `todaySkipIcon`, tooltip reuses `todaySkip` | Discoverable one-tap skip keeping `skipped` distinct; ≥48 dp | Long-press menu / bottom sheet (less discoverable — rejected in spec Q) |
| Taken vs skipped in checkbox model | Taken ⇒ checkbox checked (uncheck = undo within grace, else locked); skipped ⇒ unchecked disabled checkbox + "Skipped" label + `todayUndo` button while `undoable`; missed ⇒ "Missed" label, no actions | Preserves the skipped/missed distinction and the existing undo-for-skipped path; keeps exhaustive `switch` | Force skipped into the checkbox (loses distinction) |
| Type chip reuse | Extract shared `MedTypeChip` (continuous / Day N/M / paused) into `med_type_chip.dart`; refactor `medication_tile._TypeChip` to use it; Today tile computes `CourseProgress.resolve(now)` and passes it | DRY on non-trivial color+label logic; avoids divergence between the two screens; reuse `medsListTypeContinuous`/`medsListTypeCourseDay` copy | Duplicate the pill in the Today tile (risks copy/color drift) |
| Stock display | Reuse `formatStock`/`isLowStock` from `medication_display.dart`; render the stock segment **only when low** (bold `cs.error`) | Zero new logic; matches template (red-only) and meds-list treatment | Always show stock (clutters Today; template shows only low) |
| Group collapse state | Per-group `StatefulWidget` keyed `ValueKey('todayGroup-$hour')`, seeded `initiallyExpanded` from state==now (or soonest future when no now group) on first build | Survives parent rebuilds (timer re-derive) and preserves user toggles; ephemeral (resets on reload) per spec | Lift collapse map to screen (more state plumbing); persist (out of scope) |
| Mark-all | Screen loops `markIntakeTaken` over the group's `actionable && pending` doses, sequential `await`, `mounted`-guarded, one SnackBar on any failure | Reuses shipped use case; no new batch API (out of scope) | New batch repo/use case (scope); parallel writes (ordering/rebuild churn) |

### File Impact

| File | Action | What changes |
|------|--------|-------------|
| `lib/features/meds/domain/usecases/undo_intake.dart` | Modify | Add `required Duration gracePeriod` to `call`; compare against it instead of `kIntakeUndoGracePeriod`; drop the `intake_grace.dart` import; keep inclusive boundary + `Either`. |
| `lib/features/meds/domain/value_objects/intake_grace.dart` | Delete | Constant redundant once both consumers read the configured `Duration` (grep-confirm zero refs first). |
| `lib/features/meds/presentation/view_models/today_view_model.dart` | Modify | New params (`intakeWindow`, `gracePeriod: Duration`, `allowMarkAhead`); compute `windowState` + `actionable` per dose; bucket into `TodayHourGroup`s with `TodayGroupState` + `takenCount`; compute `nextIntake`; `undoable` uses `gracePeriod`. Add `TodayHourGroup`, `TodayGroupState`, `DoseWindowState`. |
| `lib/features/meds/presentation/providers/intake_providers.dart` | Modify | Add `todayIntakeSettingsProvider` (record projection of `settingsNotifierProvider`). Undo call site passes the projected `Duration` (the provider stays `UndoIntake(repo)`; grace flows via the call). |
| `lib/features/meds/presentation/screens/today_screen.dart` | Modify | Watch projected settings; pass them to `buildTodayView`; render `TodayCountdownCard` + `ListView` of `TodayHourGroup` (replacing the flat list); generalize the timer to `_scheduleNextBoundaryRefresh`; wire check/uncheck/skip/undo/mark-all; pass `gracePeriod` into `_onUndo`. Preserve tile-key scheme. |
| `lib/features/meds/presentation/widgets/today_dose_tile.dart` | Modify | Replace Take/Skip/Undo buttons with M3 checkbox + trailing skip `IconButton`; add `MedTypeChip` + inline low-stock; `.done`/locked/future-dim/missed visuals; keep exhaustive `IntakeStatus` switch; new keys `todayCheckbox`/`todaySkipIcon` (keep `todayUndo`). |
| `lib/features/meds/presentation/widgets/today_hour_group.dart` | Create | Collapsible section: header (HH:00 via `MaterialLocalizations`, state badge, dose-count sub-label, rotating chevron) + body (tiles + Mark-all tonal row); left-border accent when `state == now`; per-group collapse `StatefulWidget`. |
| `lib/features/meds/presentation/widgets/today_countdown_card.dart` | Create | Primary-container card: "Next intake" + "in Xh Ym · HH:mm" from `nextIntake` + `now`, or "All done for today" when null. Dumb (inputs only). |
| `lib/features/meds/presentation/widgets/med_type_chip.dart` | Create | Shared continuous/Day N/M/paused chip (extracted `_Pill` + spec logic) taking `Medication` + `CourseProgress?`. |
| `lib/features/meds/presentation/widgets/medication_tile.dart` | Modify (refactor) | Point `_TypeChip` at shared `MedTypeChip`; behavior-preserving (existing tests guard). |
| `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` | Modify | Add: `todayNextIntakeLabel`, `todayNextIntakeIn`{hours,minutes} (+ `todayNextIntakeInMinutes`{minutes}), `todayAllDone`, `todayGroupBadgeNow`, `todayGroupBadgeFuture`, `todayGroupTakenCount`{taken,total}, `todayGroupDoseCount`{count, plural}, `todayMarkAllInGroup`. Reuse `medsListTypeContinuous`/`medsListTypeCourseDay`/`medsListStock`/`todayStatus*`/`todayUndo`/`todaySkip`/`todayMarkTaken`/`todayActionError`. Regenerate `AppLocalizations`. |
| `test/features/meds/presentation/view_models/today_view_model_test.dart` | Modify | New params in all call sites; add grouping/state-boundary/enablement-matrix/countdown/`undoable`-grace cases. |
| `test/features/meds/presentation/widgets/today_dose_tile_test.dart` | Modify | Checkbox/skip-icon/chips/stock/locked-missed rendering; new keys. |
| `test/features/meds/presentation/widgets/today_hour_group_test.dart` | Create | Header badge per state, collapse toggle, Mark-all visibility. |
| `test/features/meds/presentation/widgets/today_countdown_card_test.dart` | Create | Countdown value vs all-done. |
| `test/features/meds/presentation/screens/today_screen_test.dart` | Modify | Reword for checkbox/skip/undo/mark-all + groups; keep the mutable-`Clock`/one-shot-`Timer` `pumpAndSettle`-safe idiom; assert live re-derive at a boundary. |
| `test/features/meds/domain/usecases/undo_intake_test.dart` | Modify | Pass `gracePeriod` `Duration`; cover boundary at a non-default grace (e.g. 0 and 30). |

### Documentation Impact

| Doc File | Action | What changes |
|----------|--------|-------------|
| `docs/features/*today*` (or meds feature doc) | Update | Today screen behavior: hourly groups, group states, countdown, checkbox+skip model, settings-driven enablement, grace rewire. Handled by tech-writer post-`/verify`. |
| `docs/architecture.md` | Update (minor) | Note the settings→meds projection-provider seam pattern. |
| `constitution.md §5.1` | No change | `allowMarkAhead`/VO representation already amended by spec 039. |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `buildTodayView`/`UndoIntake` signature changes break callers + hand-written fakes past changed-file analyze | High | Med | Enumerated in File Impact; run **project-wide** `dart analyze` + full `flutter test` (AC-16). |
| One-shot boundary timer regresses to `Timer.periodic` / reschedule loop → `pumpAndSettle` hang | Med | High | Single self-rescheduling one-shot, no DB writes, cancel on dispose/reschedule; reuse the shipped mutable-`Clock`/`FakeAsync` test idiom; assert settle (AC-15). |
| Refactoring the shipped `medication_tile._TypeChip` to shared widget regresses the meds list | Low | Med | Behavior-preserving extraction; existing `medication_tile` tests are the guard; run them unchanged. |
| "Open" vs "missed" off-by-one (gap/overlap with 040's strict `>`) | Med | Med | Inclusive `windowClose`; unit-test at/just-past boundary; cross-check 040 AC-2 (AC-9). |
| Cross-feature settings coupling makes the pure VM provider-aware/impure | Med | Med | VM takes plain values (`IntakeWindow`/`Duration`/`bool`); provider read confined to the seam (§2.1). |
| Skipped-in-checkbox-model UX ambiguity (uncheck=undo only for taken) | Low | Med | Distinct label + `todayUndo` for skipped; line-through/locked visuals; design-auditor pass. |
| Un-batched Mark-all → N rebuilds jank | Low | Low | Accepted MVP trade-off (040 follow-up); noted; batch op out of scope. |

## Dependencies

None new. All packages (`flutter_riverpod`, `riverpod_annotation`, `freezed`, `clock`, `fpdart`, `lucide_icons_flutter`, `flutter_localizations`/`intl`) are already in `pubspec.yaml`. Run `dart run build_runner build --delete-conflicting-outputs` after the `@riverpod` projection provider is added and after ARB changes regenerate `AppLocalizations`.

## Supporting Documents

- [Data Model](data-model.md) — the new/changed presentation view-model types.
- Research: none (no external-library/new-integration/perf signals; all in-stack).
- Contracts: none (no network API; internal Dart signature changes captured in File Impact).

## Plan ↔ Spec AC Coverage

| AC | Covered by |
|----|-----------|
| AC-1 hourly bucketing (pure) | `today_view_model` grouping; VM test |
| AC-2 group state + badge | `TodayGroupState` derivation; `today_hour_group.dart`; group test |
| AC-3 collapse + default expansion | per-group `StatefulWidget` (keyed, `initiallyExpanded`); group/screen test |
| AC-4 countdown target + all-done | `nextIntake` in VM; `today_countdown_card.dart`; card test |
| AC-5 live countdown update | `_scheduleNextBoundaryRefresh`; screen test asserting re-derive at boundary |
| AC-6 check=take / uncheck=undo / lock | tile checkbox wiring + `_onTaken`/`_onUndo`; tile + screen tests |
| AC-7 skip icon → skipped, distinct | trailing skip `IconButton`; `_onSkip`; tile test |
| AC-8 enable matrix + reactive to settings | `actionable`/`windowState` in VM; `todayIntakeSettingsProvider` watch; VM + screen tests |
| AC-9 UTC inclusive window boundary | `DoseWindowState` math; boundary VM tests |
| AC-10 mark-all filtering | screen mark-all loop + `hasActionablePending`; group/screen tests |
| AC-11 status chips | shared `MedTypeChip`; tile test |
| AC-12 inline low-stock | `formatStock`/`isLowStock` in tile; tile test |
| AC-13 no `surfaceVariant` | token audit across new/changed widgets; design-auditor |
| AC-14 grace rewire end-to-end | `UndoIntake` `Duration` param + VM `undoable` + projection; undo + VM tests |
| AC-15 one-shot timer, pumpAndSettle-safe | `_scheduleNextBoundaryRefresh`; screen test |
| AC-16 analyze/suite/l10n/dartdoc/exhaustive | project-wide analyze + full suite; ARB parity; review |
