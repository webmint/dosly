# Tasks: Surface Settings Persistence Errors

**Spec**: `specs/014-surface-settings-errors/spec.md`
**Plan**: `specs/014-surface-settings-errors/plan.md`
**Generated**: 2026-05-07
**Total tasks**: 4
**Status**: All tasks Complete (4/4) | Verified 2026-05-08 — all 16 ACs PASS, all gates green, APPROVED

## Dependency Graph

```
001 (i18n: ARB + gen-l10n) ──┐
                             ├──→ 003 (screen + SnackBar + widget test) ──→ 004 (bug close + docs)
002 (provider + unit tests) ─┘
```

Tasks 001 and 002 are independent — they can be reasoned about and executed
in either order. Task 003 is the convergence + integration-gate task. Task
004 is pure bookkeeping after the source-edit chain is complete.

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Add `settingsPersistenceError` ARB key in en/de/uk | mobile-engineer | None | Complete |
| 002 | Add error stream to `SettingsNotifier` + `settingsErrorsProvider` + unit tests | mobile-engineer | None | Complete |
| 003 | Convert `SettingsScreen` to `ConsumerWidget` + listen for errors + show SnackBar | mobile-engineer | 001, 002 | Complete |
| 004 | Update settings doc, architecture doc, and close bug 003 | tech-writer | 001, 002, 003 | Complete |

## Additions to Spec

- `docs/architecture.md` — added in Task 004. Not in spec §4 Affected Areas;
  noted in plan §"Documentation Impact" and plan §"Plan-Spec Cross-Reference
  Check". Single-paragraph addition documenting the side-channel
  error-stream pattern for future feature reuse. User can drop this from
  Task 004 if they prefer to keep `docs/architecture.md` untouched in this
  spec.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Mechanical i18n edit. `flutter gen-l10n` validates structurally. The new key follows the established `settingsX` naming convention. |
| 002 | Med | First `StreamController` in the codebase. Lifecycle (broadcast + onDispose) is the main risk surface — a leaked or wrongly-scoped controller would surface as Riverpod analyzer warnings or as test-teardown hangs. Mitigated by explicit `ref.onDispose` and the existing `tearDown(() { container.dispose(); })` in the test file. |
| 003 | Med | First `ref.listen` + first `SnackBar` + first `ConsumerWidget` conversion of an existing `StatelessWidget` in this codebase. Integration-gate task (full `flutter test` + `flutter build apk --debug`). The widget test must use `pump` not `pumpAndSettle` for the SnackBar enter animation (called out in the task file). |
| 004 | Low | Pure markdown edits. Front matter flip + 1-paragraph doc addition + section rewrite. No compile or test surface. |

## Review Checkpoints

| Before Task | Reason | What to Verify |
|-------------|--------|----------------|
| 003 | Convergence point (depends on 001 + 002). First `ref.listen` + first `SnackBar` integration. | (a) `context.l10n.settingsPersistenceError` compiles (Task 001 produced); (b) `settingsErrorsProvider` exported from `settings_provider.dart` (Task 002 produced); (c) Task 002's 6 new unit tests pass. |
| 004 | Convergence point (depends on 001, 002, 003). Last task — gates the feature for `/review` → `/verify`. | (a) `flutter test` passes; (b) the SnackBar widget test in Task 003 passes; (c) source code is final (no pending edits). |

## Contract Chain Integrity

- **Task 001 Produces** → consumed by Task 003 Expects: `context.l10n.settingsPersistenceError` resolves to a String. ✓
- **Task 002 Produces** → consumed by Task 003 Expects: `settingsErrorsProvider` exported as `StreamProvider<Failure>`. ✓
- **Task 002 Produces** → maps to spec ACs 1, 2, 3, 4, 6, 7. ✓
- **Task 003 Produces** → consumed by Task 004 Expects: source implementation complete. ✓
- **Task 003 Produces** → maps to spec ACs 9, 10, 11, 13, 14. ✓
- **Task 004 Produces** → maps to spec ACs 15, 16. ✓
- **No orphaned Produces**, **no unsatisfied Expects**.

## Spec Acceptance Criteria Coverage

| AC | Task(s) |
|----|---------|
| AC-1 (Stream + controller + onDispose) | 002 |
| AC-2 (saveThemeMode failure emits) | 002 |
| AC-3 (other 3 mutators emit) | 002 |
| AC-4 (Right does NOT emit) | 002 |
| AC-5 (state-not-updated-on-failure preserved) | 002 (existing tests preserved) |
| AC-6 (zero debugPrint/print/log) | 002 (regression guard) |
| AC-7 (deferral comments removed) | 002 |
| AC-8 (ARB key in 3 locales + gen-l10n clean) | 001 |
| AC-9 (SnackBar on emission) | 003 |
| AC-10 (SnackBar floating + verbatim localized text) | 003 |
| AC-11 (ConsumerWidget + body unchanged) | 003 |
| AC-12 (dart analyze passes) | 002, 003 |
| AC-13 (flutter test passes) | 003 |
| AC-14 (flutter build apk --debug passes) | 003 |
| AC-15 (bug 003 front matter Closed) | 004 |
| AC-16 (docs/features/settings.md updated) | 004 |

All 16 ACs are covered by at least one task.
