# Task 005: Update architecture docs and close Bug 013

**Agent**: tech-writer
**Files**: `docs/architecture.md`, `bugs/013-main-blocks-on-async.md`
**Depends on**: 004
**Blocks**: None
**Context docs**: `docs/architecture.md` (Bootstrap + provider-wiring sections)
**Review checkpoint**: No
**Status**: Complete

## Description

Documentation last, so the writeup reflects what actually shipped, not what was planned (MEMORY L226). Update the architecture doc's Bootstrap section — which currently documents the old blocking `main()` verbatim (lines 93-120) — to describe the new non-blocking flow, and add the new provider to the wiring table. Then mark Bug 013 Fixed with a Resolution section.

## Change details

- In `docs/architecture.md`:
  - Rewrite the "Bootstrap: `SharedPreferencesWithCache`" section: `main()` is now synchronous and calls `runApp(const ProviderScope(child: AppBootstrap()))`; `AppBootstrap` watches `sharedPreferencesInitProvider` (async create), showing a splash while loading and a retry screen on error, and on success nests a `ProviderScope` overriding the synchronous `sharedPreferencesProvider` so the settings tree is unchanged. Replace the old blocking `main()` code sample with the new one. Keep the note that the sync `sharedPreferencesProvider` is a throwing placeholder satisfied by the override.
  - Add a row to the provider-wiring table: `sharedPreferencesInitProvider` | `@riverpod` function (Future) | Async creation of the prefs instance; gated by `AppBootstrap` before the sync provider is overridden.
- In `bugs/013-main-blocks-on-async.md`:
  - Set `**Status**: Fixed` and fill `**Fixed**: 2026-05-23` (or the actual completion date).
  - Add a `## Resolution` section describing the AppBootstrap + `sharedPreferencesInitProvider` fix, the nested-scope override, and that logging of the failure was deferred to Bug 017.

## Contracts

### Expects
- `lib/main.dart` is synchronous and runs `AppBootstrap` (Task 004).
- `lib/app_bootstrap.dart` declares `AppBootstrap`; `sharedPreferencesInitProvider` exists (Tasks 002, 004).

### Produces
- `docs/architecture.md` Bootstrap section references `AppBootstrap` and `sharedPreferencesInitProvider` and no longer shows an `await` in the `main()` sample.
- `bugs/013-main-blocks-on-async.md` contains `**Status**: Fixed` and a `## Resolution` section.

## Done when
- [x] `docs/architecture.md` Bootstrap section and provider table reflect the new flow.
- [x] No stale `await SharedPreferencesWithCache.create` remains in the architecture doc's `main()` sample.
- [x] `bugs/013-main-blocks-on-async.md` is marked Fixed with a Resolution section.

**Spec criteria addressed**: AC-10

## Completion Notes
**Completed**: 2026-05-23
**Files changed**: docs/architecture.md, bugs/013-main-blocks-on-async.md
**Contract**: Expects [2/2 verified] | Produces [2/2 verified]
**Notes**: Rewrote the architecture Bootstrap section + provider table; tech-writer also caught and fixed a stale "Entry point" section (still in architecture.md, in scope). Bug 013 marked Fixed (2026-05-23) with Resolution. No source touched. Code review inline (docs-only) — APPROVE.
