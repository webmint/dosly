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

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/id/id_generator_provider.dart';
import '../../data/datasources/medication_local_data_source.dart';
import '../../data/repositories/medication_repository_impl.dart';
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
