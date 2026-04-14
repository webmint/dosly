# Plan: Lucide Icons

**Date**: 2026-04-12
**Spec**: specs/004-lucide-icons/spec.md
**Status**: Approved

## Summary

Replace all Material Design `Icons.*` references with Lucide equivalents from the `lucide_icons_flutter` package (v3.1.12) to match the HTML design template. The change is mechanical — same `IconData` API, different source. An icon showcase section is added to the theme preview screen for visual verification.

## Technical Context

**Architecture**: Presentation layer only — icons are widgets, no domain/data impact
**Error Handling**: N/A — no fallible operations
**State Management**: N/A — icons are stateless

## Constitution Compliance

- Rule 2.1 (Layer Boundaries): Compliant — all icon usage is in `presentation/` layer, no domain imports affected
- Rule 2.x (No Flutter in domain): Compliant — no domain files touched
- Rule "Minimal changes": Compliant — direct icon swap, no widget restructuring
- Rule "Lint everything": Will verify via `dart analyze` post-change

## Implementation Approach

### Package Details

- **Package**: `lucide_icons_flutter` (NOT `lucide_icons` — that's a different, older package)
- **Version**: `^3.1.12` (latest, published 2026-04-01)
- **Import**: `import 'package:lucide_icons_flutter/lucide_icons.dart';`
- **Class**: `LucideIcons` — provides `IconData` constants, drop-in replacement for `Icons.*`
- **Stroke variants**: Supports weight suffixes (e.g., `LucideIcons.activity200`) but default (no suffix) matches the HTML template's `stroke-width="2"` standard weight

### Icon Name Mapping

Verified icon names from the `lucide_icons_flutter` docs. Names use lowerCamelCase:

| HTML SVG icon | `LucideIcons.*` field | Verified |
|--------------|----------------------|----------|
| pill | `pill` | Yes (docs) |
| house | `house` | Needs verify* |
| settings | `settings` | Yes (docs) |
| history | `history` | Needs verify* |
| circle-plus | `circlePlus` | Needs verify* |
| thermometer | `thermometer` | Needs verify* |
| syringe | `syringe` | Needs verify* |
| glasses | `glasses` | Needs verify* |
| droplets | `droplets` | Needs verify* |
| activity | `activity` | Yes (docs) |
| clock | `clock` | Needs verify* |
| check | `check` | Yes (docs) |
| chevron-down | `chevronDown` | Needs verify* |
| chevron-right | `chevronRight` | Needs verify* |
| arrow-left | `arrowLeft` | Yes (docs) |
| search | `search` | Yes (docs) |
| plus | `plus` | Yes (docs) |
| eye | `eye` | Needs verify* |
| x | `x` | Yes (docs) |
| phone | `phone` | Needs verify* |
| sun-moon | `sunMoon` | Needs verify* |
| sun | `sun` | Needs verify* |
| moon | `moon` | Needs verify* |

*"Needs verify" = follows standard Lucide naming convention but not explicitly seen in docs samples. `dart analyze` will immediately catch any wrong name after implementation. These are standard Lucide icon names so mismatches are unlikely.

### Layer Map

| Layer | What | Files |
|-------|------|-------|
| Presentation | Replace icons, add showcase | `home_screen.dart`, `theme_preview_screen.dart` |
| Config | Add dependency | `pubspec.yaml` |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Package choice | `lucide_icons_flutter` ^3.1.12 | Provides `IconData` constants (same API as `Icons.*`), actively maintained, 3.x has stroke weight variants | `flutter_lucide` (different package, less popular), `flutter_svg` (overkill — need raw SVG parsing), `iconify_flutter` (heavy — loads all icon sets) |
| Icon showcase layout | `Wrap` of `Column(icon + label)` widgets | Matches existing color swatches pattern on the same screen | `GridView` (overkill for ~20 items in a `SingleChildScrollView`), separate screen (unnecessary complexity) |
| Showcase section placement | Between "Typography" and "Components" | Logical visual flow: colors → type → icons → interactive components | After components (icons are a design primitive, should appear before composed widgets) |
| Showcase widget | Inline private widget in `theme_preview_screen.dart` | Theme preview is temporary dev scaffolding — no need for a reusable widget | Separate file (violates minimal-change principle for throwaway code) |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `pubspec.yaml` | Modify | Add `lucide_icons_flutter: ^3.1.12` to dependencies |
| `lib/features/home/presentation/screens/home_screen.dart` | Modify | Replace `Icons.settings` → `LucideIcons.settings`, add import |
| `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | Modify | Replace 6 `Icons.*` refs → `LucideIcons.*`, add icon showcase section with 20 icons, add import |

### Documentation Impact

No documentation changes expected — this is an internal presentation-layer icon swap on temporary dev screens.

## AC Cross-Reference

| AC | Covered by |
|----|-----------|
| AC-1 | `pubspec.yaml` change + `flutter pub get` in verification |
| AC-2 | `home_screen.dart` icon swap |
| AC-3 | `theme_preview_screen.dart` 6 icon swaps |
| AC-4 | Icon showcase section with 20 icons + labels |
| AC-5 | Showcase uses `Wrap` layout matching swatches pattern |
| AC-6 | All `Icons.*` replaced — grep verification in done-check |
| AC-7 | `dart analyze` gate |
| AC-8 | `flutter test` gate |
| AC-9 | `flutter build apk --debug` gate |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Some `LucideIcons.*` field names differ from expected | Medium | Low | `dart analyze` catches immediately; fix during implementation |
| Package doesn't support Flutter SDK ^3.11.1 | Very Low | Medium | Package supports Flutter broadly; verify after `flutter pub get` |

## Dependencies

| Dependency | Version | Purpose |
|-----------|---------|---------|
| `lucide_icons_flutter` | ^3.1.12 | Lucide icon set as Flutter `IconData` constants |
