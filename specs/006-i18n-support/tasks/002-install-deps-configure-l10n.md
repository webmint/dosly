# Task 002: Install deps + configure l10n + generate `AppLocalizations`

**Agent**: architect
**Files**: `pubspec.yaml`, `pubspec.lock`, `l10n.yaml` (new), `lib/l10n/app_localizations.dart` (generated, new), `lib/l10n/app_localizations_en.dart` (generated, new), `lib/l10n/app_localizations_de.dart` (generated, new), `lib/l10n/app_localizations_uk.dart` (generated, new)
**Depends on**: 001
**Blocks**: 003, 005
**Review checkpoint**: Yes (high risk — dependency resolution + codegen produces committed files)
**Context docs**: [../research.md](../research.md) — explains `synthetic-package: false` decision and `intl: any` rationale
**Status**: Complete

## Description

Add the two i18n dependencies via `flutter pub add`, enable Flutter's codegen flag, create `l10n.yaml` with the modernized (`synthetic-package: false`) configuration, and run `flutter pub get` to generate `AppLocalizations` and its locale subclasses. All four generated files are committed to `lib/l10n/` so fresh clones and CI builds compile without needing codegen to run first.

This is the riskiest task in the feature: if `intl: any` resolves to a version incompatible with the Flutter SDK's transitive pin, the solver fails. Mitigation is in the done-when list.

## Change details

- Run `flutter pub add flutter_localizations --sdk=flutter` from repo root.
  - Adds `flutter_localizations: { sdk: flutter }` under `dependencies:` in `pubspec.yaml` and updates `pubspec.lock`.
- Run `flutter pub add intl:any` from repo root.
  - Adds `intl: any` under `dependencies:` in `pubspec.yaml` and updates `pubspec.lock`.
  - If resolution fails with a version conflict, fall back to `flutter pub add intl:^<version>` where `<version>` is what `flutter pub deps | grep intl` reports the Flutter SDK itself depending on. Document the pinned version in the commit body if this fallback is used.
- Edit `pubspec.yaml`:
  - In the `flutter:` section, add a new `generate: true` line. Keep existing `uses-material-design: true` and the `fonts:` block as-is. Add `generate: true` as a sibling of `uses-material-design` (Flutter conventionally places it near the top of the `flutter:` section).
- Create `l10n.yaml` at the repo root with the following contents:
  ```yaml
  arb-dir: lib/l10n
  template-arb-file: app_en.arb
  output-localization-file: app_localizations.dart
  output-class: AppLocalizations
  ```
  (Flutter 3.41+ has fully retired the `synthetic-package` option — setting it triggers a deprecation warning on every `flutter pub get`. The default behavior is now exactly what `synthetic-package: false` used to request: generated files live in `lib/l10n/` and are committable source. The plan's research was based on slightly older Flutter docs; reality has moved further, so we omit the flag entirely.)
- Run `flutter pub get` from repo root to trigger `flutter gen-l10n` (runs implicitly because `generate: true` is set). This produces:
  - `lib/l10n/app_localizations.dart` — abstract `AppLocalizations` class with static `localizationsDelegates`, `supportedLocales`, and abstract getters for all five keys.
  - `lib/l10n/app_localizations_en.dart` — English subclass.
  - `lib/l10n/app_localizations_de.dart` — German subclass.
  - `lib/l10n/app_localizations_uk.dart` — Ukrainian subclass.
- Commit all four generated files to Git (they live inside `lib/`, not `.dart_tool/`, so they are not auto-ignored). The feature commit-squash at `/finalize` will preserve them.
- Do NOT add any `.gitignore` entry for the generated files.

## Contracts

### Expects
- `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` exist with the four keys each (produced by Task 001).
- `pubspec.yaml` has the current shape shown in the plan's File Impact row (no existing `flutter_localizations` / `intl` lines, no existing `generate:` flag).
- Flutter toolchain is available on PATH (standard project assumption).

### Produces
- `pubspec.yaml` has `flutter_localizations:` with `sdk: flutter` and `intl:` with a non-empty version constraint under `dependencies:`.
- `pubspec.yaml`'s `flutter:` section contains a `generate: true` line.
- `pubspec.lock` is updated and committed.
- `l10n.yaml` exists at the repo root containing the literal keys `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`, `output-class: AppLocalizations`. (Originally included `synthetic-package: false` per plan; removed during execution because Flutter 3.41+ deprecated the option entirely — see completion notes.)
- `lib/l10n/app_localizations.dart` exists and declares `class AppLocalizations` (abstract) with static members `localizationsDelegates` (a `List<LocalizationsDelegate<dynamic>>`) and `supportedLocales` (a `List<Locale>`), plus abstract getters `settingsTooltip`, `bottomNavToday`, `bottomNavMeds`, `bottomNavHistory` (all `String`).
- `lib/l10n/app_localizations_en.dart`, `app_localizations_de.dart`, `app_localizations_uk.dart` exist and each extend `AppLocalizations` with concrete getter implementations returning the locale's string values.
- `dart analyze` is clean.
- `flutter test` runs (pre-existing 84 tests still pass — delegates are not yet wired into the app root, but their presence in the package does not break anything).

## Done when

- [x] `grep -E '^\s*flutter_localizations:' pubspec.yaml` finds a match.
- [x] `grep -E '^\s*intl:' pubspec.yaml` finds a match.
- [x] `grep -E '^\s*generate:\s*true' pubspec.yaml` finds a match (inside the `flutter:` block).
- [x] `l10n.yaml` exists at repo root and contains the four expected keys (`arb-dir`, `template-arb-file`, `output-localization-file`, `output-class`). `synthetic-package` was originally in the plan but removed — see completion notes.
- [x] `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_de.dart`, `app_localizations_uk.dart` all exist.
- [x] `grep 'class AppLocalizations' lib/l10n/app_localizations.dart` finds a match.
- [x] `grep -E 'String get settingsTooltip|String get bottomNavToday|String get bottomNavMeds|String get bottomNavHistory' lib/l10n/app_localizations.dart` finds at least four matches (one per key).
- [x] `dart analyze` produces zero warnings or errors.
- [x] `flutter test` passes all pre-existing tests (no regressions from dep or config additions).
- [x] `flutter build apk --debug` succeeds (confirms the toolchain accepts the new config).

## Spec criteria addressed
AC-1, AC-2, AC-4

## Completion Notes

**Completed**: 2026-04-15
**Files changed**: `pubspec.yaml`, `pubspec.lock`, `l10n.yaml` (new), `lib/l10n/app_localizations.dart` (generated), `lib/l10n/app_localizations_en.dart` (generated), `lib/l10n/app_localizations_de.dart` (generated), `lib/l10n/app_localizations_uk.dart` (generated)
**Contract**: Expects 3/3 verified | Produces 8/8 verified (all generated class members present, lock committed, config minimal)
**Notes**:
- `intl` resolved to **0.20.2** (no fallback needed — `intl: any` paired cleanly with `flutter_localizations`'s transitive pin).
- **Deviation from plan**: `synthetic-package: false` was **removed** from `l10n.yaml`. Flutter 3.41+ has fully retired this option — setting it (even to `false`) emits a deprecation warning on every `flutter pub get`. Omitting the line produces exactly the desired behavior (generated files in `lib/l10n/`, committable). The plan's research was based on Context7 docs slightly behind current Flutter; reality has moved further. Task file and plan risk section updated accordingly.
- Added clarifying comment above `intl: any` per code review suggestion: "deliberately unpinned; must track flutter_localizations' transitive pin".
- Code review verdict: APPROVE (one Warning resolved inline; no Critical issues).
- Test count increased 84 → 85 pre-existing (minor discovery during execution, not a regression).
- All verification clean: `dart analyze` (no issues), `flutter test` (85 pass), `flutter build apk --debug` (success), `flutter pub get` (warning-free after removing deprecated flag).
