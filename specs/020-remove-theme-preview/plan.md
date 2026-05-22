# Plan: Remove theme_preview feature

**Date**: 2026-05-22
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

A pure deletion + reference-cleanup change. Remove the `lib/features/theme_preview/`
folder (3 files), then sweep every inbound reference — the `/theme-preview` route,
the `HomeScreen` dev button, dartdoc mentions, and two test files — until
`dart analyze` and `flutter test` are green with zero dangling references. No new
code, no new dependencies, no architecture change. Closes Bug 009 by removing the
file that holds the §2.1 cross-feature import.

## Technical Context

**Architecture**: Touches `presentation` (a feature screen + its widgets, the home
screen, the routing composition root) and the app root dartdoc. No `domain` or
`data` layer involvement.
**Error Handling**: N/A — no fallible operations added or removed.
**State Management**: N/A — Riverpod wiring (`appRouterProvider`,
`settingsNotifierProvider`) is untouched; only the preview screen's *consumer* of
`settingsNotifierProvider` is deleted along with the file.

## Constitution Compliance

- **§2.1 Cross-feature rule**: COMPLIANT — the violation (`theme_preview` importing
  `settings/presentation` and `settings/domain`) is removed by deleting the file.
  No new cross-feature import is introduced.
- **§3 No dead code**: COMPLIANT — the plan sweeps imports, comments, dartdoc, and
  tests so nothing references the deleted feature.
- **"Never leave bare TODOs"**: COMPLIANT — the three `TODO(post-mvp)` markers are
  deleted together with the code they annotate.
- **"Minimal changes"**: COMPLIANT — edits are scoped to reference removal. One
  small KISS simplification (single-child Column → direct child) is noted as a
  decision below.
- **"Read before write"**: all target files were read during `/specify` and are
  re-read by the executing agent before edits.
- **No `print`/`!`/`dynamic`**: COMPLIANT — deletion-only; nothing introduced.

## Implementation Approach

### Layer Map

| Layer | What | Files |
|-------|------|-------|
| Presentation (feature) | Delete the preview screen + 2 helper widgets | `lib/features/theme_preview/**` (3 files) |
| Presentation (routing) | Remove route, import, route-table dartdoc | `lib/core/routing/app_router.dart` |
| Presentation (home) | Remove dev button + spacer + TODO, fix dartdoc | `lib/features/home/presentation/screens/home_screen.dart` |
| App root | Fix library dartdoc only | `lib/app.dart` |
| Tests | Fix test 1 assertion + delete test 2; remove import + delete Test 5 + fix header | `test/widget_test.dart`, `test/core/routing/app_router_test.dart` |
| Tracking | Mark bug resolved | `bugs/009-cross-feature-import-theme-preview.md` |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Remove vs rework the screen | Delete the folder | Spec §3 + research verdict (Option A); the screen's only purpose was early M3 validation, now done | Option B (local `ValueNotifier`) — leaves dead-ish code, against §3 |
| `HomeScreen` body shape after button removal | Replace the `Column` (now single child) with `Center(child: Text('Hello World'))` | KISS — a `Column(mainAxisSize: min, children: [oneChild])` is pointless once the button/spacer go | Keep the 1-child `Column` — needless wrapper |
| `go_router` import in `home_screen.dart` | Keep it | Still used by `context.push('/settings')` at line 42 | Removing it — would break `/settings` nav + fail `dart analyze` |
| Doc prose cleanup | Defer to `/finalize` tech-writer | Project workflow assigns `docs/` maintenance to tech-writer; spec §2 enumerates every stale line | Editing docs in this spec's code tasks — off-convention |
| Test 1 in `widget_test.dart` | Edit (drop button assertion + rename), do not delete | It still validates the home screen renders ("Hello World" + "Dosly" app bar) — that coverage stays valid | Deleting it — loses legitimate home-render coverage |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | Delete | Remove file (holds the Bug 009 imports) |
| `lib/features/theme_preview/presentation/widgets/color_swatch_card.dart` | Delete | Remove file |
| `lib/features/theme_preview/presentation/widgets/typography_sample.dart` | Delete | Remove file; `lib/features/theme_preview/` directory removed |
| `lib/core/routing/app_router.dart` | Modify | Remove import (22), `/theme-preview` `GoRoute` + TODO (74–79); update library dartdoc (6–8) to drop the sibling-route sentence |
| `lib/features/home/presentation/screens/home_screen.dart` | Modify | Remove `OutlinedButton` + `SizedBox` + TODO (56–64); simplify body to `Center(child: Text('Hello World'))`; trim class dartdoc (20–27); keep `go_router` import |
| `lib/app.dart` | Modify | Library dartdoc (10–13): replace the `/theme-preview` sentence with "Routing is delegated to `appRouterProvider` which currently exposes `/` (`HomeScreen`), `/meds`, `/history`, and `/settings`." No code change |
| `test/widget_test.dart` | Modify | Test 1 (66, 79–82): drop "Theme preview" from name + remove button assertion; delete Test 2 (87–126) |
| `test/core/routing/app_router_test.dart` | Modify | Remove `ThemePreviewScreen` import (29); delete Test 5 (286–313); fix header comment (3) |
| `bugs/009-cross-feature-import-theme-preview.md` | Modify | `Status: Fixed`, `Fixed: 2026-05-22`, resolution note → this spec |

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/architecture.md` | Update (via /finalize) | Lines 180, 198, 216 — drop `/theme-preview` from routing prose, code sample, and route table |
| `docs/overview.md` | Update (via /finalize) | Line 24 — drop the "reached via dev button / scheduled for removal" sentence |
| `docs/features/i18n.md` | Update (via /finalize) | Lines 189–190 — remove the dev-scaffolding string rows |
| `docs/features/settings.md` | Update (via /finalize) | Line 81 — reword the `CycleThemeMode` note that cites `ThemePreviewScreen` as the consumer (the use case still exists; only the preview caller is gone) |
| `docs/features/home.md` | Update (via /finalize) | Line 146 — drop the "add icons to `theme_preview_screen.dart`'s showcase" guidance |
| `docs/features/theme.md` | Update (via /finalize) | Lines 83, 89, 116, 128 — remove the preview-screen sync steps and the "When to delete" section (now done) |
| `docs/features/icons.md` | Update (via /finalize) | Lines 45, 51, 55, 57, 119, 125 — remove the "render in the theme preview" discoverability claims |

Doc edits are intentionally NOT code tasks (spec §6) — they are the tech-writer's
job at `/finalize`. Listed here so that step has a complete checklist.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Removing the button drops the `go_router` import → `/settings` nav breaks | Low | Med | Decision pins the import as "keep"; `dart analyze` (AC-9) catches removal |
| Only deleting "the second test" leaves test 1's button assertion failing | Med | Low | Plan edits test 1 separately (AC-6) |
| Dangling dartdoc/comment reference survives the sweep | Med | Low | AC-2 grep gate + AC-9 `dart analyze`; final grep for `theme.preview`/`ThemePreview` across `lib/` + `test/` |
| Stale `docs/` references mislead readers until `/finalize` | Med | Low | Doc table above is the `/finalize` checklist |
| `app_router_test.dart` Test 5 deletion leaves a now-meaningless AC-13 mention in the header | Low | Low | AC-7 covers header comment + import + test body together |

## Dependencies

None. No packages added or removed; `pubspec.yaml` untouched.

## Supporting Documents

- Research: [`research/2026-05-22-bug-009-theme-preview-cross-feature.md`](../../research/2026-05-22-bug-009-theme-preview-cross-feature.md) (Option A chosen)
- No data-model.md or contracts.md — no entities or API surface involved.
