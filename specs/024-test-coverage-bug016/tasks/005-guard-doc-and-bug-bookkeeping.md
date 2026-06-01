# Task 005: Document language_selector guard + update Bug 016 record

**Agent**: tech-writer
**Files**:
- `lib/features/settings/presentation/widgets/language_selector.dart`
- `bugs/016-test-coverage-gaps-consolidated.md`
**Status**: Complete
**Depends on**: 001, 002, 003, 004
**Blocks**: None
**Context docs**: None
**Review checkpoint**: Yes

## Completion Notes

**Completed**: 2026-05-27
**Files changed**: lib/features/settings/presentation/widgets/language_selector.dart (1 comment, 3 lines), bugs/016-test-coverage-gaps-consolidated.md (Status: Fixed + Resolution section)
**Contract**: Expects [2/2 verified] | Produces [2/2 verified]
**Notes**: Guard kept + documented (no `!`, per Never #7). Bug 016 Status set to
Fixed with a per-sub-item Resolution section (1,2,10 fixed w/ catch-branch caveat;
3 fixed; 9 fixed + 7-way-not-4-way note; 8 documented; 4,7 already-closed; 5,6
moot). Code review APPROVE-with-warnings: split the overlong 183-char comment into
3 lines. Final feature verification: `dart analyze` clean, full suite 261 passed.

**Description**:
Two documentation-only changes that close out the feature. (1) Bug 016 sub-item
8: document the `if (selected != null)` defensive guard in
`language_selector.dart` — keep it, do NOT introduce a `!` (constitution Never
#7). (2) Bug 016 sub-item 9 / AC-9: update the bug record to reflect reality
now that the tests exist. This task is last (depends on 001-004) so the bug
file accurately marks the work done. Convergence + presentation-layer `lib/`
edit → review checkpoint.

**Change details**:
- In `lib/features/settings/presentation/widgets/language_selector.dart`, at the `if (selected != null)` guard inside `DropdownButton<AppLanguage>.onChanged` (~line 81), add a single `//` line above it, e.g.:
  `// DropdownButton.onChanged is typed ValueChanged<T?> but only ever fires with a non-null value on selection; the guard is defensive, not reachable via the UI.`
  Do not change the guard logic. No `!`.
- In `bugs/016-test-coverage-gaps-consolidated.md`:
  - Set `**Status**: Fixed` and `**Fixed**: 2026-05-27 (spec 024)`.
  - Annotate each sub-item: 1, 2, 3, 8, 9, 10 → Fixed (spec 024, with the test file that closes it); 4 & 7 → already-closed (note the existing test files); 5 & 6 → Moot (theme_preview removed in spec 020).
  - Keep edits surgical — append status annotations, do not rewrite the original Evidence section.

**Done when**:
- [ ] `language_selector.dart` retains the `if (selected != null)` guard with a new `//` comment; no `!` was added (`grep "selected!" ` finds nothing new).
- [ ] `bugs/016-test-coverage-gaps-consolidated.md` Status is `Fixed` with a Fixed date, and all 10 sub-items are annotated (fixed / already-closed / moot).
- [ ] `dart analyze` passes on `language_selector.dart`.
- [ ] `flutter test` still passes (no behavior change).

**Spec criteria addressed**: AC-8, AC-9

## Contracts

### Expects
- The three new test files (Tasks 001-003) and the harness dedup (Task 004) are complete, so the bug record's "Fixed" claims are accurate.
- `lib/features/settings/presentation/widgets/language_selector.dart` contains `if (selected != null)` inside `DropdownButton<AppLanguage>.onChanged`.

### Produces
- `language_selector.dart` has a `//` comment immediately preceding the `if (selected != null)` guard, and still contains that guard (no `!`).
- `bugs/016-test-coverage-gaps-consolidated.md` contains `**Status**: Fixed` and a per-sub-item disposition for all 10 items.
