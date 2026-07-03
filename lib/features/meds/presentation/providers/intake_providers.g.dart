// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intake_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [IntakeLocalDataSource] wired to the app-wide [AppDatabase].
///
/// The data source is the only collaborator that touches drift directly; it is
/// constructed here in the composition seam so the repository can depend on it
/// without screens/widgets reaching into `data/`.

@ProviderFor(intakeLocalDataSource)
final intakeLocalDataSourceProvider = IntakeLocalDataSourceProvider._();

/// Provides the [IntakeLocalDataSource] wired to the app-wide [AppDatabase].
///
/// The data source is the only collaborator that touches drift directly; it is
/// constructed here in the composition seam so the repository can depend on it
/// without screens/widgets reaching into `data/`.

final class IntakeLocalDataSourceProvider
    extends
        $FunctionalProvider<
          IntakeLocalDataSource,
          IntakeLocalDataSource,
          IntakeLocalDataSource
        >
    with $Provider<IntakeLocalDataSource> {
  /// Provides the [IntakeLocalDataSource] wired to the app-wide [AppDatabase].
  ///
  /// The data source is the only collaborator that touches drift directly; it is
  /// constructed here in the composition seam so the repository can depend on it
  /// without screens/widgets reaching into `data/`.
  IntakeLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'intakeLocalDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$intakeLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<IntakeLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IntakeLocalDataSource create(Ref ref) {
    return intakeLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IntakeLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IntakeLocalDataSource>(value),
    );
  }
}

String _$intakeLocalDataSourceHash() =>
    r'22d8d24e590193264beed9169c2e0a7b3c78f3f4';

/// Provides the [IntakeRepository] implementation backed by the local data
/// source.
///
/// Exposes the domain-typed [IntakeRepository] abstraction (not the concrete
/// [IntakeRepositoryImpl]) so consumers depend on the contract rather than the
/// storage technology (constitution §2.1, DIP).

@ProviderFor(intakeRepository)
final intakeRepositoryProvider = IntakeRepositoryProvider._();

/// Provides the [IntakeRepository] implementation backed by the local data
/// source.
///
/// Exposes the domain-typed [IntakeRepository] abstraction (not the concrete
/// [IntakeRepositoryImpl]) so consumers depend on the contract rather than the
/// storage technology (constitution §2.1, DIP).

final class IntakeRepositoryProvider
    extends
        $FunctionalProvider<
          IntakeRepository,
          IntakeRepository,
          IntakeRepository
        >
    with $Provider<IntakeRepository> {
  /// Provides the [IntakeRepository] implementation backed by the local data
  /// source.
  ///
  /// Exposes the domain-typed [IntakeRepository] abstraction (not the concrete
  /// [IntakeRepositoryImpl]) so consumers depend on the contract rather than the
  /// storage technology (constitution §2.1, DIP).
  IntakeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'intakeRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$intakeRepositoryHash();

  @$internal
  @override
  $ProviderElement<IntakeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IntakeRepository create(Ref ref) {
    return intakeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IntakeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IntakeRepository>(value),
    );
  }
}

String _$intakeRepositoryHash() => r'ffbeedd9fa28a04735bf56e5c93c9a1ec7d488d9';

/// Provides the [MarkIntakeTaken] use case wired to the intake repository and
/// the application-wide [IdGenerator].
///
/// This is the domain operation the today screen consumes to confirm a
/// scheduled dose as taken; it depends only on domain abstractions.

@ProviderFor(markIntakeTaken)
final markIntakeTakenProvider = MarkIntakeTakenProvider._();

/// Provides the [MarkIntakeTaken] use case wired to the intake repository and
/// the application-wide [IdGenerator].
///
/// This is the domain operation the today screen consumes to confirm a
/// scheduled dose as taken; it depends only on domain abstractions.

final class MarkIntakeTakenProvider
    extends
        $FunctionalProvider<MarkIntakeTaken, MarkIntakeTaken, MarkIntakeTaken>
    with $Provider<MarkIntakeTaken> {
  /// Provides the [MarkIntakeTaken] use case wired to the intake repository and
  /// the application-wide [IdGenerator].
  ///
  /// This is the domain operation the today screen consumes to confirm a
  /// scheduled dose as taken; it depends only on domain abstractions.
  MarkIntakeTakenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'markIntakeTakenProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$markIntakeTakenHash();

  @$internal
  @override
  $ProviderElement<MarkIntakeTaken> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MarkIntakeTaken create(Ref ref) {
    return markIntakeTaken(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarkIntakeTaken value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarkIntakeTaken>(value),
    );
  }
}

String _$markIntakeTakenHash() => r'ddb93b8cef8b7e3f3ee6883c152ad5ddec6b9bfe';

/// Provides the [SkipIntake] use case wired to the intake repository and the
/// application-wide [IdGenerator].
///
/// This is the domain operation the today screen consumes to record a
/// scheduled dose as skipped; it depends only on domain abstractions.

@ProviderFor(skipIntake)
final skipIntakeProvider = SkipIntakeProvider._();

/// Provides the [SkipIntake] use case wired to the intake repository and the
/// application-wide [IdGenerator].
///
/// This is the domain operation the today screen consumes to record a
/// scheduled dose as skipped; it depends only on domain abstractions.

final class SkipIntakeProvider
    extends $FunctionalProvider<SkipIntake, SkipIntake, SkipIntake>
    with $Provider<SkipIntake> {
  /// Provides the [SkipIntake] use case wired to the intake repository and the
  /// application-wide [IdGenerator].
  ///
  /// This is the domain operation the today screen consumes to record a
  /// scheduled dose as skipped; it depends only on domain abstractions.
  SkipIntakeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skipIntakeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skipIntakeHash();

  @$internal
  @override
  $ProviderElement<SkipIntake> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SkipIntake create(Ref ref) {
    return skipIntake(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SkipIntake value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SkipIntake>(value),
    );
  }
}

String _$skipIntakeHash() => r'65ed6b12cfe6aa2f77d9416e072905adb39cd779';

/// Provides the [UndoIntake] use case wired to the intake repository.
///
/// The domain operation the today screen consumes to revert a confirmed intake
/// within its grace window (constitution §5.2); it depends only on domain
/// abstractions.

@ProviderFor(undoIntake)
final undoIntakeProvider = UndoIntakeProvider._();

/// Provides the [UndoIntake] use case wired to the intake repository.
///
/// The domain operation the today screen consumes to revert a confirmed intake
/// within its grace window (constitution §5.2); it depends only on domain
/// abstractions.

final class UndoIntakeProvider
    extends $FunctionalProvider<UndoIntake, UndoIntake, UndoIntake>
    with $Provider<UndoIntake> {
  /// Provides the [UndoIntake] use case wired to the intake repository.
  ///
  /// The domain operation the today screen consumes to revert a confirmed intake
  /// within its grace window (constitution §5.2); it depends only on domain
  /// abstractions.
  UndoIntakeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'undoIntakeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$undoIntakeHash();

  @$internal
  @override
  $ProviderElement<UndoIntake> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UndoIntake create(Ref ref) {
    return undoIntake(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UndoIntake value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UndoIntake>(value),
    );
  }
}

String _$undoIntakeHash() => r'487590b9b76ecb4422daa692d07ee147f8d94932';

/// Reactively exposes all persisted intakes as `AsyncValue<List<Intake>>`.
///
/// Watches the repository's [IntakeRepository.watchAll] stream and folds each
/// `Either` emission: `Right` becomes a data value, `Left(failure)` is thrown so
/// Riverpod surfaces it as `AsyncValue.error(failure)` (constitution §3.2).

@ProviderFor(intakesList)
final intakesListProvider = IntakesListProvider._();

/// Reactively exposes all persisted intakes as `AsyncValue<List<Intake>>`.
///
/// Watches the repository's [IntakeRepository.watchAll] stream and folds each
/// `Either` emission: `Right` becomes a data value, `Left(failure)` is thrown so
/// Riverpod surfaces it as `AsyncValue.error(failure)` (constitution §3.2).

final class IntakesListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Intake>>,
          List<Intake>,
          Stream<List<Intake>>
        >
    with $FutureModifier<List<Intake>>, $StreamProvider<List<Intake>> {
  /// Reactively exposes all persisted intakes as `AsyncValue<List<Intake>>`.
  ///
  /// Watches the repository's [IntakeRepository.watchAll] stream and folds each
  /// `Either` emission: `Right` becomes a data value, `Left(failure)` is thrown so
  /// Riverpod surfaces it as `AsyncValue.error(failure)` (constitution §3.2).
  IntakesListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'intakesListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$intakesListHash();

  @$internal
  @override
  $StreamProviderElement<List<Intake>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Intake>> create(Ref ref) {
    return intakesList(ref);
  }
}

String _$intakesListHash() => r'680c6ef056aa729044b6a5c097f64d4e6c2539c7';
