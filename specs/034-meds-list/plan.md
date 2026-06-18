# Plan: Medications List Screen

**Date**: 2026-06-18
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Build the read side of the meds feature as a reactive vertical slice: a watched drift left-outer join (medications ⨝ time_slots) surfaced through a `Stream<Either<Failure, List<Medication>>>` repository method and a `@riverpod` stream provider exposing `AsyncValue<List<Medication>>`. A pure, `now`-injected domain derivation computes each med's `Active`/`Completed` status and (for courses) a cycle-day counter. The rebuilt `MedsScreen` groups meds into Continuous/Course sections, renders form-icon tiles with `dose · times · stock` subtitles and status/type chips, and adds All/Active filter chips + name search. A `kDebugMode`-only, empty-table-guarded seeder inserts 12 representative medications via the real write path so the screen is exercisable on device.

## Technical Context

**Architecture**: Clean Architecture, all three layers of `features/meds/` + `core/database` (seeder) + `l10n`.
**Error Handling**: `Either<Failure, T>` at the repository boundary, carried over a stream (`async*` + `try` → `Left(Failure.unknown)`); folded to `AsyncValue` in the provider.
**State Management**: Riverpod 3 / generator 4. One `@riverpod` **stream** provider for the data (precedent: `settingsErrors`); ephemeral filter-chip + search state held as `ConsumerStatefulWidget` `setState` (UI-only, not domain).
**Time**: `package:clock` ambient `clock.now()` read once at the screen seam and passed into the pure derivations (matches `add_medication.dart`).

## Constitution Compliance

| Rule | Status |
|------|--------|
| §2.1 layer boundaries | Compliant — read path mirrors write path; only the composition seam (`medication_providers.dart`) imports `data/`; screen/tile/view-model depend on domain-typed providers only. |
| §2.1 domain purity | Compliant — derivations are pure Dart (no Flutter/drift); icon map, `HH:mm`/dose/stock formatting live in `presentation/`. |
| §3.2 `Either` at boundaries | Compliant — `Stream<Either<Failure, List<Medication>>>` is the read-side analog of the existing `Future<Either<…>>` write; provider folds `Right`→data / `Left`→error. **Documented design choice** (research.md Q2) — flagged for a possible future `/constitute` note if the pattern spreads. |
| §3.4 testing | Compliant — domain derivation unit tests (mandatory), in-memory drift data-source/repo tests (mandatory), screen/tile widget tests with overridden providers. |
| §4.2.1 Clock, never `DateTime.now()` | Compliant — derivations take injected `now`; caller uses `clock.now()`; tests pass fixed instants. |
| §4.2.1 never log PHI | Compliant — seeder logs nothing with med names; `repo.add` logs nothing on success. |
| §4.3.1 typed queries; `@riverpod` codegen; exhaustive switches; const | Compliant — typed `leftOuterJoin().watch()`; codegen providers; exhaustive `switch` over `MedicationType`/enums. |
| §6.5 no schema change without migration | Compliant — **no schema change**; `schemaVersion` stays `1`. Active/Completed are derived. |
| §3.7 DRY / search-before-build | Compliant — extract the existing `MedicationForm → IconData` map from `add_medication_modal.dart` for reuse; reuse `medicationFromRows`. |
| §2.3 no new deps | Compliant — rxdart rejected (research.md); drift/riverpod/fpdart/clock already present. |

## Implementation Approach

### Layer Map

| Layer | What | Files (existing / new) |
|-------|------|------------------------|
| Domain | `Active`/`Completed` + cycle-day derivation; leaf enums; `CourseProgress` value object | **new** `entities/medication_activity_status.dart`, `entities/course_phase.dart`, `value_objects/course_progress.dart`, `value_objects/medication_activity.dart` |
| Domain | Reactive read contract | **mod** `domain/repositories/medication_repository.dart` (+`watchAll()`) |
| Data | Watched join; row→entity; error→`Left` | **mod** `data/datasources/medication_local_data_source.dart` (+`watchAllMedications()`), **mod** `data/repositories/medication_repository_impl.dart` (+`watchAll()`), **reuse** `data/mappers/medication_mapper.dart` (`medicationFromRows`) |
| Presentation | Stream provider; seeder provider | **mod** `presentation/providers/medication_providers.dart` (+`medicationsListProvider`, +`devSeedProvider`) |
| Presentation | Screen, tile, sections, view-model, shared icon map, formatters | **mod** `presentation/screens/meds_screen.dart`; **new** `presentation/widgets/medication_tile.dart`, `presentation/widgets/medication_section.dart`, `presentation/widgets/medication_form_icon.dart`, `presentation/view_models/meds_list_view_model.dart`, `presentation/widgets/medication_display.dart` (dose/time/stock + unit-abbrev formatting) |
| Presentation | Consume shared icon map | **mod** `presentation/widgets/add_medication_modal.dart` (use extracted map) |
| Core | Debug seed data | **new** `core/database/dev_seed.dart` |
| Bootstrap | Trigger seeder once (debug) | **mod** `lib/app_bootstrap.dart` (`if (kDebugMode) ref.read(devSeedProvider)`) |
| l10n | List-screen strings ×3 locales | **mod** `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` |
| Tests | Domain, data, presentation | **new** under `test/features/meds/...` |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Reactive read | Single watched `leftOuterJoin` + group rows in Dart | Re-emits on both tables; no new dep; typed (§4.3.1) | rxdart `combineLatest2` (new dep); `customSelect` (raw SQL); `Future`+invalidate (not reactive) |
| Boundary type | `Stream<Either<Failure, List<Medication>>>` via `async*`+`try` | Honors §3.2; folds to `AsyncValue`; keeps typed `Failure` | bare `Stream<List<…>>` (bypasses §3.2) |
| Provider | `@riverpod Stream<List<Medication>> medicationsList` folding `Left`→throw | AsyncValue.error(Failure) per §3.2/§7.2; precedent `settingsErrors` | manual `StreamProvider` (violates codegen rule) |
| Derivation home | Pure `now`-param fns in `domain/value_objects/`; enums in `entities/` | Sync+infallible ⇒ not a use case; no unsanctioned `services/` folder | `usecases/`(dishonest `Future<Either>`); `domain/services/`(not in §2.2) |
| Day math | Date-only (local) differencing; explicit cyclic modulo; inclusive end | DST/intraday-safe; matches §5.2; avoids the `startDate` instant-equality trap (MEMORY spec 033) | raw-instant `difference` (DST/intraday bugs) |
| Active filter | Derived `Completed` = ended non-cyclic course; `active` hides it | Gives chips meaning with **no** schema change | persisted archive flag (deferred follow-up) |
| Filter/search state | `ConsumerStatefulWidget` `setState` | UI-ephemeral, not domain; KISS | extra `@riverpod` notifiers (over-engineering) |
| View shaping | Pure `buildMedsListView(...)` in `view_models/` | Unit-testable without pumping widgets; thin widget | logic inline in `build` (untestable, fat widget) |
| Form icon | Extract `Map<MedicationForm, IconData>` shared by modal + tile | DRY (§3.7); single source of truth | duplicate the mapping in the tile |
| Seeder trigger | `@Riverpod(keepAlive: true) Future<void> devSeed` read once in `AppBootstrap`; self-guards `kDebugMode` + empty table; fire-and-forget | Async, non-blocking; rows appear via the reactive stream; idempotent; no release impact | seeding in `main()` (blocks startup); seeding in `build` without guard (re-runs) |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `domain/entities/medication_activity_status.dart` | Create | `enum { active, completed }` |
| `domain/entities/course_phase.dart` | Create | `enum { activeWindow, paused }` |
| `domain/value_objects/course_progress.dart` | Create | `@freezed CourseProgress(currentDay,totalDays,phase)` + `static resolve(course, now)` |
| `domain/value_objects/medication_activity.dart` | Create | `resolveMedicationActivity(Medication, now)` |
| `domain/repositories/medication_repository.dart` | Modify | Add `Stream<Either<Failure, List<Medication>>> watchAll()` |
| `data/datasources/medication_local_data_source.dart` | Modify | Add `watchAllMedications()` (watched left-outer join, group by med) |
| `data/repositories/medication_repository_impl.dart` | Modify | Add `watchAll()` (`async*`+`try`, `medicationFromRows`, error→`Left`) |
| `presentation/providers/medication_providers.dart` | Modify | Add `medicationsListProvider` (stream) + `devSeedProvider` |
| `presentation/view_models/meds_list_view_model.dart` | Create | Pure filter+search+group+derive shaping; `MedsFilter` enum |
| `presentation/widgets/medication_form_icon.dart` | Create | Shared `MedicationForm → IconData` (extracted from modal) |
| `presentation/widgets/medication_display.dart` | Create | dose/time/stock + localized unit-abbrev formatting |
| `presentation/widgets/medication_tile.dart` | Create | `.mlt` tile: icon (variant), name, subtitle, chips, chevron |
| `presentation/widgets/medication_section.dart` | Create | Section header + list + inline empty placeholder |
| `presentation/screens/meds_screen.dart` | Modify | Rebuild: search app-bar, filter chips, sections, loading/error/empty states |
| `presentation/widgets/add_medication_modal.dart` | Modify | Consume the extracted icon map (behavior-preserving) |
| `core/database/dev_seed.dart` | Create | `List<Medication> devSeedMedications(DateTime now)` (12 variants) |
| `lib/app_bootstrap.dart` | Modify | `if (kDebugMode) ref.read(devSeedProvider);` in the data branch |
| `lib/l10n/app_en.arb` / `app_de.arb` / `app_uk.arb` | Modify | ~25 new keys (incl. 9 dose-unit abbrevs) ×3 locales |
| `test/features/meds/domain/value_objects/*_test.dart` | Create | Derivation tests (fixed `Clock` instants) |
| `test/features/meds/data/...` | Create | In-memory drift watch/group + repo `watchAll` tests |
| `test/features/meds/presentation/...` | Create | View-model + tile + screen widget tests |
| `*.g.dart` / `*.freezed.dart` | Regenerate | `build_runner` for new freezed + providers + l10n |

> **Additions beyond the spec's Affected Areas** (discovered during planning): `course_phase.dart` + `medication_activity_status.dart` (split the "new derivation" entry into leaf enums); `meds_list_view_model.dart` (extract pure shaping); `medication_display.dart` (formatting helpers); `medication_section.dart`. All are refinements within the spec's stated areas, not scope growth.

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/features/medications.md` | Create (at `/finalize`, via tech-writer) | List screen, reactive read, derivation rules, seeder |
| `docs/architecture.md` | Update (at `/finalize`) | First reactive (`watch`) read + `Stream<Either>` boundary pattern |

`docs/` is currently empty; documentation is generated by the tech-writer at `/finalize`, not during task execution.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Cycle-day / inclusive-end / DST math wrong | Med | Med | Centralize in `CourseProgress.resolve` + `resolveMedicationActivity`; date-only differencing; exhaustive fixed-`Clock` tests at boundaries (AC-6); reuse §5.2 rules. |
| Watched join mis-groups slots or fails to re-emit on slot-only change | Med | Med | In-memory drift test: insert/modify/delete a slot and assert re-emission + correct grouping; left-outer join keeps slot-less meds. |
| `Stream<Either>` deviates from `Future<Either>` idiom (review friction) | Med | Low | Documented in research.md + seam dartdoc as the sanctioned read-side analog; architect sign-off implicit via this plan. |
| Seeder duplicates or wipes real data | Low | High | `kDebugMode` + empty-table guard + insert-only (never deletes); stable `seed-*` ids; no-op in release. |
| Icon-map extraction breaks the add modal | Low | Med | Behavior-preserving move; existing add-modal tests must stay green; `dart analyze` clean. |
| l10n key/plural/format drift across 3 locales | Low | Low | All keys added in one task; `flutter gen-l10n` fails fast; widget tests assert localized output (mind `MaterialLocalizations` format gotchas, MEMORY). |
| AC coverage gaps | Low | Med | Phase 2.5 cross-reference below maps every AC to a file/decision. |

## Dependencies

None new. Uses existing `drift ^2.31`, `flutter_riverpod ^3.3`, `riverpod_annotation ^4.0`, `fpdart ^1.2`, `clock ^1.1`, `lucide_icons_flutter`. Code generation via existing `build_runner` + `flutter gen-l10n`.

## AC → Plan Cross-Reference (Phase 2.5)

| AC | Covered by |
|----|-----------|
| AC-1 | `watchAllMedications()` + `watchAll()` (`Stream<Either>`, error→`Left`) |
| AC-2 | `medicationsListProvider` (folds to `AsyncValue`) |
| AC-3 | `watchAll()` reuses `medicationFromRows` |
| AC-4 | `resolveMedicationActivity` |
| AC-5 | `CourseProgress.resolve` |
| AC-6 | derivation unit tests (fixed `Clock`) |
| AC-7 | `buildMedsListView` grouping/sort + `medication_section.dart` + screen |
| AC-8 | `medication_tile.dart` + `medication_form_icon.dart` + `medication_display.dart` |
| AC-9 | `medication_tile.dart` chips (status/type from derivations) |
| AC-10 | `MedsFilter` state + `buildMedsListView` filter |
| AC-11 | search `setState` + `buildMedsListView` query |
| AC-12 | screen empty states (top-level + per-section) |
| AC-13 | `medication_tile.dart` non-interactive chevron |
| AC-14 | screen `AsyncValue.when(loading/error/data)` |
| AC-15 | `app_en/de/uk.arb` keys |
| AC-16 | `devSeedProvider` (`kDebugMode` + empty-table guard) |
| AC-17 | `devSeedMedications` 12-variant set (data-model.md) |
| AC-18 | seeder no-PHI-log + no debug artifacts; `dart analyze` |
| AC-19 | reactive provider (AC-1/2) + an add→appears test |

## Supporting Documents

- [Research](research.md) — reactive-read strategy, boundary shape, derivation placement
- [Data Model](data-model.md) — new domain types, read contract, l10n keys, seed set
