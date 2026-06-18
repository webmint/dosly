# Research: Medications List Screen

**Date**: 2026-06-18
**Signals detected**: Architectural decision with multiple valid approaches — first reactive (`watch`) drift read in the codebase; first `Stream`-based repository boundary; placement of a pure Clock-injected domain derivation.

## Questions Investigated

1. **How to reactively read medications + their time slots so the stream re-emits when *either* table changes?**
   → drift's `.watch()` works on any `Selectable`, including joins, and a watched query auto-tracks every table it reads (`readsFrom`). A single `select(medications).join([leftOuterJoin(timeSlots, …)]).watch()` re-emits on changes to **both** tables. The alternative in drift's own "relationships" example uses `Rx.combineLatest2` from **rxdart** — which is **not** a project dependency. **Decision: single watched left-outer join, group `TypedResult` rows by medication in Dart.** No new dependency; typed query (constitution §4.3.1 "typed queries over raw SQL").

2. **How to honor §3.2 (`Either` at boundaries) over a stream?**
   → The repository read returns `Stream<Either<Failure, List<Medication>>>`. An `async*` generator wraps the data-source stream in a `try`, `yield Right(mapped)` per emission, and `yield Left(Failure.unknown(e, st))` on any thrown error (including `medicationFromRows`' corrupt-row `StateError`). The provider folds each emission with `either.fold((f) => throw f, (m) => m)`, producing `AsyncValue<List<Medication>>` (`Right` → `AsyncData`, `Left`/throw → `AsyncError(Failure)`) — exactly the §3.2 convention and the `MedicationsList` example in constitution §7.2.

3. **Where does the Clock-injected activity / course-day derivation live?**
   → It is **synchronous and infallible**, so it is NOT a use case (use cases are `Future<Either<…>>`). §2.2 sanctions `domain/{entities, value_objects, repositories, usecases}` — no `services/`. **Decision: pure `now`-parameterized functions in `domain/value_objects/`** (`resolveMedicationActivity(Medication, DateTime now)`, `CourseProgress.resolve(CourseType, DateTime now)`), with leaf enums (`MedicationActivityStatus`, `CoursePhase`) in `domain/entities/` alongside `medication_form.dart`. The caller (presentation) supplies `now` from `package:clock`'s `clock.now()` — matching how `add_medication.dart` already uses `clock`. Passing `now` as a parameter (rather than reading ambient clock inside) makes the derivation trivially testable with literal instants and avoids ambient-clock surprises across widget rebuilds.

4. **Stream provider shape under Riverpod 3 / generator 4?**
   → Confirmed in-repo precedent: `settingsErrors` is `@riverpod Stream<Failure> settingsErrors(Ref ref)` exposing `AsyncValue<Failure>` (`settings_provider.dart:192`). The list provider mirrors it: `@riverpod Stream<List<Medication>> medicationsList(Ref ref)`.

## Alternatives Compared

### Reactive read strategy
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| Single watched left-outer join + group in Dart | Re-emits on both tables; no new dep; type-safe; one query | Must group `(med × slot)` rows (incl. null-slot meds) in Dart | **Chosen** |
| `Rx.combineLatest2(medications.watch(), slots.watch())` | Matches drift's relationship example | Requires adding **rxdart**; more moving parts | Rejected (new dependency, §2.3) |
| `customSelect(... , readsFrom: {medications, timeSlots}).watch()` | Full SQL control | Raw SQL strings (against §4.3.1); manual row parsing | Rejected |
| `Future getAll()` + `ref.invalidate` after mutations | Matches existing `Future<Either>` idiom exactly | Not reactive; stale-list bugs; spec AC-1/AC-19 require live updates | Rejected (spec decision) |

### Repository boundary over a stream
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| `Stream<Either<Failure, List<Medication>>>` (async* + try) | Honors §3.2; folds cleanly to `AsyncValue`; one error path | Slightly more verbose than a bare stream | **Chosen** |
| `Stream<List<Medication>>` (let drift errors surface as `AsyncError`) | Less code | Bypasses the §3.2 "repository returns `Left`" contract; loses typed `Failure` | Rejected |

### Derivation placement
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| Pure `now`-param functions in `domain/value_objects/` | Testable with literals; no new folder; respects §2.2 | Functions, not a class API | **Chosen** |
| `usecases/` returning `Future<Either>` | "Canonical" use-case home | Sync+infallible ⇒ `Future<Either>` is dishonest boilerplate | Rejected |
| `domain/services/` | Conceptually clean | Folder not sanctioned by §2.2 → would be a constitution deviation | Rejected |

## References
- drift streams (`watch()` on any `Selectable`, incl. joins; auto `readsFrom` tracking) — https://github.com/simolus3/drift/blob/develop/docs/content/dart_api/streams.md
- drift joins (`leftOuterJoin`, `readTable`/`readTableOrNull`) — https://github.com/simolus3/drift/blob/develop/docs/content/dart_api/select.md
- drift relationships example (the rxdart `combineLatest2` approach we reject) — https://github.com/simolus3/drift/blob/develop/docs/content/examples/relationships.md
- In-repo stream-provider precedent — `lib/features/settings/presentation/providers/settings_provider.dart:192`
- In-repo `clock` use in domain — `lib/features/meds/domain/usecases/add_medication.dart:10`
- Read mapper to reuse — `lib/features/meds/data/mappers/medication_mapper.dart:145` (`medicationFromRows`)
