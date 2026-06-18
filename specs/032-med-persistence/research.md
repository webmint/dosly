# Research: Medication Persistence (drift)

**Date**: 2026-06-16
**Signals detected**: external libs not yet in project deps — `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `uuid` (first DB in the codebase); first persistence layer for `meds`.

Most of the architecture-level research (drift vs alternatives, entity shape) was completed in `research/2026-06-16-medication-entity-storage.md` and ratified into the constitution §5.1. This file only captures the concrete drift/Dart API decisions the breakdown will rely on.

## Questions Investigated

1. **How is a drift DB opened for app vs tests?** → `drift_flutter`'s `driftDatabase(name: 'dosly')` for the app (lazy open, no async bootstrap needed); a constructor `AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection())` lets tests inject `DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true)`. Decision: use the optional-executor constructor (AC-2/AC-23).
2. **Atomic insert of a medication + N time slots?** → wrap in `transaction(() async { … })`; insert the medication row, then `batch((b) => b.insertAll(timeSlots, [...]))` for the slots. Decision: one `transaction` in the data source (AC-14).
3. **How to store enums?** → `textEnum<T>()` stores the enum **by name**; renaming/removing a value breaks deserialization of existing rows. Decision: `textEnum` for `form`/`doseUnit`/`frequency`/`typeKind`; freeze the value names (risk noted).
4. **Drift row-class name collision with the domain `Medication`?** → drift generates a row class named after the table's singular by default (`Medication`), colliding with the domain entity. `@DataClassName('MedicationRow')` / `@DataClassName('TimeSlotRow')` renames the generated classes. Decision: apply both (AC-4/5).
5. **Where does the UUID for `MedicationId` come from, given domain purity?** → see decision table below — `package:uuid` cannot be imported under `lib/features/*/domain/` (§2.1 allowed-imports list). Resolved with an injected `IdGenerator` abstraction (mirrors the project's `Clock` injection).

## Alternatives Compared

### ID generation (the only non-trivial decision)
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| `MedicationId.generate()` calling `package:uuid` **inside `domain/`** (as constitution §7.2's *illustrative* greenfield example shows) | Least code; matches the §7.2 sketch | **Violates §2.1**: `package:uuid` is not on the domain allowed-imports list; domain would no longer be pure-Dart-only by the project's own rule | Rejected |
| Amend §2.1 to allow `package:uuid` in domain | Simple | Weakens a NON-NEGOTIABLE boundary for one convenience; tests get random IDs (non-deterministic) | Rejected |
| **Inject an `IdGenerator` (domain interface in `core/`, uuid-backed impl in `core/`, provided via Riverpod)** | Domain stays pure; **deterministic IDs in tests** (inject a sequential fake); symmetric with the existing `Clock` injection the constitution mandates (§4.1.1) | One small interface + impl + provider | **Chosen** |

**Decision**: inject `IdGenerator`. `package:uuid` is added but used only in `lib/core/` (outside domain). This **refines spec AC-7/AC-9**: `MedicationId`/`TimeSlotId` are plain value objects with **no** `generate()`; the `AddMedication` use case takes an injected `IdGenerator` and an ambient `clock.now()`.

### Time injection
`package:clock` is already on the domain allow-list. The use case uses the ambient `clock.now().toUtc()` (tests wrap bodies in `withClock(Clock.fixed(...))`) — no constructor `Clock` param needed. Consistent with `add_medication_modal.dart`'s existing `clock.now()` usage.

## References
- Drift setup / testing / writes / type converters — https://drift.simonbinder.eu/setup , /testing , /dart_api/writes , /type_converters (via Context7, 2026-06-16)
- `research/2026-06-16-medication-entity-storage.md` — entity shape + drift-vs-alternatives rationale
- `lib/features/settings/presentation/providers/settings_provider.dart` — `@riverpod` composition-seam idiom (plain `Ref`, `@Riverpod(keepAlive:true)`, `name:`/`late` notifier rules)
- `lib/core/providers/shared_preferences_provider.dart` — kept-alive singleton provider pattern (analogue for `appDatabase`)
