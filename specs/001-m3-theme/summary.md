## Feature Summary: 001 — Material Design 3 Theme

### What was built

The visual foundation for dosly. A hand-coded Material 3 `ColorScheme` (light + dark) generated from seed `#4CAF50` via Material Theme Builder, bundled Roboto typography at four weights, fully wired `ThemeData` with M3 component themes, an in-memory `ThemeController` driving `MaterialApp.themeMode`, and a preview screen that renders every color role and common widget so the theme can be visually verified. Replaces the `flutter create` counter boilerplate — the app now boots into `ThemePreviewScreen` with full M3 theming in both light and dark.

### Changes

- **Task 001**: Bundle 4 Roboto TTF weights (300/400/500/700) from `googlefonts/roboto-3-classic` v3.015, declare in `pubspec.yaml`, ship SIL OFL 1.1 license + SHA-256 provenance metadata.
- **Task 002**: Create `lib/core/theme/app_color_schemes.dart` with hand-coded `const ColorScheme lightColorScheme` and `darkColorScheme` (no `fromSeed`) — every M3 role matches the Theme Builder output exactly. Plus 70 per-hex assertion tests.
- **Task 003**: Create `lib/core/theme/app_text_theme.dart` — `AppTextTheme.textTheme` exposing the full 15-style M3 type scale on bundled Roboto.
- **Task 004**: Create `lib/core/theme/theme_controller.dart` — `ThemeController extends ValueNotifier<ThemeMode>` with `setMode` + `cycle` (system→light→dark→system), singleton `themeController`, 7 unit tests.
- **Task 005**: Create `lib/core/theme/app_theme.dart` — `AppTheme.lightTheme` / `darkTheme` composing the color schemes and text theme with 11 pre-wired component themes (appBar, card, buttons, chip, fab, input, divider, bottomNav, icon).
- **Task 006**: Create two preview helper widgets (`ColorSwatchCard`, `TypographySample`) — stateless, `const`-constructible, no hardcoded colors.
- **Task 007**: Create `ThemePreviewScreen` — 28 color swatches + 15 typography samples + component showcase (Filled/Tonal/Outlined/Text buttons + Card + Chip + Switch + TextField + FAB). App-bar cycle action calls `themeController.cycle`. All icons use `_rounded` variants. **[review checkpoint]**
- **Task 008**: Wire `DoslyApp` (wraps `MaterialApp` in `ListenableBuilder(themeController)`), replace `lib/main.dart` with 7-line entry point, replace `test/widget_test.dart` with smoke + cycle tests. **[review checkpoint, final convergence]**

### Files changed

| Area | Files | Notes |
|---|---|---|
| `lib/core/theme/` | 4 added | Color schemes, text theme, app theme, theme controller |
| `lib/features/theme_preview/presentation/` | 3 added | 1 screen + 2 widgets |
| `lib/` (root) | 1 added, 1 replaced | `app.dart` new; `main.dart` stripped from 122 → 7 lines |
| `test/core/theme/` | 2 added | 77 unit tests (70 color + 7 controller) |
| `test/widget_test.dart` | replaced | counter test → smoke + cycle tests (2 widget tests) |
| `assets/fonts/` | 6 added | 4 Roboto TTFs + LICENSE.txt (OFL 1.1) + SOURCE.md (SHA-256 hashes) |
| `pubspec.yaml` | modified | Added `flutter.fonts` block + updated description |
| `specs/001-m3-theme/` | 12 added | spec, plan, research, review, verify, summary, task README + 8 task files |
| `.claude/memory/MEMORY.md` | modified | 6 new external-API quirks + lessons learned |

**Total**: 34 files changed, 2981 insertions(+), 139 deletions(-)

**Test suite after**: 79/79 passing (70 color-scheme assertions + 7 controller unit tests + 2 widget smoke tests)

### Key decisions

- **Hand-coded `ColorScheme` literals, no `fromSeed`** — single source of truth. Every hex is visible in source and asserted by tests so any design drift fails the build immediately.
- **Bundle Roboto as assets, not `google_fonts`** — constitution forbids runtime network calls; bundled fonts render identically on iOS and Android from first frame with no FOUC.
- **Plain `ValueNotifier<ThemeMode>` for theme state, no Riverpod yet** — scoped this spec to theming only; Riverpod arrives with the first feature that actually needs DI. Zero new package dependencies added.
- **`ThemeController` is in-memory only, no persistence** — persistence needs a drift `Settings` table, which is the future Settings feature's scope. Restart resets to `ThemeMode.system`.
- **`surfaceBright` / `surfaceDim` derived from adjacent container tones** — the HTML source doesn't specify them; derivation documented inline and in `research.md` (light: `Bright=ContainerLow, Dim=ContainerHighest`; dark: `Bright=ContainerHigh, Dim=ContainerLowest`).
- **All icons `Icons.xxx_rounded`** — matches the design reference (`material-icons-round`). Built into Flutter, zero asset cost.

### Deviations from plan

- **Task 001 — license**: task spec said "Apache 2.0" for Roboto, but Roboto v3 (the version actually shipped by Google Fonts) is **SIL OFL 1.1**. Agent correctly shipped OFL.txt and documented the discrepancy in `assets/fonts/SOURCE.md`. The task was edited post-completion to reflect the correct license.
- **Task 001 — Roboto source**: `github.com/google/fonts/apache/roboto/static/` no longer exists; agent used `googlefonts/roboto-3-classic` v3.015 release instead. Captured in `SOURCE.md` + memory.
- **Task 002 — `library;` directive**: agent added a `library;` directive at file top to attach file-level dartdoc properly — a Dart 3 idiom, no behavioral effect. Applied consistently across subsequent theme files.
- **Task 004 — removed `package:flutter/foundation.dart`**: redundant with `package:flutter/material.dart` (which re-exports `ValueNotifier`). `unnecessary_import` lint forced the fix. Captured in memory as a quirk.

### Acceptance criteria

All 15 ACs from `spec.md` — 14 PASS, 1 DEFERRED to manual user run:

- [x] **AC-1**: `const ColorScheme` literals exist, no `fromSeed` usage
- [x] **AC-2**: Light scheme hex spot checks match HTML source
- [x] **AC-3**: Dark scheme hex spot checks match HTML source
- [x] **AC-4**: `AppTheme.lightTheme`/`darkTheme` wire `useMaterial3: true` + correct scheme + Roboto `TextTheme` *(code-read verified; automated test is a flagged tech-debt gap)*
- [x] **AC-5**: `pubspec.yaml` declares 4 Roboto weights + all 4 `.ttf` files exist
- [x] **AC-6**: `ThemeController` default is `system`, `setMode` + `cycle` work
- [x] **AC-7**: `DoslyApp` wires `ListenableBuilder` + `MaterialApp` with all required fields *(code-read verified; exact field assertions are a flagged partial gap)*
- [x] **AC-8**: `lib/main.dart` reduced to 7 lines, no counter boilerplate
- [x] **AC-9**: `ThemePreviewScreen` renders all 3 sections (palette + typography + components) *(code-read verified; structural test presence is a flagged partial gap)*
- [x] **AC-10**: All icons use `Icons.xxx_rounded` variants
- [x] **AC-11**: `dart analyze` reports zero issues
- [x] **AC-12**: `flutter test` passes (79/79)
- [ ] **AC-13**: Manual `flutter run -d ios` + `flutter run -d android` — **⏳ DEFERRED to user**
- [x] **AC-14**: No hardcoded `Color(0xFF...)` outside `lib/core/theme/`
- [x] **AC-15**: No `package:flutter/*` imports in `domain/` (trivially — no domain layer)

### Review findings

- **Security**: 0 Critical / 0 High / 0 Medium (13 positive observations) — PASS
- **Performance**: 0 bottlenecks — PASS (2 optional polish items: trim unused Roboto Light/Bold weights, memoize `AppTheme` getters)
- **Test coverage**: GAPS FOUND — AC-4 fully uncovered; AC-7 + AC-9 partial. ~35 lines of test code would close all three. Logged as tech debt.

### Verdict
**APPROVED** (with tech debt). Ship-ready once AC-13 manual cross-platform run is completed by the user.
