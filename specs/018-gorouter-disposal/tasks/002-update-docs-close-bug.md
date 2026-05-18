# Task 002: Update docs and close bug 007

**Agent**: tech-writer
**Status**: Complete
**Files**:
- `docs/architecture.md` (modify § Routing)
- `bugs/007-gorouter-never-disposed.md` (modify front-matter + add Resolution)

**Depends on**: 001
**Blocks**: None
**Review checkpoint**: Yes
**Context docs**:
- `specs/018-gorouter-disposal/spec.md` — full spec context
- `specs/018-gorouter-disposal/plan.md` § File Impact — exact doc edit prescription

## Description

After Task 001 has landed the source changes, update `docs/architecture.md` § Routing to describe the new `@Riverpod(keepAlive: true)` provider pattern (removing the stale "kept on plain primitives" rationale) and flip `bugs/007-gorouter-never-disposed.md` to `Fixed` with a Resolution section linking back to spec 018.

This mirrors the docs/bookkeeping task pattern from spec 013 (`/fix` closing bug 002) and spec 015 (closing bug 004) — small, mechanical, tech-writer-owned, no source code touched.

## Change details

### `docs/architecture.md` — modify § Routing

Three edits, all inside the `## Routing` section (current source lines ~173–246):

**Edit 1: Update the inline code sample** (around line 183). Replace:

```dart
// lib/core/routing/app_router.dart
final GoRouter appRouter = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(...),
    GoRoute(path: '/settings', builder: ...),
    GoRoute(path: '/theme-preview', builder: ...),
  ],
);
```

With:

```dart
// lib/core/routing/app_router.dart
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(...),
      GoRoute(path: '/settings', builder: ...),
      GoRoute(path: '/theme-preview', builder: ...),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
```

Also update the surrounding paragraph (the one introducing the snippet) so it describes the new provider shape: "The router is declared as a function-form `@Riverpod(keepAlive: true)` provider in `lib/core/routing/app_router.dart` and consumed by `DoslyApp` via `MaterialApp.router(routerConfig: ref.watch(appRouterProvider))`. `ref.onDispose(router.dispose)` binds the router's `ChangeNotifier` lifecycle to the `ProviderScope`, so tests that override the provider (e.g., to inject a different route topology) get automatic teardown."

**Edit 2: Replace the "kept on plain primitives" bullet** in `### Conventions` (third bullet around line 242). Replace this bullet:

> - **`appRouter` mirrors the `themeController` pattern** — a top-level `final` declared next to its module, not a Riverpod provider. Riverpod will arrive with the first real feature; the router was deliberately kept on plain primitives.

With:

> - **`appRouter` is a function-form `@Riverpod(keepAlive: true)` provider.** The emitted symbol is `appRouterProvider`. Lifecycle is bound to the `ProviderScope` via `ref.onDispose(router.dispose)`. Tests that need a different route topology override with `appRouterProvider.overrideWith((ref) { final r = ...; ref.onDispose(r.dispose); return r; })` — the override callback's `Ref` mirrors the production lifecycle binding so tests do not call `dispose()` directly. The earlier rationale for keeping the router on plain primitives (Riverpod hadn't landed yet) was retired by spec 018.

**Edit 3: Update the provider wiring table** (around line 124, in `### Provider wiring`). Add a new row to the existing table:

| Provider | Type | Purpose |
|---|---|---|
| ... existing rows ... | ... | ... |
| `appRouterProvider` | `@Riverpod(keepAlive: true)` function | App-wide `GoRouter` instance with `onDispose`-bound lifecycle |

Leave the rest of `docs/architecture.md` untouched — Layering, theme module, i18n, entry point, etc. are unaffected.

### `bugs/007-gorouter-never-disposed.md` — modify

Two front-matter edits + one section append:

**Edit 1: Front-matter Status**

```markdown
# Before
**Status**: Open
**Severity**: Critical
**Source**: audit (audits/2026-04-30-audit.md) — RECURRING from spec 007
**Reported**: 2026-04-30
**Fixed**:

# After
**Status**: Fixed
**Severity**: Critical
**Source**: audit (audits/2026-04-30-audit.md) — RECURRING from spec 007
**Reported**: 2026-04-30
**Fixed**: <implementation-date>
```

For `<implementation-date>`, use the actual date Task 001 was completed (read from `git log` of `lib/core/routing/app_router.dart` after Task 001 lands — MEMORY L147 pattern). If Task 001 and Task 002 land the same day, use today's date.

**Edit 2: Append a Resolution section** at the bottom of the file (after the existing `## Fix Notes` section):

```markdown
## Resolution

Closed by [spec 018](../specs/018-gorouter-disposal/spec.md). `lib/core/routing/app_router.dart` now declares a function-form `@Riverpod(keepAlive: true) GoRouter appRouter(Ref ref)` provider that registers `ref.onDispose(router.dispose)`. The previous top-level `final GoRouter appRouter = ...` is gone; `lib/app.dart` reads `ref.watch(appRouterProvider)`. Test 4 of `test/core/routing/app_router_test.dart` uses `appRouterProvider.overrideWith((ref) { ... ref.onDispose(r.dispose); return r; })` instead of a manual `testRouter.dispose()` call — the `_buildTestRouterWithSentinel()` helper remains in place because its purpose is a different route topology (sentinel child route), not a lifecycle workaround.

`docs/architecture.md` § Routing was updated in the same spec to describe the new pattern.
```

Do not edit the `## Description`, `## File(s)`, `## Evidence`, or `## Fix Notes` sections — those record the bug as it was reported (historical truth), and the Resolution section is the record of how it was closed.

## Done when

- [x] `grep -nE "kept on plain primitives" docs/architecture.md` returns zero matches
- [x] `grep -nE "appRouterProvider" docs/architecture.md` returns ≥ 2 matches (the new code sample + the conventions bullet; bonus from the provider wiring table)
- [x] `grep -nE "@Riverpod\(keepAlive: true\)" docs/architecture.md` returns ≥ 1 match within the § Routing section
- [x] `grep -nE "ref\.onDispose" docs/architecture.md` returns ≥ 1 match within the § Routing section
- [x] `grep -nE "^\*\*Status\*\*: Fixed$" bugs/007-gorouter-never-disposed.md` returns ≥ 1 match
- [x] `grep -nE "^\*\*Fixed\*\*: 20" bugs/007-gorouter-never-disposed.md` returns ≥ 1 match (Fixed date is set to a 20xx-xx-xx value, not empty)
- [x] `grep -nE "## Resolution" bugs/007-gorouter-never-disposed.md` returns ≥ 1 match
- [x] `grep -nE "spec.018|018-gorouter-disposal" bugs/007-gorouter-never-disposed.md` returns ≥ 1 match
- [x] `dart analyze 2>&1 | head -40` is clean (docs and bug-file edits do not affect source, but the gate is the workflow's standard close)
- [x] `flutter test` still passes (no regressions from Task 001 introduced by the doc edits — should be a no-op)

**Spec criteria addressed**: AC-12, AC-13

## Contracts

### Expects

- Task 001 has landed: `lib/core/routing/app_router.dart` is a `@Riverpod(keepAlive: true)` provider, `appRouterProvider` exists in `lib/core/routing/app_router.g.dart`, and the test suite is green
- `docs/architecture.md` § Routing contains the inline code sample showing `final GoRouter appRouter = GoRouter(...)` and the "kept on plain primitives" bullet under `### Conventions`
- `bugs/007-gorouter-never-disposed.md` front-matter has `Status: Open` and an empty `Fixed:` field

### Produces

- `docs/architecture.md` § Routing's inline code sample shows the new `@Riverpod(keepAlive: true)` function-form provider
- `docs/architecture.md` § Routing > Conventions no longer contains the phrase "kept on plain primitives"; the replacement bullet describes `appRouterProvider`, `ref.onDispose(router.dispose)`, and the `appRouterProvider.overrideWith(...)` test idiom
- `docs/architecture.md` § Provider wiring table includes a row for `appRouterProvider`
- `bugs/007-gorouter-never-disposed.md` front-matter has `**Status**: Fixed` and a populated `**Fixed**:` date
- `bugs/007-gorouter-never-disposed.md` contains a `## Resolution` section linking to spec 018

## Completion Notes

**Completed**: 2026-05-18
**Files changed**:
- `docs/architecture.md` — 4 edits inside § Routing + 1 edit to the App-wide-state code snippet (legitimate scope extension; the snippet on line 87 still showed `routerConfig: appRouter` which contradicts post-Task-001 reality) + 1 row added to the provider wiring table
- `bugs/007-gorouter-never-disposed.md` — front-matter Status flipped, Fixed date set to 2026-05-18, `## Resolution` section appended

**Contract**: Expects 3/3 verified | Produces 5/5 verified

**Verification**:
- `dart analyze`: No issues found
- `flutter test`: All 227 tests still pass (no source changes, no regressions)
- AC-12 greps: zero matches of "kept on plain primitives"; 4 matches of `appRouterProvider`; 6 matches of `@Riverpod(keepAlive: true)`; 4 matches of `ref.onDispose` — all in `docs/architecture.md`
- AC-13 greps: `Status: Fixed`, `Fixed: 20...`, `## Resolution`, `spec 018` link — all 1+ matches in `bugs/007-gorouter-never-disposed.md`

**Notes**: This task was pure docs + bookkeeping per spec design. No code review agent launched — diff is small markdown-only with grep-verifiable predicates; self-review confirmed no lying comments and faithful preservation of unrelated sections.
