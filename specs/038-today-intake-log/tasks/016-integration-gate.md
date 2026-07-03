# Task 016: Integration gate — full test suite + build

**Agent**: qa-engineer
**Files**: `integration_test/today_intake_flow_test.dart` (optional), test harness updates if needed
**Depends on**: 015
**Blocks**: —
**Context docs**: docs/features/meds.md
**Review checkpoint**: Yes

**Description**:
Terminal verification task (the meds-feature "integration gate on the terminal task only" pattern). Run the full suite + a debug build to catch cross-task integration breakage, and optionally add an on-device golden flow. No new production code.

**Change details**:
- Run `flutter test` (entire suite) — all green, including the migration, expansion, view-model, data-source, mapper, and widget tests from prior tasks.
- Run `flutter build apk --debug` — compiles clean (drift codegen + freezed + riverpod_generator all consistent).
- Optional: `integration_test/today_intake_flow_test.dart` — add a medication with an intake time, open the Today tab, mark the dose taken, assert the tile shows Taken; undo, assert back to pending. If the harness seeds/overrides providers (see `integration_test/support/app_harness.dart` and the `devSeedProvider` no-op override), keep intake state deterministic.
- Run `dart analyze` on the whole project — zero new issues.

**Contracts**:

### Expects
- All prior tasks complete; `home_screen.dart` renders the reactive Today checklist (Task 015).

### Produces
- `flutter test` passes across the whole suite; `flutter build apk --debug` succeeds; `dart analyze` reports no new issues.
- (Optional) `integration_test/today_intake_flow_test.dart` exercises add → mark taken → undo.

**Done when**:
- [ ] `flutter test` green (whole suite).
- [ ] `flutter build apk --debug` succeeds.
- [ ] `dart analyze` clean (no new issues).
- [ ] (If added) integration flow passes.

**Spec criteria addressed**: AC-15

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-02
**Files changed**: `integration_test/today_intake_flow_test.dart` (new) + post-gate `dart format` of 7 new-038 files.
**Contract**: Produces [4/4] — full suite green, APK builds, analyze clean, integration flow added.
**Notes**: **GATE = PASS.** `dart analyze`: no issues. `flutter test`: **659/659**. `flutter build apk --debug`: ✓ built. On-device integration flow (add med → Today tab → Take → Undo) passes (bounded `pump()`, no hung grace timer). Format check flagged 40 files as not tall-style-clean; 33 predate feature 038 (standing repo debt — see audit 2026-06-10 finding #7), **7 new-038 files** were formatted here (analyze stayed clean after). The 33 pre-existing files left as-is (out of feature scope) — candidate for a repo-wide `dart format` cleanup.
