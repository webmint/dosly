# Task 003: Delete the theme_preview folder and close Bug 009

**Status**: Complete
**Agent**: mobile-engineer
**Files**: `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` (delete), `lib/features/theme_preview/presentation/widgets/color_swatch_card.dart` (delete), `lib/features/theme_preview/presentation/widgets/typography_sample.dart` (delete), `bugs/009-cross-feature-import-theme-preview.md` (edit)
**Depends on**: 001, 002
**Blocks**: None
**Context docs**: None
**Review checkpoint**: Yes

**Description**:
With all inbound references removed by Tasks 001 (source) and 002 (tests), delete
the `theme_preview` feature folder outright — this is the change that physically
removes the Bug 009 cross-feature imports. Then mark the bug resolved. This is the
convergence task: it must run only after both 001 and 002 are complete, otherwise
a dangling import to the deleted files would break `dart analyze` / `flutter test`.

**Change details**:
- Delete all three files under `lib/features/theme_preview/` and remove the now-empty
  `lib/features/theme_preview/` directory:
  - `presentation/screens/theme_preview_screen.dart`
  - `presentation/widgets/color_swatch_card.dart`
  - `presentation/widgets/typography_sample.dart`
- After deletion, run a project-wide grep for `theme_preview`, `ThemePreview`,
  `ColorSwatchCard`, and `TypographySample` across `lib/` and `test/` and confirm
  zero matches (the helper widgets `ColorSwatchCard` / `TypographySample` were used
  only inside this folder — verified during breakdown).
- In `bugs/009-cross-feature-import-theme-preview.md`:
  - Change `**Status**: Open` to `**Status**: Fixed`.
  - Set `**Fixed**:` to `2026-05-22`.
  - Append a short resolution note: the feature folder was deleted (Option A),
    removing both cross-feature imports; reference `specs/020-remove-theme-preview/`.

## Contracts

### Expects
- `lib/core/routing/app_router.dart`, `lib/features/home/presentation/screens/home_screen.dart`,
  and `lib/app.dart` contain no `theme_preview` / `ThemePreviewScreen` / `/theme-preview`
  references (produced by Task 001).
- `test/widget_test.dart` and `test/core/routing/app_router_test.dart` contain no
  `theme_preview` / `ThemePreviewScreen` references (produced by Task 002).

### Produces
- The directory `lib/features/theme_preview/` does not exist.
- A grep for `theme_preview` across `lib/` and `test/` returns zero matches.
- `bugs/009-cross-feature-import-theme-preview.md` contains `**Status**: Fixed`.

**Done when**:
- [x] `lib/features/theme_preview/` and its three files are deleted.
- [x] Grep for `theme_preview`/`ThemePreview`/`ColorSwatchCard`/`TypographySample` over `lib/` + `test/` returns nothing.
- [x] Bug 009 marked `Fixed` with date and resolution note.
- [x] `dart analyze` reports zero diagnostics across the project.
- [x] `flutter test` passes.
- [x] `flutter build apk --debug` completes successfully.

**Spec criteria addressed**: AC-1, AC-2, AC-8, AC-9, AC-10, AC-11, AC-12

## Completion Notes

**Completed**: 2026-05-22
**Files changed**: deleted lib/features/theme_preview/{presentation/screens/theme_preview_screen.dart, presentation/widgets/color_swatch_card.dart, presentation/widgets/typography_sample.dart}; edited bugs/009-cross-feature-import-theme-preview.md
**Contract**: Expects [2/2 verified] | Produces [3/3 verified]
**Notes**: Terminal integration gate all green — `dart analyze` "No issues found!", `flutter test` 226 passed, `flutter build apk --debug` built successfully. Grep over lib/ + test/ returns zero `theme_preview`/`ThemePreview`/`ColorSwatchCard`/`TypographySample` matches. Bug 009 closed with a Resolution section noting both cross-feature imports eliminated. Code review verdict APPROVE (no findings). Review checkpoint cleared before execution (no external refs; go_router retained in home_screen.dart).
