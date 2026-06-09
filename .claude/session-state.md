<!-- This file is a fixed-size sliding window. Always fully overwritten, never appended. Max ~40 lines. -->
# Session State

## Current Feature
None active. Last shipped: 025-typed-logger. Most recent work: `/audit --full` (2026-06-08 report) then a `/fix` batch resolving all 18 audit findings.

## Progress
Ran `/audit --full` → `audits/2026-06-08-audit.md` (confirmed all 21 prior-audit bugs still resolved; surfaced 18 new refactor-residue findings). Then `/fix` batch resolved all 18 across 7 clean commits on `main` (715c62c..333c742, local-only, not pushed). Critical was a constitution §2.1↔§7.2 self-contradiction → resolved by amending the constitution (user-approved).

## Recently Completed (last 3)
- /fix audit batch: removed dead CycleThemeMode cluster + dead bottomNavigationBarTheme; `late final _errors`→`late`; single-sourced prefs keys; allowBackup=false; dartdoc fixes; +2 re-enable-branch tests
- constitution §2.1 amended: @riverpod provider files may import data/ (composition seam)
- Bug 021 /fix: +2 corroborative AC-2 int wrong-type tests

## Recent Decisions
- §2.1 composition-seam exception sanctions provider→data imports — future audits must NOT re-flag it (see MEMORY)
- `late final` in Riverpod build() is a LateInitializationError trap on rebuild → use `late` (see MEMORY)
- Dead-cluster detection: grep lib/ for the method-INVOCATION; test-only callers = dead code

## Recently Modified Files
- constitution.md, lib/features/settings/presentation/providers/settings_provider.dart
- lib/core/providers/settings_prefs_keys.dart (new), lib/core/theme/app_theme.dart
- android/app/src/main/AndroidManifest.xml, docs/{features/settings,architecture}.md

## Verification
dart analyze: clean | flutter test: 286 pass | code-review: APPROVE w/ warnings (addressed)
