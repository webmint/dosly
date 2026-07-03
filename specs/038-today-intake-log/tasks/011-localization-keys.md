# Task 011: Today localization keys

**Agent**: mobile-engineer
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_uk.arb` (+ regenerated `app_localizations*.dart`)
**Depends on**: None
**Blocks**: 014, 015
**Context docs**: docs/features/i18n.md
**Review checkpoint**: No

**Description**:
Add all user-facing strings for the Today screen to the three ARB files, with `@`-descriptions in `app_en.arb`, following the existing meds key conventions. Regenerate `AppLocalizations`.

**Change details**:
- Add keys (English shown; translate to DE + UK): `todayTitle` ("Today"), `todayDateHeader` (or reuse `MaterialLocalizations` date formatting — if a label is needed), `todayMarkTaken` ("Take"), `todaySkip` ("Skip"), `todayUndo` ("Undo"), `todayStatusTaken` ("Taken"), `todayStatusSkipped` ("Skipped"), `todayEmptyTitle` ("Nothing due today"), `todayEmptyBody` ("You have no doses scheduled for today."), and (if used) `todayLoadError` ("Couldn't load today's doses.").
- `@`-descriptions for each new key in `app_en.arb` only.
- Consume exclusively via `context.l10n.*` (no direct `AppLocalizations.of(context)!`).
- Regenerate via the l10n pipeline (build/gen-l10n).

**Contracts**:

### Expects
- `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` exist; `context.l10n` extension exists.

### Produces
- All new `today*` keys exist in all three ARB files with `@`-descriptions in `app_en.arb`.
- `AppLocalizations` exposes getters for each new key (regenerated).

**Done when**:
- [ ] Every new key present in en/de/uk with en `@`-descriptions.
- [ ] `AppLocalizations` regenerated and compiles.
- [ ] `dart analyze` passes.

**Spec criteria addressed**: AC-14

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-02
**Files changed**: `l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (+ regenerated `app_localizations*.dart`)
**Contract**: Expects [ok] | Produces [2/2] — 9 `today*` keys in all 3 locales, 9 `@`-descriptions in en, 9 generated getters.
**Notes**: `flutter gen-l10n` (l10n.yaml config). `todayTitle` kept distinct from `bottomNavToday` (AppBar vs nav label). No date key (screen uses `MaterialLocalizations`). `dart analyze` clean. Keys not yet consumed (Tasks 014/015).
