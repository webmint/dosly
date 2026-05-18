# Task 003: Close bug 008 and document the error screen in `docs/architecture.md`

**Agent**: tech-writer
**Files**:
- `bugs/008-approuter-no-errorbuilder.md` (modify — mark Fixed, add Resolution section)
- `docs/architecture.md` (modify — add one bullet under §"Routing" → "Conventions")

**Depends on**: 002
**Blocks**: None (final task)
**Context docs**: None (the task description is self-contained — the bug file and the architecture section are both short and read fully during execution)
**Review checkpoint**: No

## Description

Documentation + bookkeeping closure. The behavior shipped in Task 002 is now observable in the codebase; this task records the closure of `bugs/008-approuter-no-errorbuilder.md` and adds one architecture-doc bullet documenting the new convention.

The bullet describes *behavior* (renders outside the shell, "Go to home" recovery), not *implementation rationale* — per MEMORY L192 / bug 012, rationale paragraphs in architecture docs rot fast and should not be introduced where a behavior-only line suffices.

## Change details

### `bugs/008-approuter-no-errorbuilder.md`

1. Change the `**Status**` line from `**Status**: Open` to `**Status**: Fixed`.
2. Change the `**Fixed**:` line (currently empty) to `**Fixed**: 2026-05-18`.
3. Append a new `## Resolution` section at the end of the file:
   ```markdown
   ## Resolution

   Fixed by spec 019 (`specs/019-router-error-screen/`).

   - `lib/core/routing/app_router.dart` now sets `errorBuilder: (context, state) => const _RouterErrorScreen()` on the `GoRouter` constructor.
   - `_RouterErrorScreen` is a private `StatelessWidget` in the same library. It renders a localized `Scaffold` (title, body, "Go to home" `FilledButton`) using `context.l10n`. The `FilledButton.onPressed` calls `context.go('/')`.
   - Three ARB keys (`errorScreenTitle`, `errorScreenBody`, `errorScreenGoHome`) added to `app_en.arb`, `app_de.arb`, `app_uk.arb` and codegen regenerated `lib/l10n/app_localizations*.dart`.
   - `test/core/routing/app_router_test.dart` adds Test 7 which pushes `/nonexistent`, asserts the error screen renders without `AppBottomNav`, and verifies the "Go to home" button recovers to `HomeScreen`.
   ```

### `docs/architecture.md`

Locate §"Routing" → "Conventions" (currently 5 bullets at lines 247–251). Add one new bullet at the end of the list (after the `AppBottomNav is router-agnostic` bullet):

```markdown
- **Unmatched paths render a localized error screen.** `appRouter.errorBuilder` produces a private `_RouterErrorScreen` (in `lib/core/routing/app_router.dart`) that shows a localized title/body and a "Go to home" `FilledButton` calling `context.go('/')`. This is the recovery path for malformed deep links and future notification-action payloads (constitution §5.2). The screen renders outside the `StatefulShellRoute`, so no `AppBottomNav` is visible.
```

No other section of `docs/architecture.md` is modified.

## Contracts

### Expects
- `lib/core/routing/app_router.dart` contains `errorBuilder:` and `class _RouterErrorScreen extends StatelessWidget` (from Task 002 Produces).
- `bugs/008-approuter-no-errorbuilder.md` exists with `**Status**: Open` and an empty `**Fixed**:` line (existing).
- `docs/architecture.md` exists with `### Conventions` at line 245 under `## Routing`, currently containing 5 bullets (existing — last touched by spec 018).

### Produces
- `bugs/008-approuter-no-errorbuilder.md` contains the literal lines `**Status**: Fixed` and `**Fixed**: 2026-05-18`.
- `bugs/008-approuter-no-errorbuilder.md` ends with a `## Resolution` section referencing `specs/019-router-error-screen/`.
- `docs/architecture.md` §"Routing" → "Conventions" contains a bullet whose first sentence is `**Unmatched paths render a localized error screen.**`.
- `docs/architecture.md` contains the literal phrase `appRouter.errorBuilder` exactly once.

## Done when

- [x] `grep -c "^\\*\\*Status\\*\\*: Fixed" bugs/008-approuter-no-errorbuilder.md` returns `1`.
- [x] `grep -c "^\\*\\*Fixed\\*\\*: 2026-05-18" bugs/008-approuter-no-errorbuilder.md` returns `1`.
- [x] `grep -c "^## Resolution" bugs/008-approuter-no-errorbuilder.md` returns `1`.
- [x] `grep -c "Unmatched paths render a localized error screen" docs/architecture.md` returns `1`.
- [x] `grep -c "appRouter.errorBuilder" docs/architecture.md` returns `1`.
- [x] `dart analyze` clean (`No issues found!`).
- [x] `flutter test test/core/routing/app_router_test.dart` exits 0 (7/7 still pass).

**Spec criteria addressed**: AC-14, AC-15

## Completion Notes

**Status**: Complete
**Completed**: 2026-05-18
**Files changed**:
- `bugs/008-approuter-no-errorbuilder.md` — Status: Open → Fixed; Fixed: 2026-05-18; `## Resolution` section appended
- `docs/architecture.md` — 6th bullet appended to §"Routing" → "Conventions" (existing 5 bullets untouched)

**Contract**: Expects 3/3 verified | Produces 4/4 verified
**Code review**: APPROVE (zero Critical/Warning; 6/6 review checks pass — bullet describes behavior with constitution-anchor reference; existing bullets preserved verbatim; Resolution section accurately reflects Tasks 001+002)
**Notes**: No surprises. The MEMORY L192 / bug 012 lesson (rationale paragraphs rot) was the load-bearing constraint and the bullet stayed on the behavior side of the line with constitution §5.2 as the stable contract anchor.
