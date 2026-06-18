// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [MedicationLocalDataSource] wired to the app-wide
/// [AppDatabase].
///
/// The data source is the only collaborator that touches drift directly; it is
/// constructed here in the composition seam so the repository can depend on it
/// without screens/widgets reaching into `data/`.

@ProviderFor(medicationLocalDataSource)
final medicationLocalDataSourceProvider = MedicationLocalDataSourceProvider._();

/// Provides the [MedicationLocalDataSource] wired to the app-wide
/// [AppDatabase].
///
/// The data source is the only collaborator that touches drift directly; it is
/// constructed here in the composition seam so the repository can depend on it
/// without screens/widgets reaching into `data/`.

final class MedicationLocalDataSourceProvider
    extends
        $FunctionalProvider<
          MedicationLocalDataSource,
          MedicationLocalDataSource,
          MedicationLocalDataSource
        >
    with $Provider<MedicationLocalDataSource> {
  /// Provides the [MedicationLocalDataSource] wired to the app-wide
  /// [AppDatabase].
  ///
  /// The data source is the only collaborator that touches drift directly; it is
  /// constructed here in the composition seam so the repository can depend on it
  /// without screens/widgets reaching into `data/`.
  MedicationLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'medicationLocalDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$medicationLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<MedicationLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MedicationLocalDataSource create(Ref ref) {
    return medicationLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MedicationLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MedicationLocalDataSource>(value),
    );
  }
}

String _$medicationLocalDataSourceHash() =>
    r'cc5e73293598a16631748d8e014cf83b787b9136';

/// Provides the [MedicationRepository] implementation backed by the local data
/// source.
///
/// Exposes the domain-typed [MedicationRepository] abstraction (not the
/// concrete [MedicationRepositoryImpl]) so consumers depend on the contract
/// rather than the storage technology (constitution §2.1, DIP).

@ProviderFor(medicationRepository)
final medicationRepositoryProvider = MedicationRepositoryProvider._();

/// Provides the [MedicationRepository] implementation backed by the local data
/// source.
///
/// Exposes the domain-typed [MedicationRepository] abstraction (not the
/// concrete [MedicationRepositoryImpl]) so consumers depend on the contract
/// rather than the storage technology (constitution §2.1, DIP).

final class MedicationRepositoryProvider
    extends
        $FunctionalProvider<
          MedicationRepository,
          MedicationRepository,
          MedicationRepository
        >
    with $Provider<MedicationRepository> {
  /// Provides the [MedicationRepository] implementation backed by the local data
  /// source.
  ///
  /// Exposes the domain-typed [MedicationRepository] abstraction (not the
  /// concrete [MedicationRepositoryImpl]) so consumers depend on the contract
  /// rather than the storage technology (constitution §2.1, DIP).
  MedicationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'medicationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$medicationRepositoryHash();

  @$internal
  @override
  $ProviderElement<MedicationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MedicationRepository create(Ref ref) {
    return medicationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MedicationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MedicationRepository>(value),
    );
  }
}

String _$medicationRepositoryHash() =>
    r'a9edc74094e9f9088d06116020cf28fe8e79eebb';

/// Provides the [AddMedication] use case wired to the medication repository and
/// the application-wide [IdGenerator].
///
/// This is the domain operation the add-medication modal consumes to validate
/// input and persist a new medication; it depends only on domain abstractions.

@ProviderFor(addMedication)
final addMedicationProvider = AddMedicationProvider._();

/// Provides the [AddMedication] use case wired to the medication repository and
/// the application-wide [IdGenerator].
///
/// This is the domain operation the add-medication modal consumes to validate
/// input and persist a new medication; it depends only on domain abstractions.

final class AddMedicationProvider
    extends $FunctionalProvider<AddMedication, AddMedication, AddMedication>
    with $Provider<AddMedication> {
  /// Provides the [AddMedication] use case wired to the medication repository and
  /// the application-wide [IdGenerator].
  ///
  /// This is the domain operation the add-medication modal consumes to validate
  /// input and persist a new medication; it depends only on domain abstractions.
  AddMedicationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addMedicationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addMedicationHash();

  @$internal
  @override
  $ProviderElement<AddMedication> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AddMedication create(Ref ref) {
    return addMedication(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddMedication value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddMedication>(value),
    );
  }
}

String _$addMedicationHash() => r'abcc2f0b1bc60481670ee87f7601c940bc8fec74';

/// Reactively exposes all persisted medications as `AsyncValue<List<Medication>>`.
///
/// Watches the repository's [MedicationRepository.watchAll] stream and folds each
/// `Either` emission: `Right` becomes a data value, `Left(failure)` is thrown so
/// Riverpod surfaces it as `AsyncValue.error(failure)` (constitution §3.2).

@ProviderFor(medicationsList)
final medicationsListProvider = MedicationsListProvider._();

/// Reactively exposes all persisted medications as `AsyncValue<List<Medication>>`.
///
/// Watches the repository's [MedicationRepository.watchAll] stream and folds each
/// `Either` emission: `Right` becomes a data value, `Left(failure)` is thrown so
/// Riverpod surfaces it as `AsyncValue.error(failure)` (constitution §3.2).

final class MedicationsListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Medication>>,
          List<Medication>,
          Stream<List<Medication>>
        >
    with $FutureModifier<List<Medication>>, $StreamProvider<List<Medication>> {
  /// Reactively exposes all persisted medications as `AsyncValue<List<Medication>>`.
  ///
  /// Watches the repository's [MedicationRepository.watchAll] stream and folds each
  /// `Either` emission: `Right` becomes a data value, `Left(failure)` is thrown so
  /// Riverpod surfaces it as `AsyncValue.error(failure)` (constitution §3.2).
  MedicationsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'medicationsListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$medicationsListHash();

  @$internal
  @override
  $StreamProviderElement<List<Medication>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Medication>> create(Ref ref) {
    return medicationsList(ref);
  }
}

String _$medicationsListHash() => r'441f5ed26b7022c82fe0f16e23bf349cbe898c32';

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

@ProviderFor(devSeed)
final devSeedProvider = DevSeedProvider._();

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

final class DevSeedProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
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
  DevSeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'devSeedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$devSeedHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return devSeed(ref);
  }
}

String _$devSeedHash() => r'4aa4a4ed1daad61ac9959eb064a3f4f2b0fc5841';
