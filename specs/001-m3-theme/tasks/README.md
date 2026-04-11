# Tasks: Material Design 3 Theme

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-04-11
**Total tasks**: 8 — all **Complete**
**Branch**: `spec/001-m3-theme`
**Verification**: see `../verify.md` — APPROVED (14/15 AC PASS, AC-13 deferred to user manual run)

## Dependency Graph

```
       ┌──────────────────┐
       │ 001 Roboto fonts │
       └────────┬─────────┘
                │
                ▼
       ┌────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐    ┌──────────────────────┐
       │ 003 text theme │    │ 002 color schemes    │    │ 004 theme controller│    │ 006 preview widgets  │
       │   (+ pubspec)  │    │      (+ tests)       │    │     (+ tests)       │    │  (swatch + typography)│
       └────────┬───────┘    └──────────┬───────────┘    └──────────┬──────────┘    └──────────┬───────────┘
                │                       │                            │                          │
                └───────────┬───────────┘                            │                          │
                            ▼                                        │                          │
                   ┌──────────────────┐                              │                          │
                   │ 005 app_theme    │                              │                          │
                   └────────┬─────────┘                              │                          │
                            │                                        │                          │
                            │                                        │                          │
                            │                          ┌─────────────┘                          │
                            │                          │                                        │
                            │                          ▼                                        │
                            │            ┌────────────────────────┐                             │
                            │            │ 007 preview screen     │◄────────────────────────────┘
                            │            └────────────┬───────────┘
                            │                         │
                            └─────────┬───────────────┘
                                      ▼
                          ┌─────────────────────────┐
                          │ 008 DoslyApp + main +   │  ← REVIEW CHECKPOINT
                          │     smoke test          │
                          └─────────────────────────┘
```

**Parallelizable waves** (tasks within a wave have no inter-dependencies):
- **Wave 1**: 001, 002, 004, 006 — can all run in parallel
- **Wave 2**: 003 (depends on 001), 005 (depends on 002 + 003 but 003 can run as soon as 001 is done)
- **Wave 3**: 007 (depends on 004 + 006)
- **Wave 4**: 008 (depends on 004 + 005 + 007) — convergence

## Task Index

| # | Title | Agent | Depends on | Review checkpoint | Status |
|---|---|---|---|---|---|
| 001 | Add Roboto fonts and declare in pubspec | mobile-engineer | None | No | **Complete** |
| 002 | Create app_color_schemes.dart with light and dark ColorScheme literals | mobile-engineer | None | No | **Complete** |
| 003 | Create app_text_theme.dart with Roboto-based M3 type scale | mobile-engineer | 001 | No | **Complete** |
| 004 | Create theme_controller.dart and its tests | mobile-engineer | None | No | **Complete** |
| 005 | Create app_theme.dart with full ThemeData for both schemes | mobile-engineer | 002, 003 | No | **Complete** |
| 006 | Create preview helper widgets (ColorSwatchCard + TypographySample) | mobile-engineer | None | No | **Complete** |
| 007 | Create ThemePreviewScreen | mobile-engineer | 004, 006 | **Yes** | **Complete** |
| 008 | Wire DoslyApp, replace main.dart, replace smoke test | mobile-engineer | 004, 005, 007 | **Yes** | **Complete** *(manual run deferred to user)* |

## Acceptance Criteria Coverage

| AC | Description (short) | Tasks |
|---|---|---|
| AC-1 | `ColorScheme` literals, no `fromSeed` | 002 |
| AC-2 | Light scheme spot-checks | 002 |
| AC-3 | Dark scheme spot-checks | 002 |
| AC-4 | `AppTheme.lightTheme` / `darkTheme` | 005 (and 003 contributes textTheme) |
| AC-5 | pubspec font declarations + .ttf files | 001 |
| AC-6 | `ThemeController` API + default + setMode | 004 |
| AC-7 | `DoslyApp` with `ListenableBuilder` + `MaterialApp` | 008 |
| AC-8 | `lib/main.dart` reduced to 4 lines | 008 |
| AC-9 | `ThemePreviewScreen` content | 006 + 007 |
| AC-10 | Rounded icons only | 007 |
| AC-11 | `dart analyze` clean | every task (post-execution check) |
| AC-12 | `flutter test` passes | 002, 004, 008 (their tests) |
| AC-13 | Manual `flutter run` on iOS + Android | 008 (manual verification step) |
| AC-14 | No hardcoded `Color(0xFF...)` outside `lib/core/theme/` | 002 (canonical home), 006, 007 (consume via Theme.of) |
| AC-15 | No `package:flutter/*` in `domain/` | trivially true — no `domain/` files in this spec |

Every AC has at least one task. No coverage gaps.

## Additions to Spec

Two file additions discovered during planning, neither in the spec's Affected Areas table:

| File | Reason | Task |
|---|---|---|
| `assets/fonts/LICENSE.txt` | Apache 2.0 license attribution required for the bundled Roboto font | 001 |
| `assets/fonts/SOURCE.md` | Reproducibility — record download URL, date, SHA-256 hashes | 001 |

Both are tiny housekeeping files, included in Task 001.

## Risk Assessment

| Task | Risk | Reason |
|---|---|---|
| 001 | **Medium** | Manual font download is required. The implementer may not have network access in the sandbox; if the download fails, the task blocks until the user manually drops the four `.ttf` files into `assets/fonts/`. Mitigation: task description tells the implementer to STOP and prompt the user rather than guess or skip. |
| 002 | Low | Pure constants but the file has 60+ named parameters across two `ColorScheme` literals. Typo risk is non-zero — a transposed digit in a hex value would be silent until visual review. Mitigation: the test file (also written in this task) asserts every hex against the same source, so a typo fails the test immediately. |
| 003 | Low | Mechanical type scale transcription. M3 spec is well-known. |
| 004 | Low | Tiny file. Tests cover all behaviors. |
| 005 | Medium | Largest file (~120 lines), most component themes wired in one place. Easy to miss a parameter or use the wrong field name. Mitigation: section comments per component, manual run in Task 008 catches any visual regression. |
| 006 | Low | Tiny widgets. No state. |
| 007 | Medium | First widget that integrates everything. Layout overflow risk on small screens. Mitigation: `SingleChildScrollView` wrapping the body, manual run in Task 008. |
| 008 | **Medium-High** | Convergence point. Replaces the app entry point. If the wiring is wrong, `flutter run` fails entirely. Mitigation: review checkpoint, three small files only, smoke test fails fast if `DoslyApp` doesn't render. Must run manually on both platforms (AC-13). |

## Review Checkpoints

Two checkpoints, both auto-placed:

| Before Task | Reason | What to Review |
|---|---|---|
| 007 | First convergence (depends on 004 + 006) — first time multiple modules integrate | Verify Tasks 004 and 006 are functionally complete and their tests pass before building the screen on top of them. Confirm `themeController` and the two preview widgets are importable as expected. |
| 008 | Convergence (depends on 004 + 005 + 007) AND layer-boundary crossing (theme infrastructure → app entry point) AND highest-stakes task (replaces `lib/main.dart`) | Verify Tasks 005 and 007 produced what 008 expects: `AppTheme.lightTheme` / `AppTheme.darkTheme` are reachable, `ThemePreviewScreen` is importable. Run the full test suite before launching the manual `flutter run`. |

## Contract Consistency Check

Walked the contract chain. Every `Produces` is consumed by a downstream `Expects` or maps directly to a spec AC. Every `Expects` traces to either an upstream `Produces` or current codebase state.

| Producer task | Produces | Consumer task | Status |
|---|---|---|---|
| 001 | `pubspec.yaml` declares `family: Roboto` | 003 | ✅ Linked |
| 001 | `assets/fonts/Roboto-*.ttf` exist | 008 (manual run) | ✅ Linked (visual) |
| 002 | `lightColorScheme`, `darkColorScheme` exports | 005 | ✅ Linked |
| 002 | `app_color_schemes_test.dart` exists | AC-2, AC-3, AC-12 | ✅ Maps to AC |
| 003 | `AppTextTheme.textTheme` export | 005 | ✅ Linked |
| 004 | `themeController` singleton | 007, 008 | ✅ Linked (two consumers) |
| 004 | `ThemeController` class with `setMode`/`cycle` | AC-6, 008 (test) | ✅ Maps to AC + linked |
| 005 | `AppTheme.lightTheme` / `darkTheme` | 008 | ✅ Linked |
| 006 | `ColorSwatchCard`, `TypographySample` exports | 007 | ✅ Linked |
| 007 | `ThemePreviewScreen` class | 008 | ✅ Linked |
| 008 | `DoslyApp` + `main()` rewrite + smoke test | AC-7, AC-8, AC-12, AC-13 | ✅ Maps to ACs |

**No orphaned `Produces`.** **No unsatisfied `Expects`.** Chain is intact.
