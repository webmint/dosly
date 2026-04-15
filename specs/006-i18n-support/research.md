# Research: Multi-Language Support

**Date**: 2026-04-14
**Signals detected**:
- External library not in project dependencies — `intl` (published pub package)
- Greenfield pattern not yet in codebase — first introduction of i18n infrastructure

## Questions Investigated

1. **Is the spec's import path (`package:flutter_gen/gen_l10n/app_localizations.dart`) still the current recommendation?**
   → **No.** Flutter has deprecated the *synthetic package* approach that backs that import path. The current recommendation is `synthetic-package: false` in `l10n.yaml`, with generated files written directly into the project source tree and imported from a normal `package:<name>/...` path. Source: Flutter breaking-changes doc "flutter generate i10n source" (via Context7 `/flutter/website`).

2. **What `intl` version pin should we use?**
   → Flutter's own docs recommend `intl: any` — i.e., allow the resolver to pick the version that matches the Flutter SDK's own transitive `intl` dependency. This avoids the "pinned version conflicts with Flutter's pinned version" failure mode. Applying `intl: any` and committing the resolved `pubspec.lock` is the idiomatic Flutter answer.

3. **Where should generated files live with `synthetic-package: false`?**
   → Flutter lets you either (a) omit `output-dir`, in which case generated files land in the same directory as `arb-dir` (here `lib/l10n/`), or (b) specify a separate `output-dir` (e.g., `lib/src/generated/i18n`). For a small feature with five keys, co-locating generated files in `lib/l10n/` alongside ARB sources is simplest. The generated files are committed so a fresh clone compiles before `flutter pub get` runs.

4. **Does `MaterialApp.router` need an explicit `localeResolutionCallback`?**
   → No. Flutter's default `BasicLocaleListResolutionCallback` already handles the desired fallback-to-English behavior for unsupported locales. Confirmed against Flutter's internationalization guide — only custom callback is needed when you want non-default matching rules.

## Alternatives Compared

### i18n toolchain
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| `flutter_localizations` + `intl` + `gen_l10n` (official) | First-party, well-documented, ARB is industry standard, codegen produces typed API, matches project preference for Flutter primitives | None material | **Chosen** |
| `easy_localization` (third-party) | Simpler runtime API, no codegen, loads JSON at runtime | Not first-party; string keys are magic strings (violates constitution §3.5); not type-safe | Rejected |
| Hand-rolled `Map<Locale, Map<String, String>>` | Zero deps | Reinvents gen_l10n; loses type safety; loses ARB translator tooling | Rejected |

### Generated-code hosting
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| `synthetic-package: false` (generated → `lib/l10n/`, committed) | Current Flutter recommendation, non-deprecated, files visible and committable, no dependency on virtual package magic | Generated files in VCS (standard Dart/Flutter convention — same as freezed, drift, riverpod codegen) | **Chosen** |
| `synthetic-package: true` (generated → `.dart_tool/flutter_gen/`) | What the spec originally assumed; auto-gitignored | **Deprecated** by Flutter; migration cost later; spec-drift risk | Rejected |

### ARB-source directory
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| `lib/l10n/` (Flutter-recommended default) | Matches Flutter guide; generated files co-locate naturally; short import path | Minor deviation from constitution's "`lib/core/` for cross-feature concerns" rule | **Chosen** — ARB files follow framework convention, not project-authored-code convention (documented in spec §9 risks) |
| `lib/core/l10n/` | Matches constitution's cross-feature placement | Fights Flutter's default `arb-dir`; requires extra config; no real benefit | Rejected |

## Decision Summary

1. **Toolchain**: `flutter_localizations` + `intl` + `flutter gen-l10n`.
2. **`intl` version**: `any` (let pub solver pick a version compatible with SDK `^3.11.1`).
3. **`l10n.yaml`**:
   - `arb-dir: lib/l10n`
   - `template-arb-file: app_en.arb`
   - `output-localization-file: app_localizations.dart`
   - `output-class: AppLocalizations`
   - `synthetic-package: false` ← **diverges from spec §3.1**
4. **Generated files**: committed in `lib/l10n/` (co-located with ARBs).
5. **Import path**: `package:dosly/l10n/app_localizations.dart` ← **diverges from spec §3.1**
6. **No custom `localeResolutionCallback`** — Flutter's default covers the fallback requirement.
7. **No `localeController`** — confirmed correct per spec; no UI in this feature would drive reactive state.

## Spec Deviations (flagged for user awareness)

The spec (drafted before research) assumed the deprecated synthetic-package import pattern. The plan adopts the current Flutter recommendation instead. User-facing consequences:
- AC-4 in the spec reads: "importable via `package:flutter_gen/gen_l10n/app_localizations.dart`". The plan updates this to `package:dosly/l10n/app_localizations.dart`.
- AC text reading ".dart_tool/flutter_gen/gen_l10n/*` NOT committed" (§4 Affected Areas, last row) no longer applies; instead, `lib/l10n/app_localizations*.dart` **are** committed.
- Nothing else in the spec is materially affected.

These are ACs-in-text updates, not scope changes — the feature still ships five translated strings across three locales with device-locale auto-detection. The plan proceeds under the modernized decisions and flags the spec text drift in Phase 2.5 cross-reference.

## References
- Flutter breaking-changes: `flutter generate i10n source` (deprecation of synthetic package) — via Context7 `/flutter/website`
- Flutter internationalization guide — via Context7 `/flutter/website`
- `lib/app.dart` — current `MaterialApp.router` setup (no delegates wired)
- `lib/features/home/presentation/widgets/home_bottom_nav.dart` — target widget for label changes
- MEMORY.md entries on `NavigationBar` const-ness and `_noop` pattern (both directly relevant to widget changes)
