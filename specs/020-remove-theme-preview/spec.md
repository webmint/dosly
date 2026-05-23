# Spec: Remove theme_preview feature

**Date**: 2026-05-22
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

Delete the dev-only `theme_preview` feature and every hook that reaches it. The
`ThemePreviewScreen` was always disposable scaffolding for validating the M3
design system during early development; it boots no real flow and is reachable
only via a temporary dev button. Removing it closes **Bug 009** (a Constitution
§2.1 cross-feature import violation) by deleting the offending file outright
rather than reworking it. This is the post-MVP cleanup explicitly deferred by
`specs/002-main-screen/spec.md §6`.

## 2. Current State

The feature lives in `lib/features/theme_preview/` (3 source files, no dedicated
test files):
- `presentation/screens/theme_preview_screen.dart` — the screen.
- `presentation/widgets/color_swatch_card.dart` — palette swatch card.
- `presentation/widgets/typography_sample.dart` — type-scale row.

**The Bug 009 violation** is in `theme_preview_screen.dart`. It has TWO
cross-feature imports into the Settings feature (Constitution §2.1 lines 71–72:
"A widget in `features/A/presentation/` may NOT import from `features/B/`"):
- Line 14: `import '../../../settings/domain/entities/app_theme_mode.dart';`
  (the unflagged second import — softer, but still §2.1).
- Line 15: `import '../../../settings/presentation/providers/settings_provider.dart';`
  (the flagged import — reaches Settings' deepest presentation layer and *writes*
  to it via `settingsNotifierProvider.notifier.cycleThemeMode()`).

**Hooks that reach the feature** (each carries a `TODO(post-mvp): remove`
already pointing at `specs/002-main-screen/spec.md §6 and §8`):
- `lib/core/routing/app_router.dart`:
  - Line 22: `import '...theme_preview/.../theme_preview_screen.dart';`
  - Lines 74–79: the `/theme-preview` `GoRoute` (top-level sibling, renders
    outside the `StatefulShellRoute`).
  - Lines 6–8: library dartdoc describes the `/theme-preview` sibling route.
- `lib/features/home/presentation/screens/home_screen.dart`:
  - Lines 58–64: the `OutlinedButton` ("Theme preview") + `context.push('/theme-preview')`
    + its `SizedBox(height: 24)` spacer + the `TODO(post-mvp)` comment.
  - Lines 20–27: class dartdoc describes the temporary button and the removal plan.
  - Note: `go_router` import (line 9) stays — `home_screen.dart` still calls
    `context.push('/settings')` at line 42.
- `lib/app.dart`:
  - Lines 10–13: library dartdoc mentions the "temporary dev-only `/theme-preview`
    route". `app.dart` does NOT import the screen (routing is delegated to
    `appRouterProvider`), so only the dartdoc text changes.

**Tests that reference the feature:**
- `test/widget_test.dart`:
  - First test (lines 65–85): asserts `find.widgetWithText(OutlinedButton, 'Theme preview')`
    (lines 79–82) and its name (line 66) mentions the button.
  - Second test (lines 87–126): navigates Home → Preview and cycles theme mode
    via the preview screen.
- `test/core/routing/app_router_test.dart`:
  - Line 29: `import '...theme_preview_screen.dart';`
  - Lines 286–313: Test 5 (AC-13) — `/theme-preview` renders without the shell
    bottom nav.
  - Line 3: file header comment mentions "/theme-preview rendering outside the shell".

**Theme-cycle coverage is NOT lost** by deleting the second widget test: the
`system → light → dark → system` cycle is independently covered by
`test/features/settings/domain/usecases/cycle_theme_mode_test.dart`,
`test/features/settings/presentation/providers/settings_provider_test.dart`,
`test/features/settings/presentation/screens/settings_screen_test.dart`, and
`theme_selector_test.dart`.

**Docs referencing the feature** (per `docs/`): `architecture.md` (lines 180,
198, 216), `overview.md` (line 24), `features/i18n.md` (lines 189–190),
`features/settings.md` (line 81), `features/home.md` (line 146),
`features/theme.md` (lines 83, 89, 116, 128), `features/icons.md` (lines 45, 51,
55, 57, 119, 125). Per the workflow, doc maintenance is handled by the
tech-writer agent at `/finalize` — see §6.

## 3. Desired Behavior

After this change:
1. `lib/features/theme_preview/` does not exist (all 3 files deleted; the
   directory is removed).
2. No source or test file imports anything from `lib/features/theme_preview/`.
3. The `/theme-preview` route does not exist in `app_router.dart`. The route
   table is: `/` (Home), `/meds`, `/history` (the shell branches), `/settings`
   (sibling), plus the `errorBuilder` fallback. No other routes.
4. `HomeScreen`'s body shows only the centered "Hello World" text — no "Theme
   preview" button, no trailing spacer, no dev TODO.
5. All library/class dartdoc that referenced the preview screen or the
   `/theme-preview` route is updated to reflect its removal (no dangling
   references to deleted code).
6. `test/widget_test.dart`'s first test no longer asserts the "Theme preview"
   button (the assertion and the button mention in its name are removed); its
   second test is deleted entirely.
7. `test/core/routing/app_router_test.dart` no longer imports `ThemePreviewScreen`,
   Test 5 (AC-13) is deleted, and the file header comment no longer mentions
   `/theme-preview`.
8. `bugs/009-cross-feature-import-theme-preview.md` is marked `Status: Fixed`
   with a resolution note.
9. `dart analyze` reports zero diagnostics; `flutter test` passes; the app builds.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Theme preview feature | `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | **Delete** |
| Theme preview feature | `lib/features/theme_preview/presentation/widgets/color_swatch_card.dart` | **Delete** |
| Theme preview feature | `lib/features/theme_preview/presentation/widgets/typography_sample.dart` | **Delete** (directory `lib/features/theme_preview/` removed) |
| Routing | `lib/core/routing/app_router.dart` | **Edit** — remove import (line 22), remove `/theme-preview` `GoRoute` (74–79) + its TODO comment, update library dartdoc (6–8) |
| Home screen | `lib/features/home/presentation/screens/home_screen.dart` | **Edit** — remove `OutlinedButton` + `SizedBox` spacer + TODO (56–64), update class dartdoc (20–27). Keep `go_router` import (still used for `/settings`) |
| App root | `lib/app.dart` | **Edit** — update library dartdoc (10–13) to drop the `/theme-preview` mention. No import/code change |
| Widget test | `test/widget_test.dart` | **Edit** — remove the "Theme preview" button assertion from test 1 (79–82) + its name mention (66); delete test 2 (87–126) |
| Routing test | `test/core/routing/app_router_test.dart` | **Edit** — remove `ThemePreviewScreen` import (29), delete Test 5 (286–313), update file header comment (3) |
| Bug tracking | `bugs/009-cross-feature-import-theme-preview.md` | **Edit** — mark `Status: Fixed`, add resolution note |
| Docs | `docs/architecture.md`, `docs/overview.md`, `docs/features/{i18n,settings,home,theme,icons}.md` | **Update via /finalize tech-writer** (see §6) — remove/adjust stale references to the deleted feature |

## 5. Acceptance Criteria

- [x] **AC-1**: `lib/features/theme_preview/` and all files within it do not exist.
- [x] **AC-2**: No file under `lib/` or `test/` contains an import path matching
  `theme_preview` (verified by grep returning zero source/test matches).
- [x] **AC-3**: `lib/core/routing/app_router.dart` contains no `/theme-preview`
  `GoRoute`, no `ThemePreviewScreen` import, and no TODO referencing
  `theme_preview`. Its library dartdoc no longer mentions `/theme-preview`. The
  route table is exactly the shell branches (`/`, `/meds`, `/history`),
  `/settings`, and the `errorBuilder`.
- [x] **AC-4**: `lib/features/home/presentation/screens/home_screen.dart` body
  renders only the centered `Text('Hello World')` — `find` for an
  `OutlinedButton` with text `'Theme preview'` returns nothing. The class dartdoc
  no longer references the preview button or `/theme-preview`. The `go_router`
  import remains (used by `context.push('/settings')`).
- [x] **AC-5**: `lib/app.dart`'s library dartdoc no longer references
  `/theme-preview` or a "temporary dev-only" preview route. No code/import in
  `app.dart` changes (the `appRouterProvider` delegation is byte-for-byte intact).
- [x] **AC-6**: `test/widget_test.dart`'s first test does not assert the "Theme
  preview" button; the second test (Home → Preview navigation + theme cycling) is
  deleted. The remaining tests still pump `DoslyApp` and pass.
- [x] **AC-7**: `test/core/routing/app_router_test.dart` no longer imports
  `ThemePreviewScreen`, Test 5 (AC-13 `/theme-preview` outside the shell) is
  deleted, and the file header comment no longer mentions `/theme-preview`.
  Remaining routing tests (shell topology, tab nav, branch-stack preservation,
  errorBuilder) pass.
- [x] **AC-8**: `bugs/009-cross-feature-import-theme-preview.md` has
  `Status: Fixed`, a `Fixed:` date, and a short resolution note pointing at this
  spec.
- [x] **AC-9**: `dart analyze` reports zero errors, warnings, and info-level
  diagnostics across the project (no `unused_import`, no dangling references).
- [x] **AC-10**: `flutter test` passes — every remaining test green.
- [x] **AC-11**: `flutter build apk --debug` completes successfully.
- [x] **AC-12**: No `print()`/`debugPrint()`, no `!` null assertion, no `dynamic`
  introduced by any edit in this spec.

## 6. Out of Scope

- NOT included (in code tasks): updating `docs/` prose. Stale doc references to
  `theme_preview` are real and must be cleaned up, but per the project workflow
  doc maintenance is performed by the **tech-writer agent at `/finalize`**, not in
  feature implementation tasks. §2 lists every doc line that references the
  feature so `/finalize` has a complete checklist.
- NOT included: any change to the theme-cycle business logic
  (`CycleThemeMode` use case, `settings_provider`, `settings_screen`). The cycle
  behavior stays; only the dev preview's call into it is removed.
- NOT included: changes to `MaterialApp.router` wiring, `appRouterProvider`
  lifecycle, the `StatefulShellRoute` shell, or the `errorBuilder`.
- NOT included: changes to any other feature, the `l10n` ARB files, or
  `analysis_options.yaml`.
- NOT included: adding a replacement palette/preview tool (Option B from the
  research report). The screen is deleted, not reworked.
- NOT included: removing the `cycleThemeMode`-related Lucide icons (`sunMoon`,
  `sun`, `moon`) from the canonical icon set — they are documented glyphs and may
  be reused; only their showcase in the deleted file goes away.

## 7. Technical Constraints

- **Must follow**: Constitution §2.1 (cross-feature rule) — the deletion is the
  remedy; no new cross-feature imports may be introduced.
- **Must follow**: Constitution §3 "No dead code" — no dangling imports,
  comments, or dartdoc referencing the deleted feature may remain.
- **Must follow**: "Never leave bare TODOs" — the three `TODO(post-mvp)` markers
  for this removal are resolved by deleting them along with their code.
- **Must not break**: `flutter test`, `dart analyze`, `flutter build apk --debug`.
- **Must not break**: theme cycling, locale resolution, the shell route topology,
  or the `errorBuilder` fallback.
- **Must keep**: the `go_router` import in `home_screen.dart` (still used for the
  `/settings` push) and the `appRouterProvider` watch in `app.dart`.

## 8. Open Questions

- None. The removal scope is fully enumerated by the existing TODOs, the
  `specs/002-main-screen/spec.md §6` deferral, and the research report
  (`research/2026-05-22-bug-009-theme-preview-cross-feature.md`).

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| The first widget test (not the "second" the user named) also asserts the button → left untouched it would fail | Med | Low | AC-6 explicitly fixes test 1's assertion, not just deletes test 2 |
| Removing `home_screen.dart`'s button accidentally drops the `go_router` import, breaking `/settings` push | Low | Med | AC-4 + §7 pin the import as "must keep"; `dart analyze` (AC-9) catches an accidental removal |
| Stale `docs/` references linger and mislead future readers | Med | Low | §2 enumerates every doc line; `/finalize` tech-writer cleans them (§6) |
| A future reader assumes theme cycling lost test coverage | Low | Low | §2 lists the four Settings tests that independently cover the cycle |
| `app_router_test.dart` header/Test-5 deletion leaves a dangling AC-13 comment reference | Low | Low | AC-7 covers import, test body, and header comment together |
