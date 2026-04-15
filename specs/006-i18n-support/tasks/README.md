# Tasks: Multi-Language Support (English, German, Ukrainian)

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Review**: [../review.md](../review.md)
**Generated**: 2026-04-14
**Verified**: 2026-04-15
**Total tasks**: 7 (all Complete)
**Status**: Complete — 12 of 12 auto-verifiable ACs PASS; AC-13 deferred to user manual on-device check.

## Dependency Graph

```
001 (ARB files)
  └──→ 002 (deps + l10n config + codegen)
         └──→ 003 (wire MaterialApp delegates)
                ├──→ 004 (localize HomeScreen)
                ├──→ 005 (update existing nav test harness)
                │      └──→ 006 (localize HomeBottomNav)
                │             └──→ 007 (add locale-switching tests)
```

## Task Index

| # | Title | Agent | Depends on | Review checkpoint | Status |
|---|-------|-------|------------|-------------------|--------|
| 001 | Create ARB translation files | mobile-engineer | None | No | Complete |
| 002 | Install deps + configure l10n + generate `AppLocalizations` | architect | 001 | **Yes** — high risk | Complete |
| 003 | Wire `MaterialApp.router` with i18n delegates | mobile-engineer | 002 | **Yes** — layer crossing | Complete |
| 004 | Localize `HomeScreen` literals | mobile-engineer | 003 | No | Complete |
| 005 | Register delegates in `home_bottom_nav_test` harness | qa-engineer | 003 | No | Complete |
| 006 | Localize `HomeBottomNav` destination labels | mobile-engineer | 003, 005 | No | Complete |
| 007 | Add locale-switching widget tests for `HomeBottomNav` | qa-engineer | 006 | **Yes** — final verification convergence | Complete |

## Additions to Spec

- **`pubspec.lock` is modified and committed** as part of Task 002. The spec's §4 "Affected Areas" table omits `pubspec.lock`; it's an automatic consequence of `flutter pub add`. Flagged for completeness.
- **Generated `AppLocalizations` files at `lib/l10n/app_localizations*.dart` are committed to Git** per the plan's `synthetic-package: false` decision. This diverges from spec §4's last row which says generated files live under `.dart_tool/` and are not committed. The plan is authoritative; task 002 commits these files.

## Scope changes mid-breakdown

- **`helloWorld` dropped from translation scope** (user decision during `/breakdown`). Originally the spec listed 5 translatable keys; now 4. Rationale: `HomeScreen`'s `'Hello World'` body is a temporary placeholder that will be replaced wholesale when the real Today content ships — translating a placeholder is wasted work, analogous to the pre-existing `'Theme preview'` exclusion. Spec §1, §2 (count + row), §3.3, §3.4, §4, §5 (AC-3/4/6/13), and §6 have been updated; the plan's summary, constitution-compliance, and File Impact sections follow. `/verify` will see four keys, not five.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Pure data files; no code impact; easily editable if a translation is wrong |
| 002 | **High** | Dependency resolution (`intl: any` could conflict with Flutter SDK's pinned version); codegen must produce valid Dart; commits include auto-generated files that must be reviewed |
| 003 | Medium | Layer-crossing integration change; first time `AppLocalizations` is imported into app code; mistakes here surface as runtime nulls everywhere |
| 004 | Low | Mechanical literal replacement in 2 spots |
| 005 | Low | Harness-only change; existing English assertions must still pass |
| 006 | Low | Mechanical literal replacement in 3 spots; widget const-ness edge already understood per MEMORY.md |
| 007 | Low | New test file; no impact on existing code; direct AC-9 coverage |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 002 | High-risk (dep resolution + codegen); spec-to-plan drift applies here | Verify ARB JSON is valid and keys match across locales; confirm no typos in Ukrainian/German before codegen runs |
| 003 | Layer boundary crossing (first presentation task consuming generated code) | Verify `flutter pub get` produced compilable `app_localizations*.dart` under `lib/l10n/`; confirm `dart analyze` is clean; confirm `AppLocalizations` exposes all four getters (`settingsTooltip`, `bottomNavToday`, `bottomNavMeds`, `bottomNavHistory`) |
| 007 | Convergence point (depends on 006 + AC-8/9/11 coverage) | Verify `flutter test` passes all 84 existing + new locale tests; verify `flutter build apk --debug` succeeds |

## Contract Chain Integrity

Verified: every task's `Produces` is consumed by a downstream `Expects` or maps directly to a spec AC. Every task's `Expects` traces to an upstream `Produces` or current codebase state (verified by reading `lib/app.dart`, `home_screen.dart`, `home_bottom_nav.dart`, `home_bottom_nav_test.dart` at plan time).

No contract orphans.

## Acceptance Criteria Coverage

| AC | Covered by Task(s) |
|----|--------------------|
| AC-1 (deps + `generate: true` in pubspec) | 002 |
| AC-2 (`l10n.yaml` exists with correct keys) | 002 |
| AC-3 (three ARB files with four keys + `@key` metadata in en) | 001 |
| AC-4 (generated `AppLocalizations` importable with four getters) | 002 |
| AC-5 (`MaterialApp.router` wired with delegates) | 003 |
| AC-6 (HomeScreen `'Settings'` tooltip replaced) | 004 |
| AC-7 (HomeBottomNav three labels replaced; outer const preserved) | 006 |
| AC-8 (all 84 existing tests pass) | 005 (harness), verified via 006's post-execution test run |
| AC-9 (new de/uk/fr-fallback widget tests) | 007 |
| AC-10 (`dart analyze` clean) | Enforced by PostToolUse hook on every task + final in 007 |
| AC-11 (`flutter test` clean) | Enforced by `/execute-task` verification on every task + explicit in 007 |
| AC-12 (`flutter build apk --debug` succeeds) | Enforced by `/execute-task` verification on every task + final in 007 |
| AC-13 (manual on-device verification) | Deferred to user post-merge per spec; no code deliverable |
