## Feature Summary: 022 — Settings Data-Layer Error Containment

### What was built
Made the settings repository crash-proof against corrupt or wrong-type cached preferences. Previously a malformed value in storage could throw an uncaught error past the app's startup splash and freeze the app; now `load()` returns a typed result and falls back to safe defaults, and every save operation contains all failures instead of leaking platform error details. Enforces constitution §3.2 ("exceptions never escape the data layer") and closes bugs 014 and 010.

### Changes
- Task 1: Either-ify `load()` and align all consumers — changed `SettingsRepository.load()` to synchronous `Either<Failure, AppSettings>`, wrapped the read in `try/catch`, made the notifier fold to safe defaults + surface the failure; realigned 7 test fakes + the repo-impl test in the same atomic change.
- Task 2: Widen `save*` catches — the four save methods now catch all throwables (incl. `Error` subtypes) and return `Failure.unknown` instead of `CacheFailure(e.toString())`, removing a filesystem-path leak (CWE-209).
- Task 3: Failure-path tests — added throwing data-source doubles and tests proving wrong-type reads, getter throws, and `Error`-throwing saves are all contained; suite grew 230 → 241.

### Files changed
- `lib/features/settings/domain/repositories/` — 1 file modified (contract)
- `lib/features/settings/data/repositories/` — 1 file modified (impl: load + 4 saves)
- `lib/features/settings/presentation/providers/` — 1 file modified (notifier fold + docstrings)
- `test/` — 8 files modified (2 with substantial new failure-path tests; 6 mechanical fake-signature alignments)
- [Total: 11 files changed, 452 insertions, 63 deletions]

### Key decisions
- Contract shape: synchronous `Either<Failure, AppSettings> load()` (research Option A) over per-getter guards — satisfies §3.2's "return Either" letter and aligns `load()` with the four `save*` siblings.
- Failure surfacing: route the load `Left` to the existing `settingsErrorsProvider` stream + default state, rather than waiting on the unshipped typed logger (bug 017).
- Error variant: `Failure.unknown(e, st)` for all uncategorized throws — captures the stack and avoids leaking platform path strings via `toString()`.
- Containment point: one `try/catch` at the repository `load()`, not per data-source getter — keeps the boundary single and obvious (KISS).

### Deviations from plan
- Task 2: scope expanded by one file — code review (Critical) caught that the notifier test's fake still fabricated/asserted the old `CacheFailure`; realigned the fake + 5 assertions to `UnknownFailure` in the same task so the suite honestly reflects production.

### Acceptance criteria
- [x] AC-1: `load()` is sync `Either<Failure, AppSettings>` with an accurate dartdoc (no "Never fails")
- [x] AC-2: wrong-type cached value for any settings key never throws out of `load()`
- [x] AC-3: data-source throw during load → `Left(Failure.unknown(...))`
- [x] AC-4: success → `Right(settings)` with correct values
- [x] AC-5: load `Left` → `const AppSettings()` state + failure emitted to `settingsErrorsProvider`
- [x] AC-6: load `Right` → loaded `AppSettings` state
- [x] AC-7: each `save*` → `Left(Failure.unknown(...))` on any throwable, incl. `Error`
- [x] AC-8: no `save*` puts raw `e.toString()` into a `CacheFailure`
- [x] AC-9: existing happy-path + legacy-int `themeMode` fallback tests still pass
- [x] AC-10: `dart analyze` clean; `flutter test` (241) passes
