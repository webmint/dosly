# Research: Bug 004 — Adopt `@riverpod` codegen and add missing pubspec deps

**Date**: 2026-05-08
**Topic**: bug 004 — hand-rolled providers + missing `riverpod_annotation`/`riverpod_generator` from `pubspec.yaml`
**Verdict**: **Feasible** — small, mechanical, well-precedented refactor. No architectural risk.

## Summary

Bug 004 is a constitution §4.1.1 violation: the project mandates `@riverpod` codegen but ships four hand-rolled providers, and `riverpod_annotation`/`riverpod_generator` aren't in `pubspec.yaml`. The codebase already runs `build_runner` for `freezed` (since feature 012), so half the codegen plumbing is in place — adding Riverpod codegen is purely additive. Net cost: 2 deps, 2 source files migrated, ~10 consumer call-sites updated (one provider rename), generated `.g.dart` files committed. Standard `/specify` → `/plan` → `/breakdown` flow is appropriate; this is too multi-step for `/fix` (touches 2 source files + ~10 consumer files + pubspec + a new lock file).

## Codebase Findings

### Existing Related Code

| Area | Files | Relevance |
|---|---|---|
| Manual providers (4 sites) | `lib/core/providers/shared_preferences_provider.dart:23`; `lib/features/settings/presentation/providers/settings_provider.dart:23, 30, 130` | The targets to migrate. Note: bug file says 3 sites — feature 014 added a 4th (`settingsErrorsProvider` as manual `StreamProvider<Failure>`). |
| `pubspec.yaml` | `pubspec.yaml:30-62` | Has `flutter_riverpod ^3.3.1`, `freezed_annotation ^3.1.0`, `freezed ^3.2.5`, `build_runner ^2.15.0`. **Missing**: `riverpod_annotation` (runtime) + `riverpod_generator` (dev). The bug's "build_runner missing" claim is stale — it was added with feature 012. |
| Existing freezed codegen | `lib/features/settings/domain/entities/app_settings.freezed.dart` | Confirms `build_runner build --delete-conflicting-outputs` already works in this repo. Pattern reusable. |
| `analysis_options.yaml:19-21` | exclude `**/*.g.dart` + `**/*.freezed.dart` | Already configured to exclude generated files. No analyzer changes needed. |
| Consumer call-sites | `app.dart`, `settings_screen.dart`, `language_selector.dart`, `theme_selector.dart`, `theme_preview_screen.dart`, `main.dart` + 5 test files | All read `settingsProvider` / `settingsRepositoryProvider` / `sharedPreferencesProvider` / `settingsErrorsProvider`. |

### Patterns Available

- **Codegen pipeline** is wired up — `dart run build_runner build` already runs as part of feature 012's freezed integration. Adding `riverpod_generator` to dev_dependencies extends the existing pipeline; no new tooling.
- **Throwing-placeholder + `overrideWithValue`** pattern (`shared_preferences_provider.dart`) maps cleanly to `@Riverpod(keepAlive: true)` + override in `main()` — same lifecycle, codegen syntax.
- **`Notifier<T>` subclass** maps to `@riverpod class Foo extends _$Foo` — established pattern.

### Gaps

- No prior `@riverpod` provider exists. This will be the first instance in the codebase, so the breakdown should land an exemplar that future features copy.
- No documentation entry yet in `docs/architecture.md` for the codegen invocation; constitution §6.6 covers it but the docs don't.

## Constitution Constraints

| Rule | Impact |
|---|---|
| §4.1.1 [convention] "Always use `@riverpod` codegen for new providers. No manual `Provider`/`StateNotifierProvider` declarations." | The driver of the bug. All four manual sites violate it. |
| §1 stack: "Riverpod 2.x with `riverpod_generator`" | Project chose this from day 1; pubspec drift means the choice was never enforced. The text says "2.x" but `flutter_riverpod ^3.3.1` is already pinned to 3.x — constitution §1 wording is stale and should be tightened to "3.x" alongside this bug fix. |
| §2.2 "Generated files sit next to their source AND are committed to the repo" | New `*.g.dart` files must be committed. Established by feature 012's `app_settings.freezed.dart`. |
| §6.6 "After any change to a `@riverpod`-annotated function … run `dart run build_runner build --delete-conflicting-outputs`" | Workflow already documented; reuse. |
| §7.2 example provider uses the **Riverpod 2.x `XxxRef` typedef** pattern (`AddMedicationRef ref`) | **Outdated.** Riverpod 3.x dropped `XxxRef` typedefs — `Ref` is used directly (per Context7). Constitution §7.2 example needs a small wording update or a follow-up bug, but does not block this fix. |

## Approaches

### Option A: Migrate all four sites to `@riverpod` in one PR
- **Description**: Add `riverpod_annotation` + `riverpod_generator`, annotate all four sites, run build_runner, update consumers. Single feature-scoped spec.
- **Pros**: Clean compliance state at end. One round of `dart run build_runner build`. No half-migrated codebase.
- **Cons**: Touches `settingsProvider` rename (`settingsProvider` → `settingsNotifierProvider`, since codegen names by class). Blast radius: ~10 call-sites across 5 production + 5 test files.
- **Complexity**: Low–Medium

### Option B: Migrate `sharedPreferencesProvider` only first, then settings
- **Description**: Two specs — one to wire up the deps + migrate the simplest provider, one for the settings cluster.
- **Pros**: Lands the deps + analyzer-passes-with-codegen proof in a tiny PR before committing to the settings rename.
- **Cons**: Two `/specify` cycles, two reviews, two finalize gates, for a fundamentally mechanical refactor. Gold-plating.
- **Complexity**: Low (each), but higher total wall-clock.

### Option C: Recommend Option A with a deliberate naming choice
- **Description**: Same as A, but consciously decide between (i) renaming class `SettingsNotifier` → `Settings` to keep callsites as `settingsProvider`, vs. (ii) accepting `settingsNotifierProvider` at all callsites.
- Path (i) collides semantically with entity `AppSettings` — confusing.
- Path (ii) is the canonical Riverpod 3.x idiom and easier to read at the callsite.
- **Recommendation**: path (ii), `settingsNotifierProvider`.

**Recommended approach**: **Option A, naming path (ii)**. One spec, one breakdown, mechanical migration with explicit consumer-rename task.

## External Research

Signal: introducing two new packages (`riverpod_annotation`, `riverpod_generator`) — a real signal because version compatibility with the pinned `flutter_riverpod ^3.3.1` matters.

### Libraries Verified (via Context7 `/rrousselgit/riverpod`)

| Library | Status | Compatibility | Notes |
|---|---|---|---|
| `riverpod_annotation` | Active, current line v3.x | Pairs with `flutter_riverpod ^3.3.1` | Add to runtime `dependencies` (not dev). |
| `riverpod_generator` | Active, current line v3.x | Same | Dev dep. Generates `*.g.dart`. |
| `build_runner` | Already present | OK | Reused from freezed pipeline. |

Riverpod 3.x changed the codegen surface from 2.x: providers receive `Ref` directly (no `MedicationRepositoryRef`-style typedefs). Constitution §7.2's example block is on the 2.x form — note for a follow-up doc fix, but not a blocker for this work.

Codegen syntax confirmed via Context7:
```dart
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepositoryImpl(SettingsLocalDataSource(prefs));
}

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  @override
  AppSettings build() { ... }
}
```

For the override-only `sharedPreferencesProvider`, the throwing-placeholder pattern survives:
```dart
@Riverpod(keepAlive: true)
SharedPreferencesWithCache sharedPreferences(Ref ref) =>
  throw UnimplementedError('Override in main()');
```
`overrideWithValue` in `main.dart` continues to work unchanged with the codegen-emitted provider.

### References

- Context7 `/rrousselgit/riverpod` — `riverpod_generator` README + 3.x codegen examples (Notifier and function forms).

## Complexity Assessment

| Dimension | Rating | Notes |
|---|---|---|
| Codebase changes | Low–Medium | 2 source files annotated; ~10 callsite updates (1 rename only — others keep their names); 1 pubspec change; 2 new `.g.dart` files committed. |
| New dependencies | Low | 2 well-known packages from same maintainer as `flutter_riverpod`. |
| Risk | Low | Codegen pipeline already validated by freezed. Tests catch any wiring breakage. No runtime behavior change — pure compile-time codegen substitution. |

## Recommendation

**Proceed.** Run:

```
/specify "Adopt @riverpod codegen across all manual providers (bug 004). Add riverpod_annotation runtime dep and riverpod_generator dev dep. Migrate the four hand-rolled providers (sharedPreferencesProvider, settingsRepositoryProvider, settingsProvider, settingsErrorsProvider) to @riverpod-annotated functions/classes. Update consumer call-sites for the settingsProvider→settingsNotifierProvider rename. Commit generated .g.dart files. Closes bug 004. See research/2026-05-08-bug-004-riverpod-codegen.md for codebase findings, constitution constraints, approach options, and the recommended 4-task breakdown shape."
```

Likely 4-task breakdown shape (precedent: features 013, 014):
1. **Infra**: `pubspec.yaml` add deps + run `flutter pub get` (architect/mobile-engineer).
2. **Core**: Migrate `shared_preferences_provider.dart` to `@Riverpod(keepAlive: true)`; verify `main.dart` override still compiles (architect).
3. **Settings cluster** (terminal source-edit task — integration gate here): migrate `settingsRepositoryProvider`, `SettingsNotifier`, `settingsErrorsProvider` to `@riverpod`; update all production + test consumer callsites for the `settingsNotifierProvider` rename; run `build_runner`; commit `.g.dart` (mobile-engineer).
4. **Bookkeeping**: flip `bugs/004` Status → Fixed; update `docs/architecture.md` with the codegen pattern; consider noting the constitution §1 "2.x" wording drift + §7.2 outdated example for a separate doc-only follow-up (tech-writer).
