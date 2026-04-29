# Tasks: Language Settings

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-04-27
**Total tasks**: 5
**Status**: All tasks Complete — feature verified ([verify.md](../verify.md))

## Dependency Graph

```
001 (domain) ──→ 002 (data) ──→ 003 (notifier + wiring) ──→ 004 (l10n + UI) ──→ 005 (tests)
        │                              ▲
        └──────────────────────────────┘  (003 also depends transitively on 001 via AppLanguage import)
```

Linear chain. No parallelism opportunities — every step strictly extends the contracts produced by its predecessor.

## Task Index

| # | Title | Agent | Depends on | Status |
|---|---|---|---|---|
| 001 | Extend domain layer with AppLanguage enum, AppSettings fields, and repository contract | architect | None | Complete |
| 002 | Extend data layer with language persistence | architect | 001 | Complete |
| 003 | Extend SettingsNotifier and wire MaterialApp.locale | architect | 002 | Complete |
| 004 | Add localizations and build LanguageSelector + Settings screen section | mobile-engineer | 003 | Complete |
| 005 | Write feature tests (terminal integration gate) | qa-engineer | 004 | Complete |

## Additions to Spec

One discovery during breakdown:

- **`test/widget_test.dart` extension instead of new `test/app_test.dart`**: The existing app-level test file (`test/widget_test.dart`) already pumps `DoslyApp` under a `ProviderScope` with a `_FakeSettingsRepository` override. AC-12 (MaterialApp.locale reactivity) is more naturally an extension of that file than a parallel `app_test.dart`. The plan was updated to reflect this; spec is unchanged (the spec said "create or extend `test/app_test.dart` (or wherever `MaterialApp.locale` reactivity is asserted)" — the "or wherever" clause anticipated this).

No new files beyond what the spec listed in §4 (one creation — `language_selector.dart` widget + its test file — and additive extensions across all other affected files).

## Risk Assessment

| Task | Risk | Reason |
|---|---|---|
| 001 | Low | Pure additive domain extension. No existing API surface changes. |
| 002 | Low | Mechanical pattern extension (data source + repo impl mirror existing theme methods exactly). |
| 003 | Medium | Convergence point — three files change in lock-step (notifier + main allowList + app.dart locale wiring). A miss in any one of the three breaks end-to-end behaviour silently. **Review checkpoint placed here.** |
| 004 | Low-Medium | Largest file count (3 ARB + 4 regen + 1 NEW widget + 1 MOD screen). Codegen step adds variance. UI rendering needs visual verification at AC-18 manual gate. |
| 005 | Medium | Five test files touched — terminal integration gate runs the full `flutter test` + `flutter build apk --debug`. Any regression in the existing 117 tests surfaces here. **Review checkpoint placed here.** |

## Review Checkpoints

| Before Task | Reason | What to Review |
|---|---|---|
| 003 | Convergence (depends on 001 + 002) AND data → presentation layer crossing | Verify Tasks 001 + 002 produced exactly the contracts Task 003 expects: `AppLanguage` enum exists with `code`/`nativeName`; `AppSettings.copyWith` accepts the new params; `AppSettings.effectiveLocale` returns `Locale?`; `SettingsRepositoryImpl` implements both new save methods with the correct `Either` shape; `SettingsLocalDataSource` reads/writes both new keys with correct defaults. Particularly check: did anyone accidentally widen the data source's `as` casts when extending `getManualLanguage()`? |
| 005 | Terminal integration gate | Verify all earlier tasks didn't introduce silent breakage by running `flutter test` on the spec-009 baseline before extending the test files. Then verify the final test count (≥ 135) and that the new `MaterialApp.locale` reactivity test in `widget_test.dart` actually exercises the wiring rather than just asserting on the seeded fake state. |

## Contract Chain Integrity

Verified — every Produces is consumed by a downstream Expects or maps to a spec AC:

| Produces (from Task) | Consumed by | Or maps to AC |
|---|---|---|
| 001 → `AppLanguage` enum | 002, 003, 004, 005 | AC-1 |
| 001 → `AppSettings` new fields + `effectiveLocale` | 002, 003, 005 | AC-2 |
| 001 → `SettingsRepository` save method declarations | 002, 003 | AC-3 (declaration half) |
| 002 → `SettingsLocalDataSource` new methods + key constants | 003, 005 | AC-4 |
| 002 → `SettingsRepositoryImpl` extended `load()` + new save methods | 003, 005 | AC-3 (impl half) |
| 003 → `SettingsNotifier.setUseSystemLanguage` / `setManualLanguage` | 004, 005 | AC-6 |
| 003 → `main.dart` allowList extended | 004 (functional precondition), 005 (test fixtures) | AC-5 |
| 003 → `MaterialApp.router.locale: …` wiring | 004 (visual side effect), 005 (`widget_test.dart` AC-12 assertion) | AC-7 |
| 004 → ARB keys + generated `AppLocalizations` | 005 (screen tests reading localized strings) | AC-10 |
| 004 → `LanguageSelector` widget | 005 (widget tests) | AC-8 |
| 004 → Language section on Settings screen | 005 (screen tests) | AC-9 |
| 005 → Test files | — | AC-11, AC-12, AC-13, AC-14 |
| 005 → Final `flutter test` + `flutter build apk --debug` pass | — | AC-15, AC-16, AC-17 |

No orphans. No unsatisfied Expects.

## Spec AC Coverage

| AC | Task(s) |
|---|---|
| AC-1 (AppLanguage enum) | 001 |
| AC-2 (AppSettings fields + effectiveLocale) | 001 |
| AC-3 (Repository contract + impl) | 001 (contract), 002 (impl) |
| AC-4 (Data source methods) | 002 |
| AC-5 (allowList) | 003 |
| AC-6 (Notifier methods) | 003 |
| AC-7 (MaterialApp.locale wiring) | 003 |
| AC-8 (LanguageSelector widget) | 004 |
| AC-9 (Section header) | 004 |
| AC-10 (ARB keys + AppLocalizations) | 004 |
| AC-11 (LanguageSelector widget tests) | 005 |
| AC-12 (MaterialApp.locale reactivity) | 005 |
| AC-13 (existing tests pass) | 005 |
| AC-14 (persistence round-trip) | 005 |
| AC-15 (`dart analyze` clean) | 001-005 (per-task gate) |
| AC-16 (`flutter test` passes) | 005 (terminal gate) |
| AC-17 (`flutter build apk --debug`) | 005 (terminal gate) |
| AC-18 (manual on-device verification) | Deferred to user post-merge |
