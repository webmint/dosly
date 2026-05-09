### Task 004: Update `docs/architecture.md` and close bug 004

**Agent**: tech-writer
**Files**:
- `docs/architecture.md` (modify — rename existing `settingsProvider` references; refresh provider-wiring table; add codegen-invocation paragraph)
- `bugs/004-manual-providers-missing-riverpod-codegen.md` (modify — flip status to Fixed; add cross-reference to spec 015)

**Depends on**: 001, 002, 003
**Blocks**: None (final task)
**Context docs**: `docs/architecture.md` (the file being edited — read it first to see current shape)
**Review checkpoint**: Yes (final convergence — gates the feature for `/review` → `/verify`; documentation must match the post-migration source code state)

**Description**:

Bookkeeping after the source-edit chain. Two responsibilities:

1. **Sync `docs/architecture.md` with the post-migration codebase**. The doc currently references the manual `settingsProvider` symbol in 8 places (verified by `grep -n "settingsProvider" docs/architecture.md`):
   - Line 30: prose ("through narrow `ref.watch(settingsProvider.select(...))` calls")
   - Line 56: prose ("It watches `settingsProvider` with four narrow selectors")
   - Lines 66, 69, 72, 75: code snippet (`settingsProvider.select(...)` × 4)
   - Line 126: provider-wiring table row (`settingsProvider | NotifierProvider<SettingsNotifier, AppSettings> | ...`)
   - Line 145: prose ("All theme-mode state is now owned by `settingsProvider`.")

   All 8 occurrences need rename to `settingsNotifierProvider` to keep documentation honest with the source. Additionally, the provider-wiring table at lines 122-126 documents the manual `Provider<...>` / `NotifierProvider<...>` types — these are now codegen-emitted, so the Type column needs updating to reflect the `@riverpod` form (e.g., "`@Riverpod(keepAlive: true)` function" / "`@riverpod` class form").

   Also add a brief paragraph (2-4 sentences) under the Riverpod section that:
   - Notes the codegen invocation: `dart run build_runner build --delete-conflicting-outputs`.
   - Points to `lib/core/providers/shared_preferences_provider.dart` and `lib/features/settings/presentation/providers/settings_provider.dart` as the canonical exemplars for future feature work.
   - References constitution §6.6 (workflow rule for `@riverpod`/`freezed` codegen).
   - Notes that generated `*.g.dart` files are committed (per §2.2).

2. **Close bug 004**: Flip front-matter `Status: Open` → `Status: Fixed`, set `Fixed: 2026-05-08` (or actual completion date), and add a cross-reference back to `specs/015-riverpod-codegen/` so future audits can trace the fix.

   The bug file's "Fix Notes" section is now historical — leave it as-is, but add a short "Resolution" subsection at the bottom pointing to spec 015 and noting that all four manual providers (the original three plus `settingsErrorsProvider` from feature 014) are now codegen-emitted.

**Change details**:

In `docs/architecture.md`:
- Rename all 8 `settingsProvider` occurrences (without word-boundary issues — only the standalone `settingsProvider` symbol, NOT `settingsRepositoryProvider` or `settingsErrorsProvider`). Use word-boundary regex if doing this with sed: `\bsettingsProvider\b`.
- Update the "Provider wiring" table at lines 122-126:
  - Row 1 (`sharedPreferencesProvider`): change Type column from `Provider<SharedPreferencesWithCache>` to `@Riverpod(keepAlive: true)` (function form). Purpose column unchanged.
  - Row 2 (`settingsRepositoryProvider`): change Type column from `Provider<SettingsRepository>` to `@riverpod` (function form). Purpose column unchanged.
  - Row 3 (`settingsProvider`): change Name column to `settingsNotifierProvider`; change Type column from `NotifierProvider<SettingsNotifier, AppSettings>` to `@riverpod` (class form). Purpose column unchanged.
  - Add a new row 4 for `settingsErrorsProvider`: Type `@riverpod` (function form, autoDispose), Purpose "Broadcast stream of persistence failures from `SettingsNotifier` (feature 014).". (This row is missing from the current table — its absence pre-dates feature 014.)
- Add a new paragraph (2-4 sentences) after the existing Riverpod section content, before the next section ("Failure handling"):
  - Topic: Riverpod codegen workflow.
  - Content: identify the `dart run build_runner build --delete-conflicting-outputs` invocation, point to the two provider files as exemplars, link to constitution §6.6 and §2.2.
  - Tone: matches existing prose (terse, declarative, no list bullets unless natural).

In `bugs/004-manual-providers-missing-riverpod-codegen.md`:
- Front matter: `Status: Open` → `Status: Fixed`. `Fixed:` → `Fixed: 2026-05-08`.
- Append a "Resolution" section at the end of the file:
  ```
  ## Resolution

  Closed by spec [015-riverpod-codegen](../specs/015-riverpod-codegen/). All
  four manual providers (the three original sites plus `settingsErrorsProvider`
  added by feature 014) are now `@riverpod` codegen-emitted. `pubspec.yaml`
  lists `riverpod_annotation` (runtime) and `riverpod_generator` (dev), and
  generated `*.g.dart` files are committed alongside their source files per
  constitution §2.2.
  ```

After edits:
- `dart analyze` — should already be clean from Task 003; this task changes only markdown, so no code surface.
- `flutter test` — should already be passing from Task 003; markdown-only edits cannot break tests.
- `grep -n "settingsProvider\b" docs/architecture.md` — expected: zero matches.
- `grep -c "settingsNotifierProvider" docs/architecture.md` — expected: ≥ 8 matches (the renamed occurrences plus the table row).

**Done when**:
- [x] `grep -rn "settingsProvider\b" docs/` returns zero matches (all docs renamed to `settingsNotifierProvider`).
- [x] `docs/architecture.md` provider-wiring table has 4 rows (added `settingsErrorsProvider`) and Type column reflects `@riverpod` / `@Riverpod(keepAlive: true)` codegen forms.
- [x] `docs/architecture.md` includes a `### Riverpod codegen` subsection documenting the codegen invocation (`dart run build_runner build --delete-conflicting-outputs`) and pointing to `shared_preferences_provider.dart` + `settings_provider.dart` as exemplars; also documents the `Notifier`-suffix-stripping quirk.
- [x] `bugs/004-manual-providers-missing-riverpod-codegen.md` front matter shows `Status: Fixed` and `Fixed: 2026-05-09`.
- [x] `bugs/004-manual-providers-missing-riverpod-codegen.md` has a `## Resolution` section linking to `specs/015-riverpod-codegen/spec.md`.
- [x] `dart analyze` continues to pass.
- [x] `flutter test` continues to pass (203/203).

**Spec criteria addressed**: AC-13, AC-14

## Completion Notes
**Status**: Complete
**Completed**: 2026-05-09
**Files changed**: 5 markdown files — `docs/architecture.md` (8 renames + table refresh + new subsection), `bugs/004-manual-providers-missing-riverpod-codegen.md` (front matter + Resolution section), `docs/features/i18n.md` (3 renames), `docs/features/settings.md` (5 renames), `docs/features/theme.md` (6 renames). Last three files were beyond the task's named scope but were edited on agent initiative to keep all `docs/` consistent — verified appropriate by code review (same `settingsProvider` symbol referenced across all four files; not editing them would have created the doc-vs-code drift the project flags as a pitfall).
**Contract**: Expects 4/4 verified | Produces 7/7 verified
**Notes**:
- Markdown link diagnostic surfaced after agent completion: `bugs/004-...md:73` had `[015-riverpod-codegen](../specs/015-riverpod-codegen/)` (trailing slash, no file). Fixed by orchestrator to `(../specs/015-riverpod-codegen/spec.md)`.
- Code review verdict: **APPROVE with warnings** → APPROVE after sanitization. Single warning was about "Riverpod 3.x" phrasing in two places (`docs/architecture.md:152`, `bugs/004-...md:86-87`) conflicting with constitution §1's stale "Riverpod 2.x" wording. Sanitized both to "canonical codegen class-form naming idiom" — version-neutral phrasing avoids the cross-doc conflict without rewriting the constitution (out of spec scope).
- Constitution §1 wording drift ("Riverpod 2.x" vs actual `flutter_riverpod ^3.3.1`) and §7.2 outdated example (uses 2.x `XxxRef` typedefs) remain Open as known follow-ups — explicitly out of scope per spec §6 "Out of Scope".
- `dart analyze`: clean. `flutter test`: 203/203 pass. No source code modified.
- All 14 acceptance criteria from the spec are now satisfied.

## Contracts

### Expects
- Tasks 001, 002, 003 are complete: source code is in its final post-migration state with all `settingsProvider` references in `lib/` and `test/` already renamed to `settingsNotifierProvider`.
- `docs/architecture.md` exists and currently references `settingsProvider` in 8 places (lines 30, 56, 66, 69, 72, 75, 126, 145).
- `bugs/004-manual-providers-missing-riverpod-codegen.md` exists with front-matter `Status: Open` and an empty `Fixed:` field.
- The grep `grep -rn "settingsProvider\b" lib/ test/` returns zero matches (Task 003's verification).

### Produces
- `grep -rn "settingsProvider\b" docs/` returns zero matches.
- `docs/architecture.md` contains at least one literal occurrence of the string `settingsNotifierProvider`.
- `docs/architecture.md` contains at least one literal occurrence of the string `dart run build_runner build` (the codegen invocation paragraph).
- `docs/architecture.md` provider-wiring table contains a row whose Name cell is the literal string `` `settingsErrorsProvider` ``.
- `bugs/004-manual-providers-missing-riverpod-codegen.md` front matter contains the literal lines `Status: Fixed` and `Fixed: 2026-05-08` (or actual date).
- `bugs/004-manual-providers-missing-riverpod-codegen.md` contains a heading `## Resolution`.
- `dart analyze` and `flutter test` remain green.
