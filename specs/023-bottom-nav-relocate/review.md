# Review Report: 023-bottom-nav-relocate

**Date**: 2026-05-26
**Spec**: spec.md
**Changed files**: 5 (`lib/core/routing/app_bottom_nav.dart`, `lib/core/routing/app_shell.dart`, `test/core/routing/app_bottom_nav_test.dart`, `test/core/routing/app_bottom_nav_l10n_test.dart`, `test/core/routing/app_router_test.dart`)

> Feature is a pure, behavior-preserving file relocation (Bug 015 / constitution §2.1). The widget moved verbatim from `lib/core/widgets/` to `lib/core/routing/`; only file locations and import paths changed. All tasks are Complete.

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 5

**Overall: PASS**

- **Info** — `lib/core/routing/app_bottom_nav.dart`: purely presentational M3 `NavigationBar`; no storage, network, auth, deep links, file/webview input, or serialization. `selectedIndex`/`onDestinationSelected` forwarded verbatim from the parent shell; only static localized labels + `LucideIcons` constants rendered. No attack surface.
- **Info** — `lib/core/routing/app_shell.dart`: import-path edit only; wires go_router's framework-provided `currentIndex`/`goBranch` — not user-controlled.
- **Info** — No `print()`/`debugPrint()`, no hardcoded secrets/credentials across any changed file (constitution §4.2.1 respected).
- **Info** — Test files contain only import-path edits + relocated harness logic; no production paths, no secrets (the `_SentinelScreen` string is a test-only marker).
- **Info** — MASVS categories Insecure Storage / Auth / Network / Input Validation / Unsafe Patterns are N/A — no such code was added, moved, or modified.

  Recommendation: none required — verbatim move with no security-relevant surface; no regression.

## Performance Review

- High: 0 | Medium: 0 | Low: 1 (pre-existing, not introduced by this change)

**Verdict: no blocking findings.**

- **Low (pre-existing)** — `lib/core/routing/app_bottom_nav.dart`: the outer `Column(mainAxisSize: MainAxisSize.min)` wrapping `NavigationBar` adds one redundant `RenderFlex` layout node, since `NavigationBar` already sizes to its intrinsic height and `Scaffold.bottomNavigationBar` provides a fixed-height slot. Negligible frame-budget cost for a 3-item nav; **not introduced by this relocation** (byte-for-byte identical build tree).
  Recommendation: leave as-is unless a profiler shows it contributing to jank. Do NOT fix as part of this feature (out of scope; behavior-preserving move).
- Confirmed correct: `const` applied to all const-eligible leaves (`Divider`, all three `Icon`s); `NavigationBar` non-const is an SDK constraint (MEMORY/Feature 005), not a defect; rebuild scope is minimal (stateless, param-driven, re-runs only on navigation events).

## Test Assessment

- AC items with test coverage: 8 of 8 (3 substantive behavioral ACs fully covered by runtime tests; 5 structural/gate ACs appropriately enforced by the compile step / `dart analyze` / suite-count gate)
- Coverage gaps: none genuine
- **Verdict: ADEQUATE**

- **AC-3 (renders identically)** — fully covered: `app_bottom_nav_test.dart` (6 tests: 3 destinations+labels in order, Lucide icons, `selectedIndex` reflection, tap→callback, `labelBehavior alwaysShow`, 1-px divider) + `app_bottom_nav_l10n_test.dart` (3 locale tests: de/uk/en-fallback). All assertions intact and unmodified after the move.
- **AC-4 (shell imports new location + constructs identically)** — compile-verified + integration-tested via `app_router_test.dart`'s 6 tests and `find.byType(AppBottomNav)` usages.
- **AC-1 / AC-2 / AC-5 / AC-8** — structural facts (file path, public API shape, import paths, `core/widgets/` contents) correctly enforced by the compiler/`dart analyze`, not runtime `expect()`. Adding runtime assertions would test the build tool, not the widget — standard practice for relocations.
- **AC-6 / AC-7** — static-analysis and suite-level gates, pre-confirmed (`dart analyze` clean; 241 tests passed, count unchanged confirms no tests were lost in the move).
