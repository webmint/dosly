# Plan: Adopt `@riverpod` Codegen Across All Manual Providers

**Date**: 2026-05-08
**Spec**: `specs/015-riverpod-codegen/spec.md`
**Status**: Approved
**Closes**: bug 004

## Summary

Wire `riverpod_annotation` (runtime) and `riverpod_generator` (dev) into `pubspec.yaml`, then mechanically migrate every manual provider to the codegen form via `build_runner`. The migration is purely structural — public APIs, error semantics, override patterns, and notifier lifetimes are byte-equivalent. The single semantic rename (`settingsProvider` → `settingsNotifierProvider`) is mandated by Riverpod 3.x codegen conventions for class-form notifiers.

## Technical Context

**Architecture**: Clean Architecture (constitution §2.1). This feature touches the presentation layer (providers) and `lib/core/` (the override-only `sharedPreferencesProvider`). Domain and data layers see only a single dartdoc rename. No layer boundaries shift.

**Error handling**: Existing `Either<Failure, T>` repository contract and the `SettingsNotifier` "optimistic-write, no-update-on-failure" pattern (with side-channel error stream) are preserved verbatim. No new failure paths.

**State management**: Riverpod 3.x with `riverpod_generator`. Function-form `@riverpod` for stateless providers; class-form `@riverpod class X extends _$X` for the notifier. Default `autoDispose` for everything except `sharedPreferencesProvider` (which is `keepAlive: true` because it's a startup-injected singleton).

**Codegen pipeline**: Reuses the existing `build_runner` toolchain that feature 012 established for `freezed`. The same `dart run build_runner build --delete-conflicting-outputs` invocation now produces `*.g.dart` alongside `*.freezed.dart`. `analysis_options.yaml:19-21` already excludes `**/*.g.dart` — no analyzer changes.

## Constitution Compliance

| Rule | Status | Note |
|---|---|---|
| §1 stack: "Riverpod 2.x with `riverpod_generator`" | ✅ Aligning | Wording is stale (`flutter_riverpod ^3.3.1` is 3.x); semantic intent is satisfied. Constitution wording fix is a follow-up, out of scope. |
| §2.1 layer boundaries | ✅ Compliant | Migration preserves all import directions. `domain/app_settings.dart` only sees a dartdoc edit. |
| §2.2 generated files committed next to source | ✅ Compliant | New `.g.dart` files are committed; matches the freezed precedent. |
| §2.3 use `flutter pub add` | ✅ Compliant | Both deps added via `flutter pub add` (runtime) and `flutter pub add --dev` (dev). No manual pubspec edits. |
| §4.1.1 [convention] always `@riverpod` codegen | ✅ This is the goal | Drives the spec. |
| §4.2.1 no `print`/`debugPrint`, no `!`, no `dynamic`, etc. | ✅ Untouched | Codegen output is generated; if it produced `dynamic`, the analyzer exclusion already silences it (§7.4). |
| §6.6 build_runner invocation | ✅ Followed | `dart run build_runner build --delete-conflicting-outputs`. |
| §7.2 example uses outdated `XxxRef` typedef | ⚠️ Stale doc | Riverpod 3.x dropped these typedefs. New code uses `Ref` directly. The §7.2 example needs a follow-up doc fix; not a blocker. |

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|---|---|---|
| Infra (root) | Add 2 deps; resolve lock; commit generated files | `pubspec.yaml` (modify), `pubspec.lock` (auto), `.gitignore` (verify `*.g.dart` is **not** ignored — already correct since freezed files are committed) |
| Core | Migrate startup-injected provider to `@Riverpod(keepAlive: true)` | `lib/core/providers/shared_preferences_provider.dart` (modify — add `part` + annotation; convert from `Provider<>` factory to function), `lib/core/providers/shared_preferences_provider.g.dart` (new — generated) |
| Presentation (providers) | Migrate three providers in one file to `@riverpod` (function + class + function forms) | `lib/features/settings/presentation/providers/settings_provider.dart` (modify), `lib/features/settings/presentation/providers/settings_provider.g.dart` (new — generated) |
| Presentation (consumers) | Symbol rename `settingsProvider` → `settingsNotifierProvider` | `lib/app.dart`, `lib/features/settings/presentation/widgets/language_selector.dart`, `lib/features/settings/presentation/widgets/theme_selector.dart`, `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` |
| Presentation (entry) | Verify only — no edit needed | `lib/main.dart` (read; confirm `sharedPreferencesProvider.overrideWithValue(prefs)` still compiles) |
| Domain (dartdoc) | dartdoc reference only — no behavior | `lib/features/settings/domain/entities/app_settings.dart` (line 24) |
| Tests (unit) | Symbol rename `settingsProvider` → `settingsNotifierProvider` | `test/features/settings/presentation/providers/settings_provider_test.dart` |
| Tests (widget/router) | Verify only — no rename needed (uses `settingsRepositoryProvider`) | `test/core/routing/app_router_test.dart`, `test/features/settings/presentation/screens/settings_screen_test.dart` |
| Documentation | Update existing prose + add codegen-pattern note | `docs/architecture.md` (rename references; update provider-wiring table; add codegen invocation note) |
| Bug tracker | Close bug 004 | `bugs/004-manual-providers-missing-riverpod-codegen.md` |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|---|---|---|---|
| Settings notifier callsite name | `settingsNotifierProvider` (codegen default) | Canonical Riverpod 3.x class-form. Reading `ref.watch(settingsNotifierProvider)` is unambiguous: it's the notifier's state. Aligns with future `medicationsNotifierProvider`-style names. | (a) Rename class `SettingsNotifier` → `Settings` to keep `settingsProvider` callsite — collides with entity `AppSettings`. (b) Customize codegen `name` parameter — adds boilerplate, fights idiom. |
| `settingsErrorsProvider` lifetime | `@riverpod` (default `autoDispose`) | Only consumer is `SettingsScreen` via `ref.listen` while mounted. The provider exposes a broadcast stream of one-shot events (failures), not state to retain. The underlying `SettingsNotifier` (kept alive by `app.dart` watchers) owns the `StreamController`; the codegen autoDispose stream provider just re-subscribes when the screen remounts. | `@Riverpod(keepAlive: true)` — would mirror the manual `StreamProvider`'s default, but autoDispose is the better idiomatic match for short-lived listeners and yields no observable behavior change here. |
| `sharedPreferencesProvider` lifetime | `@Riverpod(keepAlive: true)` | App-wide singleton injected at startup via `overrideWithValue`. Auto-dispose would never fire (the override holds it alive), but `keepAlive: true` makes the intent explicit and matches the throwing-placeholder pattern's contract. | Default `@riverpod` — works, but obscures intent. |
| `settingsRepositoryProvider` lifetime | Default `@riverpod` (autoDispose) | Already follows the same lifetime as `settingsNotifierProvider` since the notifier holds a watch on it. AutoDispose is the codegen default and the right choice for a stateless wiring provider. | `keepAlive: true` — unnecessary; already kept alive transitively. |
| Provider file granularity | Keep all three settings providers in `settings_provider.dart` (single file with one `part`) | Co-located by feature cohesion. Constitution §2.2 allows multiple types per file when feature-cohesive. Splitting would invent new files for no reader benefit. | One provider per file — gold-plating. |
| `build.yaml` | Not added | `build_runner` autodiscovers builders from `dev_dependencies`. The default config handles the case. Adding a `build.yaml` would be premature configuration. | Add `build.yaml` to pin builder options — adds a config file with no current need. |
| Generated-file commit policy | Commit all `*.g.dart` (matches `*.freezed.dart` policy from feature 012) | Constitution §2.2 mandates committing generated files. Keeps fresh clones buildable without running `build_runner` first; same precedent already set for freezed and l10n. | Gitignore `*.g.dart` — violates §2.2. |
| `pub add` order | `riverpod_annotation` first, then `riverpod_generator --dev` | Two separate commands so each can be reviewed/diffed independently. `flutter pub add` resolves transitive constraints. | One combined command — fine, but two-step is auditable. |
| Codegen invocation | `dart run build_runner build --delete-conflicting-outputs` | Constitution §6.6 mandates this exact invocation. `--delete-conflicting-outputs` already used by freezed pipeline. | `dart run build_runner watch -d` — fine for active dev, but spec wants a one-shot for the task. |

### File Impact

| File | Action | What Changes |
|---|---|---|
| `pubspec.yaml` | Modify (via `flutter pub add`) | Add `riverpod_annotation: ^X.Y.Z` to `dependencies`; add `riverpod_generator: ^X.Y.Z` to `dev_dependencies`. Versions resolved by pub. |
| `pubspec.lock` | Modify (auto) | Reflects newly added deps + transitives. |
| `lib/core/providers/shared_preferences_provider.dart` | Modify | Add `import 'package:riverpod_annotation/riverpod_annotation.dart';`. Drop `import 'package:flutter_riverpod/flutter_riverpod.dart';` (codegen pulls it in transitively if needed; verify). Add `part 'shared_preferences_provider.g.dart';`. Convert `final sharedPreferencesProvider = Provider<...>((ref) => throw ...)` to `@Riverpod(keepAlive: true)\nSharedPreferencesWithCache sharedPreferences(Ref ref) => throw ...`. The codegen-emitted symbol is `sharedPreferencesProvider` (function name + `Provider` suffix). Preserve dartdoc verbatim. |
| `lib/core/providers/shared_preferences_provider.g.dart` | **Create (generated)** | Output of `build_runner`. Commit. |
| `lib/features/settings/presentation/providers/settings_provider.dart` | Modify | Add `import 'package:riverpod_annotation/riverpod_annotation.dart';`. Add `part 'settings_provider.g.dart';`. Convert: <br>• `final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {...})` → `@riverpod\nSettingsRepository settingsRepository(Ref ref) {...}`<br>• `final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);` → annotate the existing class: `@riverpod\nclass SettingsNotifier extends _$SettingsNotifier { ... }`. Drop the `extends Notifier<AppSettings>` declaration. The class body (build, four setters, `_errors`, `errors` getter) is untouched.<br>• `final settingsErrorsProvider = StreamProvider<Failure>((ref) => ref.watch(settingsProvider.notifier).errors);` → `@riverpod\nStream<Failure> settingsErrors(Ref ref) => ref.watch(settingsNotifierProvider.notifier).errors;` |
| `lib/features/settings/presentation/providers/settings_provider.g.dart` | **Create (generated)** | Output of `build_runner`. Commit. |
| `lib/main.dart` | Verify only | `sharedPreferencesProvider.overrideWithValue(prefs)` continues to compile because the codegen-emitted symbol has the same name. No code edit. |
| `lib/app.dart` | Modify | Replace 4 occurrences: `settingsProvider.select((s) => s.X)` → `settingsNotifierProvider.select((s) => s.X)` (lines 67, 70, 73, 76). |
| `lib/features/settings/presentation/widgets/language_selector.dart` | Modify | Replace 4 occurrences: `settingsProvider` → `settingsNotifierProvider` (lines 35, 69, 71, 85). Keep dartdoc reference renamed too. |
| `lib/features/settings/presentation/widgets/theme_selector.dart` | Modify | Replace 4 occurrences: `settingsProvider` → `settingsNotifierProvider` (lines 33, 63, 65, 91). Keep dartdoc reference renamed too. |
| `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | Modify | Replace 2 occurrences: `settingsProvider` → `settingsNotifierProvider` (lines 34, 53). |
| `lib/features/settings/domain/entities/app_settings.dart` | Modify (dartdoc only) | Line 24: `ref.watch(settingsProvider.select(...))` → `ref.watch(settingsNotifierProvider.select(...))`. No code change. |
| `test/features/settings/presentation/providers/settings_provider_test.dart` | Modify | Bulk rename `settingsProvider` → `settingsNotifierProvider` (~20 sites). `settingsRepositoryProvider` references unchanged. No assertion logic changes. |
| `test/core/routing/app_router_test.dart` | Verify only | Uses `settingsRepositoryProvider` (kept name). Confirm import path still resolves. |
| `test/features/settings/presentation/screens/settings_screen_test.dart` | Verify only | Uses `settingsRepositoryProvider` (kept name). Confirm import path still resolves. |
| `docs/architecture.md` | Modify | (1) Rename `settingsProvider` → `settingsNotifierProvider` in prose at lines 30, 56, 145 and in the code snippet at lines 66/69/72/75. (2) Update the "Provider wiring" table (lines 122-126): change `Provider<...>` / `NotifierProvider<...>` types to `@riverpod` (function/class form notes). (3) Add a brief paragraph under the Riverpod section noting the codegen invocation (`dart run build_runner build --delete-conflicting-outputs`) and pointing to the new providers as the exemplars for future features. |
| `bugs/004-manual-providers-missing-riverpod-codegen.md` | Modify | Set `Status: Fixed`. Set `Fixed: 2026-05-08` (or actual date). Add cross-reference to `specs/015-riverpod-codegen/`. |

**Discovered during planning** (not in spec's Affected Areas, surfaced by codebase grep):
- `docs/architecture.md` lines 30, 56, 65-76, 122-126, 145 contain `settingsProvider` references that must be renamed alongside the source-code rename to keep documentation honest. Spec AC-14 is the catch-all that covers this; the bookkeeping task will handle it.

### Documentation Impact

| Doc File | Action | What Changes |
|---|---|---|
| `docs/architecture.md` | Update | Rename ~8 `settingsProvider` references to `settingsNotifierProvider`; update the Provider wiring table to reflect codegen-emitted types; add a short codegen-invocation note. |
| `docs/features/settings.md` | Verify only | Confirmed via grep: no references to the manual provider symbols. No edit needed. |
| `docs/api/*` | N/A | Project has no remote API. |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `flutter pub add` resolves a `riverpod_annotation` / `riverpod_generator` version that conflicts with `flutter_riverpod ^3.3.1` | Low | Medium | Same maintainer publishes the trio with synchronized versions. If conflict, downgrade `flutter_riverpod` constraint to the matching minor or upgrade all three to the latest compatible set. Verified via Context7 in research that 3.x line aligns. |
| Manual `Notifier<AppSettings>` superclass replaced by codegen-generated `_$SettingsNotifier` produces a different state-update contract | Low | Medium | Codegen `_$SettingsNotifier` extends Riverpod 3.x's notifier base with the same `state` getter/setter, `ref` getter, and `build()` override. The four `setX` methods need no changes. Verified via Context7. Tests will catch any drift. |
| Missed `settingsProvider` reference (e.g. in a comment, dartdoc, README, or unindexed file) | Medium | Low | Use `grep -rn "settingsProvider\b"` post-rename across `lib/`, `test/`, `docs/`, and the spec dir. Should match only `specs/015-riverpod-codegen/` (the spec itself) and the bug 004 file (historical evidence). Add as a verification check in the bookkeeping task. |
| `settingsErrorsProvider` autoDispose semantics surface a subtle behavior change in `SettingsScreen` | Low | Low | Read `SettingsScreen.build`: only listener is `ref.listen<AsyncValue<Failure>>(settingsErrorsProvider, ...)` while widget is mounted. Underlying `StreamController` lives on `SettingsNotifier`, which is kept alive. AutoDispose only affects the stream-provider re-subscription, which broadcast streams handle correctly. |
| Generated `.g.dart` triggers analyzer warnings or unused-import lints | Low | Low | `analysis_options.yaml` already excludes `**/*.g.dart`. Verified at line 19-21. |
| `build_runner` output collides with existing freezed output | Low | Low | `--delete-conflicting-outputs` flag handles this. Already used by feature 012's freezed pipeline. |
| `directives_ordering` lint (currently disabled per `analysis_options.yaml:31-35`) flares up due to new imports | Low | Low | Lint is disabled. Re-enabling it is out of scope (per its own deferral note). |
| `sort_pub_dependencies` lint (currently disabled per `analysis_options.yaml:43-48`) blocks the pubspec change | Low | Low | Lint is disabled. `flutter pub add` appends to the bottom — known pattern, accepted. |
| Spec AC-14 was vague about doc renames; plan expanded to include rename of existing `docs/architecture.md` prose | N/A | N/A (documentation alignment, not a risk) | Plan explicitly captures the wider doc-rename scope. AC-14 spirit is "docs match code"; this plan satisfies that fully. |

## Dependencies

**New runtime package**:
- `riverpod_annotation` — Riverpod codegen runtime annotations (`@riverpod`, `@Riverpod`, `Ref`). Same maintainer as `flutter_riverpod`. Version resolved by `flutter pub add`; expected to land in the 3.x line.

**New dev package**:
- `riverpod_generator` — `build_runner` builder that emits `*.g.dart` files for `@riverpod`-annotated declarations. Reuses the existing `build_runner ^2.15.0` already in `dev_dependencies` (added by feature 012 for freezed).

**No new services, env vars, or platform configuration.**

## Supporting Documents

- **Research**: The deep research is already on file at `research/2026-05-08-bug-004-riverpod-codegen.md` (project root). It covers Context7-verified package compatibility, the four-site migration shape, and the recommended naming convention. Not duplicated under `specs/015-riverpod-codegen/research.md` — the original is authoritative.
- **Data model**: N/A — no domain entities change. Entity `AppSettings` is untouched (one dartdoc line edit only).
- **API contracts**: N/A — dosly has no remote backend. The `SettingsRepository` interface contract is preserved verbatim.

## AC Cross-Reference

Each spec AC is mapped to its plan implementation path:

| AC | Plan path |
|---|---|
| AC-1 (deps in pubspec) | "Infra (root)" layer; `flutter pub add` decisions |
| AC-2 (`shared_preferences_provider.dart` migrated) | "Core" layer; design decision "`sharedPreferencesProvider` lifetime" |
| AC-3 (`settings_provider.dart` migrated) | "Presentation (providers)" layer; design decisions for the three notifier/function/stream forms |
| AC-4 (`build_runner` produces both `.g.dart` files) | Codegen invocation decision; File Impact for both `.g.dart` files |
| AC-5 (production rename `settingsProvider` → `settingsNotifierProvider`) | "Presentation (consumers)" layer; File Impact for `app.dart`, `language_selector.dart`, `theme_selector.dart`, `theme_preview_screen.dart` |
| AC-6 (test rename) | "Tests (unit)" layer; File Impact for `settings_provider_test.dart` |
| AC-7 (dartdoc in `app_settings.dart`) | "Domain (dartdoc)" layer |
| AC-8 (`main.dart` semantics preserved) | "Presentation (entry)" Verify only; design decision "`sharedPreferencesProvider` lifetime" preserves the override contract |
| AC-9 (`SettingsNotifier` public surface unchanged) | "Presentation (providers)" layer; class body untouched |
| AC-10 (`dart analyze` clean) | Implicit — codegen output excluded; no new lint surface |
| AC-11 (`flutter test` passes) | Symbol-only renames in tests; no assertion changes |
| AC-12 (`flutter build apk` succeeds) | No native or build config changes |
| AC-13 (bug 004 closed) | "Bug tracker" File Impact |
| AC-14 (`docs/architecture.md` codegen note) | "Documentation Impact" — expanded to also include rename of existing prose, table refresh, and codegen-invocation paragraph |

All 14 ACs have a clear implementation path. No orphan ACs.
