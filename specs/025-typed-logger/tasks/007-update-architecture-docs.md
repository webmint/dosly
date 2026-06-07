# Task 7: Update architecture docs

**Agent**: tech-writer
**Files**: `docs/architecture.md`
**Depends on**: 6
**Review checkpoint**: No
**Context docs**: `docs/architecture.md`
**Status**: Complete

## Completion Notes
**Completed**: 2026-06-01
**Files changed**: `docs/architecture.md`
**Contract**: Expects 2/2 verified | Produces 2/2 verified
**Notes**: Stale "deferred to Bug 017" sentence in the AppBootstrap error bullet replaced (now points to bug 003 for bootstrap-error UI surfacing). New `### Logging` subsection (pipeline, single sanitize choke point, PHI/Failure-aware redaction, release no-op via `Level.OFF`, consumption example). Added `loggerProvider` row to the Provider wiring table. Docs-only — no code review.

**Description**:
Reflect the now-shipped logging infrastructure in the architecture docs. The existing line stating that structured failure logging is "deferred to Bug 017 (typed logger not yet built)" is now stale — the router error path logs through the typed logger.

**Change details**:
- In `docs/architecture.md`:
  - Update the line (~`:108`) that says structured failure logging is "deferred to Bug 017 (typed logger not yet built) — the error branch is UI-only for now." to reflect that the typed logger now exists and the router error path logs through it (sanitized, debug-only).
  - Add a short "Logging" subsection documenting: `lib/core/logging/` pipeline, the single `Logger.root` sanitizing listener as the PHI choke point, `loggerProvider` as the consumption point, and the release no-op (`Level.OFF`).

**Done when**:
- [ ] The stale "deferred to Bug 017" sentence is updated to reflect the shipped logger
- [ ] A "Logging" subsection describes the pipeline, sanitize choke point, and release behavior
- [ ] No other unrelated doc content is changed

**Spec criteria addressed**: (documentation of AC-2, AC-3, AC-9 — supports Key Rule #7)

## Contracts

### Expects
- The router pilot is wired (Task 6) — `app_router.dart` logs via `loggerProvider`.
- `docs/architecture.md` contains the "deferred to Bug 017" sentence.

### Produces
- `docs/architecture.md` no longer states logging is "deferred to Bug 017" and contains a "Logging" subsection mentioning `core/logging` and the sanitize listener.
