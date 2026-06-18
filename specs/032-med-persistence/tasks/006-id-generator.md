# Task 006: IdGenerator abstraction + uuid impl + provider

**Agent**: architect
**Files**: `lib/core/id/id_generator.dart`, `lib/core/id/uuid_id_generator.dart`, `lib/core/id/id_generator_provider.dart`
**Depends on**: 001
**Blocks**: 007, 009
**Context docs**: `specs/032-med-persistence/research.md` (ID generation decision)
**Review checkpoint**: No

**Description**:
Introduce an injectable ID source so the domain stays import-pure (`package:uuid` must NOT be imported under `domain/` per §2.1) and so tests get deterministic IDs. Mirrors the project's `Clock` injection philosophy.

**Change details**:
- `id_generator.dart`: `abstract interface class IdGenerator { String newId(); }` (pure Dart, dartdoc).
- `uuid_id_generator.dart`: `class UuidIdGenerator implements IdGenerator { const UuidIdGenerator(); @override String newId() => const Uuid().v4(); }` (imports `package:uuid/uuid.dart` — allowed here, this is `core/` not `domain/`).
- `id_generator_provider.dart`: `@Riverpod(keepAlive: true) IdGenerator idGenerator(Ref ref) => const UuidIdGenerator();` with `part 'id_generator_provider.g.dart'`.
- Run `build_runner` (riverpod codegen).

**Done when**:
- [ ] `IdGenerator` interface declares `String newId()`
- [ ] `UuidIdGenerator` implements it using `const Uuid().v4()`
- [ ] `idGeneratorProvider` is `@Riverpod(keepAlive: true)`
- [ ] `package:uuid` is imported only under `lib/core/` (never `domain/`); `dart analyze` passes; generated file committed

## Contracts
### Expects
- `uuid` dependency present (task 001)
### Produces
- `id_generator.dart` exports `abstract interface class IdGenerator` with method `newId()`
- `uuid_id_generator.dart` exports `class UuidIdGenerator implements IdGenerator`
- `id_generator_provider.dart` exports `idGeneratorProvider`

**Spec criteria addressed**: AC-7, AC-9

## Completion Notes
**Completed**: 2026-06-17
**Status**: Complete
**Files changed**: id_generator.dart, uuid_id_generator.dart, id_generator_provider.dart (+ id_generator_provider.g.dart)
**Contract**: Expects 1/1 | Produces 3/3
**Notes**: `package:uuid` imported ONLY in uuid_id_generator.dart (verified). idGeneratorProvider `@Riverpod(keepAlive:true)`. Domain remains uuid-free — the §2.1-compliant resolution of the MedicationId.generate() problem.
