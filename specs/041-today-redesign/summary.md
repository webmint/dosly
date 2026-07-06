## Feature Summary: 041 — Today Screen Redesign

### What was built
The Today screen now matches the Material 3 template (SCREEN 1): today's doses are grouped into **collapsible per-hour sections** each with a past/now/future state badge and a **Mark-all** action, a **"next intake" countdown card** sits on top, and dose rows use a **checkbox** (check = taken, uncheck = undo within grace) with a secondary **skip** icon that keeps *skipped* distinct from *missed*. Rows now show **status chips** (continuous / Day N/M) and an **inline low-stock warning**, and per-dose interactivity is driven live by the user's intake-window / grace-period / mark-ahead settings (specs 039 & 040). This is Spec C — the final link of the 039→040→C chain.

### Changes
- Task 001: l10n keys — 9 new Today strings (countdown, all-done, group badges, dose-count, mark-all) across en/de/uk.
- Task 002: settings projection provider — `todayIntakeSettings` exposes intake-window/grace/mark-ahead to the Today layer via the §2.1-compliant composition seam (reactive to Settings changes).
- Task 003: shared `MedTypeChip` — extracted the continuous / Day-N/M / paused chip so the Today tile and meds-list tile share one implementation (behavior-preserving).
- Task 004: `UndoIntake` configurable grace — undo window now takes a `Duration` from the `gracePeriod` setting instead of a hardcoded 5 min.
- Task 005: view-model rewrite — `buildTodayView` now yields hour-bucketed groups, per-dose window state + checkbox enablement, and the countdown target.
- Task 006: dose tile redesign — checkbox + skip icon, status chips, inline low-stock, taken/skipped/missed/locked/dimmed states.
- Task 007: `TodayCountdownCard` — primary-container card showing "in Xh Ym · HH:mm" or "All done for today".
- Task 008: `TodayGroupSection` — collapsible hour group with state badge, dose-count sub-label, and a Mark-all button gated on actionable-pending doses.
- Task 009: screen redesign — countdown card + hour groups, mark-all wiring, and a one-shot self-rescheduling **boundary timer** that re-derives the view at each window/grace boundary (never `Timer.periodic`); deleted the obsolete `intake_grace.dart`.
- Task 010: integration & regression sweep — repaired the golden-flow integration test to the checkbox model, added dose-tile dim coverage, and gated the full suite + audits green.

### Files changed
- `lib/features/meds/presentation/widgets/` — 4 added (`med_type_chip`, `today_countdown_card`, `today_group_section`, + restyled `today_dose_tile`), 1 refactored (`medication_tile`)
- `lib/features/meds/presentation/` — `screens/today_screen.dart` rewritten, `view_models/today_view_model.dart` rewritten, `providers/intake_providers.dart` (projection provider)
- `lib/features/meds/domain/` — `usecases/undo_intake.dart` (configurable grace), `value_objects/intake_grace.dart` **deleted**
- `lib/l10n/` — 3 ARB files + regenerated `AppLocalizations` (9 new keys)
- `test/` + `integration_test/` — 6 feature test files (78 tests) + golden-flow integration test updated
- [Total: 42 files changed, ~4,547 insertions, ~800 deletions — includes specs, generated l10n, and tests]

### Key decisions
- Settings seam: a meds-side `todayIntakeSettings` projection provider (not a direct `settings/presentation` import) keeps the screen settings-free per constitution §2.1 and reactive.
- Grace as `Duration` at the use-case boundary (resolved from the `GracePeriod` VO at the seam) keeps the meds domain settings-agnostic.
- Group state derives from the **aggregate per-dose window state** (not the raw hour), so a dose stays "now"/actionable while its window is open even past the top of its hour.
- One-shot rescheduling **boundary timer** (candidates strictly after `now`) instead of `Timer.periodic` — re-derives live without polling and stays `pumpAndSettle`-safe.

### Deviations from plan
- Task 003: also refactored `medication_tile.dart` to consume the extracted `MedTypeChip` (the "shared chip (maybe)" the spec flagged in §4/OQ-4).
- Task 005: added transitional shims to keep every intermediate task green through the two signature changes — a `TodayView.doses` flattener getter and defaults on the new `TodayDose` fields (getter is production-unused post-009; §3.5 cleanup tracked); also touched `today_screen_test.dart` (AC-8 blast radius).
- Task 009: fixed a review-found crash risk in Mark-all (`ref.read` after `await` → per-iteration `mounted` guard) and added an explicit list-item key.
- Task 010: agent stalled once after rewriting the integration test; a scoped follow-up added the remaining dose-tile assertions and re-verified green.

### Acceptance criteria
- [x] AC-1: doses bucket by hour (`minuteOfDay ~/ 60`), ascending
- [x] AC-2: group state future/now/past with the right badge + left-border accent
- [x] AC-3: collapsible groups; current group expanded by default; ephemeral
- [x] AC-4: countdown targets the soonest future pending dose; "all done" otherwise
- [x] AC-5: countdown/badges/enablement re-derive live at each boundary
- [x] AC-6: check = taken, uncheck = undo within grace, locked after grace
- [x] AC-7: secondary skip icon (≥48 dp, tooltip) for pending-actionable doses
- [x] AC-8: per-dose enable matrix driven by intake-window + mark-ahead, reactive to Settings
- [x] AC-9: UTC window boundary, inclusive at close (dovetails with spec 040's missed rule)
- [x] AC-10: Mark-all marks only actionable-pending doses in the group
- [x] AC-11: continuous / Day-N/M status chips
- [x] AC-12: inline low-stock warning (bold error) only when low
- [x] AC-13: no deprecated `surfaceVariant`
- [x] AC-14: undo grace reads the `gracePeriod` setting end-to-end
- [x] AC-15: one-shot boundary timer (never `Timer.periodic`), `pumpAndSettle`-safe
- [x] AC-16: project-wide analyze clean, full suite green (836/836), en/de/uk parity
