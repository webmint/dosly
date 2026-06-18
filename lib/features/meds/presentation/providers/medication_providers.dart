/// Riverpod providers wiring the meds dependency graph.
///
/// This is the meds **composition seam**: the single presentation-layer file
/// permitted to import `data/` (constitution §2.1 amendment, MEMORY
/// 2026-06-09). It assembles the concrete data layer
/// ([MedicationLocalDataSource], [MedicationRepositoryImpl]) here and exposes
/// only **domain-typed** abstractions ([MedicationRepository], [AddMedication])
/// to the rest of the feature. Screens and widgets consume those abstractions
/// via the generated providers and must never import `data/` themselves.
library;

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/database/dev_seed.dart';
import '../../../../core/id/id_generator_provider.dart';
import '../../data/datasources/medication_local_data_source.dart';
import '../../data/repositories/medication_repository_impl.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../domain/usecases/add_medication.dart';

part 'medication_providers.g.dart';

/// Provides the [MedicationLocalDataSource] wired to the app-wide
/// [AppDatabase].
///
/// The data source is the only collaborator that touches drift directly; it is
/// constructed here in the composition seam so the repository can depend on it
/// without screens/widgets reaching into `data/`.
@riverpod
MedicationLocalDataSource medicationLocalDataSource(Ref ref) =>
    MedicationLocalDataSource(ref.watch(appDatabaseProvider));

/// Provides the [MedicationRepository] implementation backed by the local data
/// source.
///
/// Exposes the domain-typed [MedicationRepository] abstraction (not the
/// concrete [MedicationRepositoryImpl]) so consumers depend on the contract
/// rather than the storage technology (constitution §2.1, DIP).
@riverpod
MedicationRepository medicationRepository(Ref ref) =>
    MedicationRepositoryImpl(ref.watch(medicationLocalDataSourceProvider));

/// Provides the [AddMedication] use case wired to the medication repository and
/// the application-wide [IdGenerator].
///
/// This is the domain operation the add-medication modal consumes to validate
/// input and persist a new medication; it depends only on domain abstractions.
@riverpod
AddMedication addMedication(Ref ref) => AddMedication(
  ref.watch(medicationRepositoryProvider),
  ref.watch(idGeneratorProvider),
);

/// Reactively exposes all persisted medications as `AsyncValue<List<Medication>>`.
///
/// Watches the repository's [MedicationRepository.watchAll] stream and folds each
/// `Either` emission: `Right` becomes a data value, `Left(failure)` is thrown so
/// Riverpod surfaces it as `AsyncValue.error(failure)` (constitution §3.2).
@riverpod
Stream<List<Medication>> medicationsList(Ref ref) =>
    ref.watch(medicationRepositoryProvider).watchAll().map(
          (either) => either.fold((failure) => throw failure, (meds) => meds),
        );

/// DEBUG-only, idempotent medication seeder.
///
/// No-op in release builds (`!kDebugMode`) and whenever the `medications` table
/// is already non-empty, so it never overwrites or deletes real data. When the
/// table is empty in a debug build it inserts a representative demo set (see
/// [devSeedMedications]) through the real repository write path
/// ([MedicationRepository.add]) so the reactive medications list picks the rows
/// up automatically.
///
/// Best-effort: a failed insert ([Either.left]) is deliberately discarded
/// rather than thrown, so a seeding error can never crash startup. Medication
/// names (potential PHI) are never logged.
@Riverpod(keepAlive: true)
Future<void> devSeed(Ref ref) async {
  if (!kDebugMode) return;
  final AppDatabase db = ref.read(appDatabaseProvider);
  final existing = await db.select(db.medications).get();
  if (existing.isNotEmpty) return;
  final MedicationRepository repo = ref.read(medicationRepositoryProvider);
  for (final Medication med in devSeedMedications(clock.now())) {
    // Discard the result: seeding is best-effort and must not throw on a Left.
    (await repo.add(med)).fold((_) {}, (_) {});
  }
}
