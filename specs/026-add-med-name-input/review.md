# Review Report: 026-add-med-name-input

**Date**: 2026-06-12 (re-run — now covers the full branch: feat + startup fix + theme fix)
**Spec**: specs/026-add-med-name-input/spec.md
**Changed files**: 6 source/test + 4 regenerated l10n bindings (`.claude/**`, `specs/**`, `docs/**` excluded)

Branch commits reviewed:
- `feat(meds)` — name `TextField` + no-op Save button + 2 l10n keys
- `fix(startup)` — `sharedPreferences` reads `sharedPreferencesInitProvider.requireValue`; `AppBootstrap` data branch mounts `DoslyApp` directly (no nested scope) + regression test
- `fix(theme)` — global `inputDecorationTheme` outlined/transparent; redundant call-site border removed

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 7 — **Overall: PASS**

No exploitable issues, no constitution violations. Highlights:
- **`requireValue` is correctly gated** — `sharedPreferencesProvider` is only reachable via `AppBootstrap`'s `data` branch (after init resolved); loading/error are graceful, recoverable branches (splash / retry). No attacker-influenced input reaches the init future → no externally-triggerable DoS.
- **Removing the nested `ProviderScope` doesn't change prefs isolation/exposure** — same process, same single keepAlive instance, same root container.
- **Prefs `allowList` unchanged** — still settings-only (`themeMode`, `useSystemTheme`, `useSystemLanguage`, `manualLanguage`); no PHI key added (constitution §4.2.1).
- **No PHI leak** — `_nameController.text` is never read/logged/persisted; the only `logger` reference (`app_bootstrap.dart:54`) just registers the existing PHI-sanitizing pipeline early. No `print`/`debugPrint` in changed files.
- **Error screen leaks no internal detail**; **theme change is cosmetic / security-neutral**; **non-blocking `main()` preserved** (§4.2.1).

## Performance Review

- High: 0 | Medium: 1 | Low: 2

- **Medium** — `lib/core/providers/shared_preferences_provider.dart`: `sharedPreferences` (keepAlive) uses `ref.watch(sharedPreferencesInitProvider).requireValue`. If the init provider is ever invalidated **while `sharedPreferences` is alive** (data→loading→data), `sharedPreferences` rebuilds on the `loading` transition and `requireValue` throws `StateError`, briefly erroring the whole settings tree + a double rebuild.
  Recommendation: the analyst suggests `ref.read(...)` to drop the watcher. **Caveat (reviewer note):** this scenario is currently **unreachable** — the only `invalidate(sharedPreferencesInitProvider)` call is the error-branch Retry, which only fires *before* `DoslyApp`/the settings tree mount, so `sharedPreferences` isn't alive yet; and a resolved init never transitions again while mounted. Also, switching to `ref.read` would contradict the standing MEMORY pitfall "`ref.read` inside provider build breaks reactivity." Net: low-urgency, latent-only. If addressed, prefer documenting the gating with an inline comment over a bare `ref.read`, or guard with `valueOrNull` + a fallback. Not blocking.
- **Low** — `lib/core/theme/app_theme.dart`: `lightTheme`/`darkTheme` rebuild (3 `OutlineInputBorder` allocations each) on every access. Cache as `static final ThemeData lightTheme = _build(...)`. One-line, strictly better; cosmetic.
- **Low** — `lib/app_bootstrap.dart`: `_bootstrapShell` allocates a fresh `MaterialApp` per `AppBootstrap.build`; compounds the getter allocation above. Resolved by the getter-caching Low; no standalone action.
- const-correctness on changed widgets: clean. Removing the nested `ProviderScope` is a net positive (single container, no override-propagation bug).

## Test Assessment

- Startup regression test: **adequate & non-tautological** — drives the real `DoslyApp → settingsNotifier → settingsRepository → sharedPreferences → requireValue` chain (only `sharedPreferencesInitProvider` overridden) and asserts `takeException() isNull` + `find.byType(DoslyApp)`. Loading/error/retry branches remain covered and unaffected.
- Verdict: **GAPS FOUND** (all proportionate; none block)

| Priority | Gap | File |
|----------|-----|------|
| Medium | AC-6: DE/UK values for `medsAddNameLabel` / `medsAddSaveButton` asserted only under EN | `add_medication_modal_test.dart` |
| Medium | AC-1: controller disposal not tested (unmount path) | `add_medication_modal_test.dart` |
| Low | Theme: no assertion that `inputDecorationTheme.filled == false` / border is `OutlineInputBorder` (would catch a future regression to filled-gray) | `add_medication_modal_test.dart` |
| Low | Regression test could assert a known `DoslyApp` child loaded without error state (stronger than `takeException`) | `app_bootstrap_test.dart` |

- `requireValue` read-while-loading edge case: **proportionate NOT to test** (structurally unreachable; documented as a programmer error). Theme change untested: **acceptable for cosmetic** but the low-cost theme-propagation assertion above would future-proof it.

## Notes for /verify
- The startup + theme changes are `fix(...)` commits mixed into this feature branch (per user request to test on-device); they are outside spec 026's ACs but should be weighed in the verdict.
- No Critical/High anywhere. The one Medium (perf) is latent-only and currently unreachable. The qa gaps are the same proportionate ones plus a cosmetic theme assertion.
