# Tasks: Bottom App Navigation

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-04-14
**Total tasks**: 2
**Completion**: All tasks complete · `/verify` verdict: APPROVED · spec Status: Complete · 2026-04-14

## Dependency Graph

```
001 (widget + wire) ──→ 002 (widget test + integration gate)
```

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Create HomeBottomNav widget and wire into HomeScreen | mobile-engineer | None | Complete |
| 002 | Write widget test for HomeBottomNav | qa-engineer | 001 | Complete |

## Additions to Spec

None. Both files in Task 001 and the test file in Task 002 were already listed in spec §4 "Affected Areas" and plan "File Impact".

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Spec + plan are unambiguous. Widget is stateless, uses only built-in `NavigationBar` + pre-verified Lucide icons. No new imports, no color/theme customization, no state. Main residual risk is the `const` empty lambda — plan already documents the fallback (promote to a top-level `_noop` function). |
| 002 | Low | Testing a stateless widget with a no-op callback is deterministic. Harness is a two-line `MaterialApp` + `Scaffold` wrap. No mocks required. |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 002 | Final integration gate (first full-stack `flutter test` + `flutter build apk --debug` verification for the feature). Per MEMORY.md "Integration-gate task ordering for UI refactors" (Feature 002), the cross-task integration point is the natural place to pause before running the heavier gates. | Confirm Task 001 produced the exact `HomeBottomNav` API the test will pump (class name, const constructor, `package:dosly/features/home/presentation/widgets/home_bottom_nav.dart` export path). If Task 001's agent renamed or relocated anything, Task 002 must update its imports/assertions. |

## Contract Chain Integrity

- **Task 001 Produces → Task 002 Expects**: `HomeBottomNav` class + const constructor + `NavigationBar` shape — all three "Expects" in Task 002 are satisfied by Task 001's "Produces". ✅
- **Task 001 Expects ← existing codebase**: `HomeScreen` exists without a `bottomNavigationBar`; `lucide_icons_flutter` is in `pubspec.yaml`; Feature 001 populated `ColorScheme` tokens. All verifiable today. ✅
- **Task 002 Produces → spec ACs**: `flutter test` + `flutter build apk --debug` + the 5 test cases directly satisfy AC-8 / AC-10 / AC-11 and provide final verification of AC-1..AC-7. ✅
- **No orphaned Produces, no unsatisfied Expects.** ✅

## AC Coverage Matrix

| AC | Covered by |
|----|------------|
| AC-1 Scaffold slot | Task 001 |
| AC-2 Three destinations in order | Task 001 + verified by Task 002 case 1 |
| AC-3 Lucide icons | Task 001 + verified by Task 002 case 2 |
| AC-4 selectedIndex == 0 on first render | Task 001 + verified by Task 002 case 3 |
| AC-5 Tap is a no-op | Task 001 + verified by Task 002 case 4 |
| AC-6 Light/dark via ColorScheme | Task 001 (no hard-coded colors) |
| AC-7 alwaysShow labels | Task 001 + verified by Task 002 case 5 |
| AC-8 Widget test exists | Task 002 |
| AC-9 `dart analyze` clean | Task 001 Done-when + Task 002 Done-when |
| AC-10 `flutter test` passes | Task 002 Done-when |
| AC-11 `flutter build apk --debug` succeeds | Task 002 Done-when |
| AC-12 No domain/data files touched | Task 001 Produces (explicit) |

All 12 acceptance criteria are covered.
