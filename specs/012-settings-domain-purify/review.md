# Review Report: 012-settings-domain-purify

**Date**: 2026-04-30
**Spec**: [spec.md](spec.md) (Approved 2026-04-30)
**Plan**: [plan.md](plan.md) (Approved 2026-04-30)
**Changed files**: 25 (12 source + 9 test + 3 doc + 1 pubspec)

> All 5 tasks marked Complete in `tasks/README.md`. `flutter test` 196/196 passing. `flutter build apk --debug` PASS. `dart analyze` clean across `lib/` + `test/`.

## Security Review

**Counts**: Critical: 0 | High: 0 | Medium: 0 | Info: 8
**Verdict**: PASS — no exploit risks, no security weaknesses, no defense-in-depth gaps introduced.

### Findings (Info — hardening notes)

- **Broad `catch (_)` in `getThemeMode()`** — `lib/features/settings/data/datasources/settings_local_data_source.dart:44`. Catch absorbs every throwable (not just `TypeError`) and returns `AppThemeMode.light`. Inline comment explains the legacy-int rationale (satisfies constitution §3.2 option (c) "explain why you're suppressing"), but the catch is wider than the documented case and lacks the "log it" half. For a non-PHI UI fallback this is acceptable defensively. Recommendation: narrow to `on TypeError catch (_)` once the typed logger lands (bug 002). No exploitable risk — fallback is a safe constant; no attacker-influenced control flow.
- **`CacheFailure(e.toString())` × 4 sites** — `settings_repository_impl.dart` lines 35, 45, 55, 67. `Exception.toString()` from SharedPreferences plugin failures may include filesystem paths from platform channels. Currently `Failure.message` is only consumed by `debugPrint` inside a `kDebugMode` guard (`settings_provider.dart:55-57` and siblings) — cannot leak in release. Carried forward to bug 010 / typed-logger workstream; not a regression introduced by this spec.
- **Generated `app_settings.freezed.dart` clean** — 4 strongly-typed fields (`bool`, `AppThemeMode`, `bool`, `AppLanguage`); no `dynamic` re-export, no JSON serialization (`includeFromJson: false`), auto-generated `toString()` echoes only UI-preference values. No PHI fields exist on this entity today. Future change-detector: if a medication-related field is ever added to `AppSettings`, override `toString()` or exclude the field from it.
- **`SharedPreferences allowList` verified** — `lib/main.dart:12-17` enumerates exactly the four non-PHI UI keys (`themeMode`, `useSystemTheme`, `useSystemLanguage`, `manualLanguage`). Constitution §4.2.1 compliance preserved.
- **Strict analyzer mode adopted without escape hatches** — `analysis_options.yaml` enables `strict-casts`/`strict-inference`/`strict-raw-types`. Grep for `// ignore:` and `ignore_for_file` across `lib/` and `test/` (excluding `*.freezed.dart`, `*.g.dart`) returns only generator-emitted gen_l10n files (out of scope, pre-existing). No analyzer suppressions were added to satisfy the new strict mode — code was actually fixed. The single `errors: invalid_annotation_target: ignore` is the freezed-required project-wide exception, correctly scoped via the `errors:` map.
- **No new runtime dependencies** — `pubspec.yaml` adds `freezed_annotation` (runtime — pure annotation package, no I/O, no network, no platform channels) and `freezed` + `build_runner` as dev-only codegen. `pubspec.lock` grep for `analytics|telemetry|firebase|sentry|crashlytics|amplitude|mixpanel` returned zero matches. Transitive packages are all build-time tooling.
- **No `print()` / unguarded `debugPrint()`** — the four `debugPrint` calls in `settings_provider.dart` (lines 56, 75, 94, 112) are all wrapped in `if (kDebugMode)` blocks; tree-shaken from release builds. Constitution §4.2.1 disposition: pre-existing pattern, carried forward to bug 002 / typed-logger workstream.
- **No unsafe code patterns** — zero hits for `eval`, `Function.apply`, `dart:mirrors`, dynamic `import()`, path concatenation against user input, or unchecked deserialization. Domain-layer purity reaffirmed: `app_theme_mode.dart` and `app_settings.dart` import only `package:freezed_annotation` and sibling domain entities — constitution §2.1 compliant.

## Performance Review

**Counts**: High: 0 | Medium: 0 | Low: 0
**Verdict**: PASS — every performance-relevant change is equal-to or better-than the prior shape.

| Metric | Before | After | Change |
|---|---|---|---|
| Root rebuild on unrelated field change | YES (identity `==`, all watchers dirty after each `copyWith`) | NO (`@freezed` value `==`, only changed-field watcher fires) | **Improvement** — eliminates spurious root rebuilds |
| `AppSettings ==` cost | O(1) identity, always new object after `copyWith` | O(4) primitive compares, short-circuits on `identical` | **Improvement** — net win for downstream selectors |
| `getThemeMode()` startup overhead | O(1) `getInt` | O(1) `getString` + `try/catch` (once at launch) | Indistinguishable in wall time |
| `DoslyApp.build` selector registrations | 2 wide selectors (`effectiveThemeMode`, `effectiveLocale`) | 4 narrow selectors (`useSystemTheme`, `manualThemeMode`, `useSystemLanguage`, `manualLanguage`) | Finer-grained, not coarser |
| `freezed_annotation` runtime weight | 0 KB | ~8 KB compiled annotation classes (tree-shaken if unreferenced) | Negligible |
| `freezed` + `build_runner` runtime weight | 0 KB | 0 KB (dev_dependencies, not shipped) | Zero |

### Notable observations

- The four narrow selectors in `lib/app.dart:66-77` are independent subscriptions. Riverpod fires a rebuild for `DoslyApp` only when the specific selected primitive changes. Toggling `useSystemLanguage` no longer dirties the `useSystemTheme`/`manualThemeMode`/`manualLanguage` watchers — strictly finer-grained than the prior `effectiveThemeMode`/`effectiveLocale` getter selectors.
- `@freezed`-generated `==` (line 28 of `app_settings.freezed.dart`) checks `identical` first (fast path), then falls through to 4 field comparisons (2 `bool`, 2 enum). All primitives, allocation-free. `hashCode` (line 33) uses `Object.hash` over 5 values — fixed-cost O(5). No quadratic patterns, no collection iteration.
- `_toFlutterThemeMode` is a 2-case Dart 3 switch expression — emitted as a direct branch by the compiler. Zero runtime overhead.
- `getThemeMode()`'s `try/catch` is on the launch path only (`SettingsRepositoryImpl.load()` → `SettingsNotifier.build()`); not a hot path.
- `ThemePreviewScreen.build` (dev-only screen, scheduled for post-MVP removal) uses `ref.watch(settingsProvider)` (unnarrowed) — now correctly stable thanks to the new `@freezed` value equality. Before spec 012 it would have rebuilt on every `copyWith(...)` due to identity equality. Improvement is irrelevant for production but noted for completeness.

## Test Assessment

**Coverage**: 13 of 13 testable in-scope ACs covered (AC-12, AC-13, AC-14 are CI gates; AC-17 is a deferred manual check)
**Verdict**: ADEQUATE — every spec-012 AC is exercised by at least one concrete test or grep-able structural assertion.

### AC-by-AC mapping

| AC | Type | Coverage |
|----|------|----------|
| AC-1 | structural (grep) | Confirmed clean: zero `package:flutter` imports in `lib/features/settings/domain/`. |
| AC-2 | structural (grep) | Confirmed clean: zero `package:flutter` imports in `lib/features/settings/data/`. |
| AC-3 | structural + test | `app_theme_mode.dart` present; `app_theme_mode_test.dart` covers 5 `fromCodeOrDefault` cases + cardinality. |
| AC-4 | structural + analyze gate | `@freezed abstract class`; `app_settings.freezed.dart` committed; analyze clean. |
| AC-5 | structural (grep) | Confirmed: zero `effectiveThemeMode\|effectiveLocale` references in `lib/`. |
| AC-6 | structural (grep) | `settings_repository.dart:27` has `Future<Either<Failure, void>> saveThemeMode(AppThemeMode mode)`. |
| AC-7 | test | `settings_repository_impl_test.dart` `persistence round-trip` group (lines 197-251) writes `AppThemeMode.dark` via repo A, reads back via repo B from same SharedPreferences, asserts equality. |
| AC-8 | test | `settings_repository_impl_test.dart` lines 79-88 seed `{'themeMode': 1}` (genuine int, not workaround string `'1'`); assert `AppThemeMode.light` fallback. |
| AC-9 | structural (grep) | `ThemeMode.` matches only in `lib/app.dart` (the seam) and `lib/features/theme_preview/` (display-only). Zero matches in `lib/features/settings/`. |
| AC-10 | structural (grep) | `lib/app.dart` has zero `effectiveThemeMode\|effectiveLocale` references. |
| AC-11 | structural | `pubspec.yaml` lists `freezed_annotation ^3.1.0`, `freezed ^3.2.5`, `build_runner ^2.15.0`. |
| AC-12 | gate | `dart analyze` reports 0 issues. |
| AC-13 | gate | `flutter test` reports 196/196 passing. |
| AC-14 | gate | `flutter build apk --debug` PASS (verified post-Task-004). |
| AC-15 | doc | `docs/features/settings.md` has 7 references to `AppThemeMode`; Domain table row + enum description + Presentation seam subsection + `saveThemeMode(AppThemeMode)` in contract table; persistence table unchanged (already correct). |
| AC-16 | test (file) | Two new pure-Dart test files: `app_theme_mode_test.dart` (6 tests) + `app_settings_test.dart` (7 tests). |
| AC-17 | manual (deferred) | Per spec §5 — verified at `/verify` time via real-device run. |

### Mock signature drift check

Verified for two sampled test files; all five other modified files compile and pass:
- `settings_provider_test.dart` line 36 — `_FakeSettingsRepository.saveThemeMode` signature is `Future<Either<Failure, void>> saveThemeMode(AppThemeMode mode)`.
- `widget_test.dart` line 33 — `_FakeSettingsRepository.saveThemeMode` signature is `Future<Either<Never, void>> saveThemeMode(AppThemeMode mode)`. No Flutter SDK `ThemeMode` anywhere in this file's fake.

### In-scope gaps

**None.** Every testable spec-012 AC is exercised.

### Out-of-scope gaps (carried forward — bug 016 territory; non-blocking)

These were flagged in the 2026-04-30 audit and explicitly deferred by spec 012 §6:

| Gap | Priority | Status |
|---|---|---|
| `_resolveLocale` helper duplicated in test files | Low | Now 6 copies (was 3 pre-spec — grew with newer feature tests). Bug 016 sub-item 9. |
| `_iconForEffectiveMode` icon-per-value widget assertions | Medium | Bug 016 sub-item 5. |
| `manualThemeMode == ThemeMode.system` defensive cycle branch | n/a | **Resolved structurally** — the new `AppThemeMode` is 2-value; the branch is now unreachable dead code that the type system prevents (no separate test needed). |
| `_FailingDataSource` for `try { } on Exception catch` × 4 branches | High | Bug 016 sub-item 7. Note: spec 012 added a try/catch in `getThemeMode()` for legacy-int — that path IS now tested (AC-8). The four `saveX` exception paths remain untested. |
| `DropdownButton onChanged(null)` defensive guard | Low | Bug 016 sub-item 8. |
| `_resolveLocale` `null deviceLocale` branch direct test | Low | Bug 016 sub-item 9. |
| No dedicated `settings_local_data_source_test.dart` | High | Bug 016 sub-item 10. The data source is exercised via repository integration test only. |
| Gear-icon-tap end-to-end (HomeScreen → Settings) | Medium | Bug 016 sub-item 3 / spec 008 carry-forward. |

---

## Aggregate notes

- 196/196 tests passing throughout the spec.
- `dart analyze`: zero issues across `lib/` AND `test/`.
- `flutter build apk --debug`: PASS.
- Constitution / MEMORY.md aggregate audit: zero new `!`, zero new `// ignore:`, zero color literals introduced, zero bare TODOs.
- **Defect caught + fixed during execution**: spec §3.6's assumption about `getString` returning `null` on int-stored keys was wrong (it throws `TypeError`). qa-engineer caught it during integration gate; architect added try/catch in `getThemeMode()`; AC-8 test now genuinely uses `int 1` seed and verifies graceful fallback. Without this catch, ANY pre-spec-012 device upgrading would have crashed on launch. **MEMORY.md candidate at `/verify` time**: SharedPreferences platform behavior on type-mismatched reads is throw-not-null.
- **Constitution drift caught + fixed during execution**: `analysis_options.yaml` was the bare Flutter default — no `analyzer:` block at all, despite constitution §7.4 prescribing strict modes + freezed exclude globs. Brought into compliance during Task 001 addendum. Two linter rules deferred (`directives_ordering`, `sort_pub_dependencies`) with documented rationale — both touch out-of-scope code.
- **Tooling drift caught**: `freezed 3.x` requires `@freezed abstract class` (not `@freezed class`), different from the freezed 2.x form in spec/plan/research. Architect agent caught + fixed inline during Task 003. **MEMORY.md candidate at `/verify` time**.

## Pre-`/verify` follow-ups (all optional / informational)

1. _(carry-forward)_ Bug 002 — typed logger introduction would let us narrow `getThemeMode()`'s broad `catch (_)` to `on TypeError catch (e) { logger.warn(...); }`.
2. _(carry-forward)_ Bug 010 — replace `e.toString()` in `CacheFailure.message` with explicit categorical messages once the `Failure.unknown(error, stack)` variant lands (bug 006).
3. _(carry-forward)_ Bug 016 — the test gaps above.
4. _(memory)_ Add to MEMORY.md "External API Quirks": `SharedPreferencesWithCache.getString` throws `TypeError` on type-mismatched stored values (e.g., a key written as `int` then read as `String`).
5. _(memory)_ Add to MEMORY.md "External API Quirks": freezed 3.x requires `abstract class` keyword on classes using `with _$ClassName` — different from freezed 2.x.

None of these block `/verify`. The feature is ready.
