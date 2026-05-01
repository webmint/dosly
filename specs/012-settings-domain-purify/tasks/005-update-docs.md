### Task 005: Update `docs/features/settings.md` and `docs/architecture.md`

**Agent**: tech-writer
**Files**:
- `docs/features/settings.md` (modify)
- `docs/architecture.md` (modify — small addition)
- `docs/features/i18n.md` (modify — addendum 2026-04-30 after Task 005 review surfaced 3 stale `AppSettings.effectiveLocale` references presented as current API; constitution §6.4 mandates the doc update because the underlying behavior changed in this spec)

**Depends on**: 003
**Blocks**: None
**Context docs**: None (this task IS the doc update)
**Review checkpoint**: No

**Description**:
Update the project documentation to match the new shape produced by Task
003. Two docs need touching:

1. **`docs/features/settings.md`** — the "Domain" section (lines 11–53)
   currently describes the old shape: `manualThemeMode: ThemeMode`,
   `effectiveThemeMode` getter, `effectiveLocale` getter. The persistence
   table at lines 156–161 already documents `String 'light'`/`'dark'` —
   no change there (the spec restored the contract the doc already
   documented; this task confirms doc and code now agree).

2. **`docs/architecture.md`** — the pull-quote at line 23 says spec 009
   was the first full Clean-Architecture stack. Add a brief note that
   spec 012 made the settings domain truly Flutter-free (eliminated the
   §2.1 violation that had persisted since 009 — even though the
   architecture doc itself stated the rule).

This task can run in parallel with Task 004 (different files, no shared
contract). Sequencing it after Task 003 is sufficient.

**Change details**:

- In `docs/features/settings.md`:
  - Lines 13–21 (entity table): Change the `manualThemeMode` row's "Type"
    from `ThemeMode.light` (current row implies type is `ThemeMode`) to
    `AppThemeMode.light` (new domain enum). Add a brief sentence after
    the table explaining `AppThemeMode` is a domain-owned enum (with
    pointer to `lib/features/settings/domain/entities/app_theme_mode.dart`)
    and lives alongside `AppLanguage` for the same reason.
  - Lines 22–34 (the `effectiveThemeMode`/`effectiveLocale` code samples):
    REMOVE the two getter code samples. Replace with a paragraph titled
    "Presentation seam" describing how `lib/app.dart` watches the four
    raw fields via `.select(...)` and computes `MaterialApp.themeMode`
    and `MaterialApp.locale` inline — with a code sample showing the new
    seam shape (the four `ref.watch` calls plus the `_toFlutterThemeMode`
    helper).
  - Line 50 ("`saveThemeMode(ThemeMode)`"): change to
    `saveThemeMode(AppThemeMode)`.
  - Lines 156–161 (persistence table): **NO CHANGE**. The table already
    documents `themeMode | String ('light' / 'dark') | 'light'` — this
    spec restores the documented contract; the doc is now correct and
    matches the code.
  - Lines 65–73 (the `setUseSystemTheme` code sample showing the
    optimistic-write pattern): The code is illustrative, not literal —
    if it references `ThemeMode`, update to `AppThemeMode`. Otherwise
    leave alone.
  - Lines 91–97 (ThemeSelector pre-fill code sample): change
    `ThemeMode.dark`/`ThemeMode.light` to `AppThemeMode.dark`/`AppThemeMode.light`.

- In `docs/architecture.md`:
  - After line 23 (the existing pull-quote about spec 009), add a sibling
    blockquote:
    > Spec `012-settings-domain-purify` (2026-04-30) made the constitution
    > §2.1 layering rule actually true for the settings feature: domain
    > and data layers are now free of `package:flutter/*` imports. The
    > Flutter↔domain mapping (e.g., `AppThemeMode → ThemeMode`) is
    > confined to the presentation seam in `lib/app.dart`.
  - No other change needed in this file.

**Done when**:
- [x] `docs/features/settings.md` "Domain" section references
      `AppThemeMode` instead of `ThemeMode` in entity table, prose, and
      code samples.
- [x] `docs/features/settings.md` no longer documents `effectiveThemeMode`
      or `effectiveLocale` as getters on `AppSettings`. Replaced with a
      "Presentation seam" subsection describing the new shape.
- [x] `docs/features/settings.md` persistence table at lines ~156–161
      is unchanged (still documents `String 'light'/'dark'` — was already
      correct).
- [x] `docs/architecture.md` has a new pull-quote referencing spec 012
      and the §2.1 rule resolution.
- [x] All cross-doc links in `docs/features/settings.md` (Related section
      at the bottom) remain valid — no broken links.

**Spec criteria addressed**: AC-15

## Completion Notes
**Status**: Complete
**Completed**: 2026-04-30
**Files changed**: docs/features/settings.md (Domain section + AppThemeMode paragraph + Presentation seam subsection + repository contract method + ThemeSelector pre-fill sample + SegmentedButton type parameter), docs/features/i18n.md (3 stale `effectiveLocale` rewrites — added in addendum after first review caught the staleness), docs/architecture.md (spec-012 pull-quote + DoslyApp code sample update + allowList snippet expansion to all 4 current keys)
**Contract**: Expects 3/3 verified | Produces 4/4 verified
**Notes**:
- First review verdict: REQUEST CHANGES with two Critical findings — (C1) `SegmentedButton<ThemeMode>` should be `SegmentedButton<AppThemeMode>` in `settings.md:98`; (C2) `docs/features/i18n.md` had 3 stale `AppSettings.effectiveLocale` references presented as current API. Task scope amended in-place to include `i18n.md` per constitution §6.4 ("update doc when behavior changes").
- Re-review verdict: APPROVE — both Criticals fully resolved; allowList snippet adjacent-warning also fixed; zero remaining `effectiveThemeMode`/`effectiveLocale` references anywhere in `docs/` (other than one explicit negation at `settings.md:26`).
- Post-fix: `dart analyze` clean; `flutter test` 196/196 still passing; no source files touched.
- The i18n.md fix is a constitution §6.4-driven scope expansion that the original task's Files list missed. The amendment is documented in the task file's Files section header.

## Contracts

### Expects
- Task 003 produced: source files now have the new shape
  (`AppThemeMode` everywhere, no Flutter import in domain/data, no
  `effectiveThemeMode`/`effectiveLocale` getters, four `.select()` calls
  in `lib/app.dart`).
- `docs/features/settings.md` exists with the existing content.
- `docs/architecture.md` exists with the existing content.

### Produces
- `docs/features/settings.md` references `AppThemeMode` (new occurrences)
  and does NOT contain the literal strings `effectiveThemeMode` or
  `effectiveLocale` (those getters are removed from the entity).
- `docs/features/settings.md` has a "Presentation seam" subsection (or
  equivalent prose) describing the four `.select()` calls in `lib/app.dart`.
- `docs/features/settings.md` "Persistence" table still documents
  `themeMode | String ('light' / 'dark') | 'light'` — unchanged.
- `docs/architecture.md` references spec 012 in a pull-quote describing
  the §2.1 resolution.
