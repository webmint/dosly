## Feature Summary: 004 — Lucide Icons

### What was built
Replaced all Material Design icons across the dosly Flutter app with Lucide icons from the `lucide_icons_flutter` package, matching the icon set used in the HTML design template. The theme preview screen gained an "Icons" showcase section displaying the 20 Lucide icons the app design uses, serving as a visual reference for future feature work.

### Changes
- Task 001: Add lucide_icons_flutter dependency — added `lucide_icons_flutter: ^3.1.12` to `pubspec.yaml` and resolved via `flutter pub get`
- Task 002: Replace Material icons with Lucide equivalents and add icon showcase — swapped 7 `Icons.*` references (1 in home, 6 in theme preview) with `LucideIcons.*` equivalents and added a 20-icon labeled showcase section to the theme preview between Typography and Components

### Files changed
- `lib/features/home/presentation/screens/` — 1 file modified (+3 lines)
- `lib/features/theme_preview/presentation/screens/` — 1 file modified (+60 lines: icon swaps + showcase section + `_iconTile` helper)
- `pubspec.yaml` / `pubspec.lock` — dependency added
- `specs/004-lucide-icons/` — spec, plan, task files, review, verify, summary artifacts
- `.claude/memory/MEMORY.md` — 4 new entries (Lucide package gotchas, `const` helper anti-pattern, two-task breakdown rationale)

Total code impact: 3 source files, ~60 net lines added. Zero domain-layer changes.

### Key decisions
- **Package choice**: `lucide_icons_flutter` over `flutter_lucide` / `flutter_svg` / `iconify_flutter` — drop-in `IconData` API, active maintenance, release-build tree-shaking
- **Showcase layout**: Inline `Wrap` of icon+label tiles matching the existing color swatches pattern — avoids premature abstraction for dev scaffolding
- **Showcase placement**: Between Typography and Components sections — icons read as design primitives alongside colors and type
- **Breakdown granularity**: 2 tasks (infra + presentation) rather than splitting per-screen — layer boundary is the right seam

### Acceptance criteria
- [x] AC-1: `lucide_icons_flutter` dependency resolves
- [x] AC-2: Home app bar uses `LucideIcons.settings`
- [x] AC-3: All 6 theme-preview Material icons replaced per §3.3 mapping
- [x] AC-4: Theme preview has "Icons" section with 20 labeled Lucide icons
- [x] AC-5: Showcase uses `Wrap` layout matching swatches
- [x] AC-6: Zero `Icons.*` references remain in either screen
- [x] AC-7: `dart analyze` passes
- [x] AC-8: `flutter test` passes (79/79)
- [x] AC-9: `flutter build apk --debug` succeeds
