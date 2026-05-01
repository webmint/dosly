# Research: Settings Domain Purify

**Date**: 2026-04-30
**Signals detected**: First adoption of `freezed` + `build_runner` codegen pipeline in this codebase. `pubspec.yaml` does not currently list any of `freezed`, `freezed_annotation`, or `build_runner`. No `*.freezed.dart` or `*.g.dart` file exists in `lib/`.

## Questions Investigated

1. **What's the canonical pubspec setup for freezed in modern Flutter?** → Per Context7 (`/rrousselgit/freezed`): `flutter pub add freezed_annotation dev:freezed dev:build_runner`. JSON support is opt-in via separate `json_annotation` / `json_serializable` packages — **not needed** for this spec since `AppSettings` is persisted field-by-field through `SettingsLocalDataSource` (one SharedPreferences key per field), not as a JSON blob.

2. **Is `with _$Foo` or `extends _$Foo` the current mixin syntax?** → `with _$Foo`. Confirmed in Context7's "Create Basic Immutable Data Class" example (`class Person with _$Person`). The `extends` form was an older API.

3. **Does `@freezed` require `sealed` for a plain immutable class with one factory?** → No. `sealed` is only needed for `freezed` union types (multiple factories — what `Failure` will eventually need). For `AppSettings` (single factory) the plain `@freezed class AppSettings with _$AppSettings { const factory AppSettings({...}) = _AppSettings; }` is the correct shape.

4. **Is `@Default(EnumValue.x)` supported for enum defaults?** → Yes. Context7's "Default Values and Assertions" example shows `@Default('localhost') String host` for primitives; the same `@Default` annotation works for enum values when the enum is a const. `AppLanguage.en` and `AppThemeMode.light` are both `const` enum values, so `@Default(AppLanguage.en) AppLanguage manualLanguage` is canonical.

5. **What is the correct codegen invocation?** → `dart run build_runner build --delete-conflicting-outputs` for one-shot, or `dart run build_runner watch -d` for development. Constitution §6.6 already documents the `--delete-conflicting-outputs` form.

6. **How do existing `themeMode` `int` values on disk behave when the data source switches from `getInt`/`setInt` to `getString`/`setString`?** → `SharedPreferencesWithCache.getString` is type-strict at the platform level: calling `getString` on a key whose stored value is an `int` returns `null` (not a stringified int, not a thrown error). The spec's `AppThemeMode.fromCodeOrDefault(null)` → `AppThemeMode.light` fallback handles this transparently. Verified by the existing data source's defensive pattern at `settings_local_data_source.dart:67–76` (the equivalent `getManualLanguage()` already uses `firstWhere(orElse:)` for unknown codes — same pattern, same behavior).

7. **Does `freezed` codegen interact with the existing `flutter gen-l10n` pipeline (which already generates `lib/l10n/app_localizations*.dart`)?** → No conflict. `flutter gen-l10n` is a Flutter-tool task triggered by `pubspec.yaml`'s `flutter: generate: true` flag and runs on `flutter pub get`. `build_runner` is a separate Dart tool that runs explicitly via `dart run build_runner build`. They write to different paths (`lib/l10n/` vs the source file's directory) and have no overlapping inputs. Both sets of generated files are committed to the repo per constitution §2.2.

8. **Is `*.freezed.dart` analyzer-excluded already?** → Yes. `analysis_options.yaml` (added by spec 001) already lists `**/*.freezed.dart` and `**/*.g.dart` under `analyzer: exclude:` (constitution §7.4). No analyzer changes needed.

## Alternatives Compared

### Codegen approach for AppSettings

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| `@freezed` (this proposal) | Constitution-mandated (§3.1); generates `==`/`hashCode`/`copyWith`; pairs with `.select()` value-equality; one canonical pattern | Adds first codegen pipeline (one-time setup cost); `.freezed.dart` files committed to repo (visible in PRs) | **Chosen** |
| Hand-rolled `==`/`hashCode`/`copyWith` (status quo) | Zero new tooling | Constitution-violating; fragile (4 fields × 3 methods = 12 places to drift); the bug we're fixing | Rejected |
| Plain `class` + `equatable` package | Smaller dep footprint; simpler than codegen | Constitution prescribes `freezed`; introducing `equatable` would be a divergent pattern; eventual `Failure` rewrite (bug 006) needs `freezed` anyway — adopt the canonical tool now | Rejected |

**Decision**: `@freezed class AppSettings with _$AppSettings` per constitution §3.1.

### Persistence migration strategy (legacy `int` themeMode)

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| Auto-fallback (this proposal) | Zero migration code; relies on platform-level type strictness; documented in spec §3.6 + AC-8/AC-17 | One-time visual reset (theme drops to `light`) for the developer's own device | **Chosen** |
| Read-both-formats (read int then string, prefer string) | Preserves the user's prior choice across the upgrade | Adds dual-format-read complexity to data source for a 1-user app; pushes the migration burden into source code that someone else has to read for years | Rejected |
| Schema version key + one-shot migration | Most "correct" for multi-user apps | Significant overkill for a personal app with 1 user; introduces a schema-versioning concept that the project doesn't otherwise use | Rejected |

**Decision**: Auto-fallback to `AppThemeMode.light` on legacy `int` reads. AC-8 verifies the behavior; AC-17 confirms graceful real-device behavior.

### `AppThemeMode` enum cardinality

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| 2-value `{ light, dark }` (this proposal) | Matches existing `manualThemeMode` field semantics ("Only `ThemeMode.light` and `ThemeMode.dark` are semantically valid"); `system` stays as orthogonal `useSystemTheme: bool` flag; impossible to construct an invalid persisted state | One mapping step at the seam (`useSystemTheme ? ThemeMode.system : map(manualThemeMode)`) | **Chosen** |
| 3-value `{ light, dark, system }` (mirrors Flutter's `ThemeMode`) | One-to-one shape with Flutter; trivial mapping at the seam | Re-introduces the contract violation we're fixing (the "shouldn't be stored here" gap); requires a runtime guard against `system` ever being persisted as `manualThemeMode` | Rejected |
| Single field `themeChoice: AppThemeMode { light, dark, system }` (collapse `useSystemTheme` + `manualThemeMode`) | Simpler entity shape; one source of truth | Breaks the existing schema (two stored keys → one); UI shape (toggle + selector) requires two pieces of state — collapsing them creates UI/data mismatch; violates "minimal changes" (§6.1) | Rejected |

**Decision**: `enum AppThemeMode { light, dark }` with a `code` field. The `system` concept stays in `useSystemTheme: bool`.

### Replacement for `AppSettings.effectiveLocale`/`effectiveThemeMode` getters

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| Remove getters entirely; seam reads four raw fields via `.select(...)` (this proposal) | No "what does effective mean in domain terms" question to answer; presentation-layer concern stays in presentation layer; four narrow `.select(...)` calls each subscribe only to their own field — finer-grained rebuild control than the single getter | Four `ref.watch` calls in `app.dart` instead of one; slight verbosity at the seam | **Chosen** |
| Keep getters but return domain types: `AppThemeMode? effectiveTheme` / `AppLanguage? effectiveLocale` | Continues the "expose derived shape" pattern | Domain types still encode "use system" as `null`, which is presentation semantics leaking into domain; `AppThemeMode? effectiveTheme = null` is harder to reason about than `useSystemTheme: bool` + `manualThemeMode: AppThemeMode` | Rejected |
| Keep getters returning Flutter types (status quo) | Zero seam changes | The bug we're fixing (Flutter in domain) | Rejected |

**Decision**: Remove both getters. The seam in `app.dart` reads `useSystemTheme`, `manualThemeMode`, `useSystemLanguage`, `manualLanguage` directly via four `.select(...)` calls and computes Flutter `themeMode` and `locale` inline.

## References

- Context7 — `/rrousselgit/freezed` — verified `@freezed` syntax, `@Default` for primitives + enums, `dart run build_runner build --delete-conflicting-outputs` codegen invocation
- `constitution.md` §2.1 (forbidden domain imports), §3.1 (freezed for entities), §3.2 (Either/Failure), §6.1 (minimal changes), §7.3 (initial dependencies command), §7.4 (analyzer exclude rules)
- `docs/architecture.md:7–23` — three-layer rule restated as the public architecture doc; this spec is the resolution of its own example
- `docs/features/settings.md:156–161` — the documented persistence contract (`String 'light'`/`'dark'`) that the implementation drifted away from; this spec restores it
- `.claude/memory/MEMORY.md` "Known Pitfalls" entry on `package:flutter/*` in `domain/` — this spec is the resolution
- `.claude/memory/MEMORY.md` "External API Quirks" entry on `unnecessary_import` lint trap — confirms `package:flutter/material.dart` re-exports many primitives, so dropping the import from `domain/` will not silently break anything that survives `dart analyze`
- `bugs/001-domain-layer-flutter-contamination.md` — the originating bug report
- `audits/2026-04-30-audit.md` — Critical Findings 4–8, recurring-issue mapping
