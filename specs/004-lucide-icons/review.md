# Review Report: 004-lucide-icons

**Date**: 2026-04-14
**Spec**: specs/004-lucide-icons/spec.md
**Changed files**: 4 (pubspec.yaml, pubspec.lock, home_screen.dart, theme_preview_screen.dart)

## Security Review

- Critical: 0 | High: 0 | Medium: 1 | Info: 3

- **Medium** — `pubspec.yaml:38`: Dependency pinned with caret (`^3.1.12`), which permits automatic minor/patch updates on `flutter pub upgrade` or lockfile regeneration on a fresh machine. For supply-chain hygiene in a medication-tracking app (PHI context per MEMORY.md), a compromised minor release could be ingested without review. `pubspec.lock` commits the SHA-256 hash (integrity protection), but there is no CI check enforcing lockfile immutability.
  Recommendation: Either (a) tighten to an exact pin `lucide_icons_flutter: 3.1.12` consistent with the project's "SHA-256 hashing for bundled font assets" supply-chain pattern, or (b) explicitly accept caret ranges as project policy and document it in the constitution. Current `^3.1.12` is the pub default and carries no exploitable flaw today — this is a defense-in-depth gap, not an urgent issue.

- **Info** — `pubspec.yaml:38` / `pubspec.lock`: Package `lucide_icons_flutter` 3.1.12 is a pure-Dart icon-font wrapper (IconData constants + bundled TTF). No network, file I/O, platform channels, `dart:mirrors`, or `Process` usage. No runtime attack surface added. OWASP MASVS-NETWORK / MASVS-STORAGE / MASVS-PLATFORM are not affected by this change.

- **Info** — `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart:130-156`: Icon showcase labels (`pill`, `syringe`, `thermometer`, etc.) are static design-system identifiers, not user-entered medication names. Preserves the MEMORY.md privacy rule ("Logging medication names — forbidden. PHI even for personal use."). No PHI exposure. Screen is flagged for post-MVP removal, further limiting exposure.

- **Info** — `home_screen.dart` and `theme_preview_screen.dart`: Both files correctly keep the `lucide_icons_flutter` import confined to the `presentation/` layer. Domain layer untouched — constitution rule "Never put Flutter imports in `domain/`" honored.

## Performance Review

- High: 0 | Medium: 1 | Low: 4

- **Medium** — `theme_preview_screen.dart:135-154, 211`: `Icon` widgets in the showcase are not `const`, even though their `IconData` arguments (e.g., `LucideIcons.pill`) and `size: 32` are compile-time constants. The `_iconTile` helper takes `IconData` as a parameter, preventing inline `const`. On each theme cycle via `themeController.cycle`, `_PreviewBody` rebuilds allocating 20 fresh `Icon` instances and 20 `Text` widgets rather than short-circuiting via reference equality.
  Recommendation: Extract a `const _IconTile(icon: LucideIcons.pill, label: 'pill')` stateless widget so each Wrap entry becomes a canonical constant. Low urgency — dev scaffolding scheduled for removal — but worth fixing when the widget is touched.

- **Low** — `theme_preview_screen.dart`: `SingleChildScrollView` + `Column` renders all children eagerly (swatches, typography, 20 icons, components, card, text field). 20 icons are trivial (< 1 ms build), well within the 16.67 ms frame budget.
  Recommendation: No change needed given dev-only context. If the pattern moves to user-facing screens, migrate to `CustomScrollView` + Slivers.

- **Low** — `pubspec.yaml:38`: `lucide_icons_flutter` ships as a TTF icon font (~1,500 glyphs, typically ~300–500 KB compressed). Flutter's tree-shaking detects used glyphs and strips the rest in release builds. Net added size in release expected to be under 100 KB.
  Recommendation: Confirm via `flutter build apk --analyze-size --target-platform android-arm64`. Ensure the build never passes `--no-tree-shake-icons`.

- **Low** — `home_screen.dart:39`: `IconButton(... icon: const Icon(LucideIcons.settings))` is correctly `const`. No issue — noted for completeness.

- **Low** — Startup time impact from importing `lucide_icons_flutter`: The package exposes `static const IconData` values. Dart's const-folding and tree-shaking keep only referenced constants. No font load at cold start — Flutter lazy-loads glyphs on first render. No measurable cold-start penalty expected.

## Test Assessment

- AC items with test coverage: 2 of 9 (AC-7, AC-8 via tooling; AC-1 is config only)
- Verdict: **ADEQUATE**

### Coverage Analysis

- **AC-1** (`lucide_icons_flutter` resolves): Config-level, verified by `flutter pub get`/build — not unit-testable.
- **AC-2** (home screen icon swap): No dedicated icon test. `widget_test.dart` asserts text only. Swap not behaviorally tested, but nothing broke.
- **AC-3, AC-4, AC-5** (theme preview icons + showcase + layout): No tests. Screen is temporary dev scaffolding — low priority per memory.
- **AC-6** (no `Icons.*` remain): Source-scan invariant, not a runtime test. Lint rule or grep gate more appropriate.
- **AC-7** (`dart analyze`): Tooling gate — enforced by PostToolUse hook and task verification.
- **AC-8** (`flutter test`): Existing tests continue to pass — don't assert on `IconData`, so icon swap is transparent.
- **AC-9** (`flutter build apk --debug`): Build gate — verified by task post-execution.

### Gaps

- **AC-6** (no `Icons.*` references): Could be enforced via `custom_lint` or CI grep check. Priority: **Low** — unlikely to regress silently in a 2-screen codebase.
- **AC-2** (home screen settings icon): Could add `expect(find.byIcon(LucideIcons.settings), findsOneWidget)` in `widget_test.dart`. Priority: **Low** — home screen is minimal, text assertions guard against widget-tree breakage.
- **AC-3/AC-4/AC-5** (theme preview): Skipped intentionally — theme preview scheduled for post-MVP removal.

**Rationale for ADEQUATE**: Mechanical icon-reference swap with zero behavioral/state changes. Existing tests exercise modified screens and pass, proving the swap didn't break the widget tree. Tooling gates (AC-7/8/9) cover the real risk surface.
