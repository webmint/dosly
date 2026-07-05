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

/// Provides the [ReconcileMissedIntakes] use case wired to the medication and
/// intake repositories, the settings repository (for the intake window), and
/// the application-wide [IdGenerator].
///
/// This is the write-side auto-miss operation: it derives every due occurrence
/// whose intake window has closed with no recorded intake and persists a
/// `missed` [Intake] for each. Consumers depend on the concrete use-case type
/// exposed here. The [settingsRepositoryProvider] import is a documented
/// cross-feature DI seam (constitution §2.1 amendment); screens/widgets stay
/// settings-free.

@ProviderFor(reconcileMissedIntakes)
final reconcileMissedIntakesProvider = ReconcileMissedIntakesProvider._();

/// Provides the [ReconcileMissedIntakes] use case wired to the medication and
/// intake repositories, the settings repository (for the intake window), and
/// the application-wide [IdGenerator].
///
/// This is the write-side auto-miss operation: it derives every due occurrence
/// whose intake window has closed with no recorded intake and persists a
/// `missed` [Intake] for each. Consumers depend on the concrete use-case type
/// exposed here. The [settingsRepositoryProvider] import is a documented
/// cross-feature DI seam (constitution §2.1 amendment); screens/widgets stay
/// settings-free.

final class ReconcileMissedIntakesProvider
    extends
        $FunctionalProvider<
          ReconcileMissedIntakes,
          ReconcileMissedIntakes,
          ReconcileMissedIntakes
        >
    with $Provider<ReconcileMissedIntakes> {
  /// Provides the [ReconcileMissedIntakes] use case wired to the medication and
  /// intake repositories, the settings repository (for the intake window), and
  /// the application-wide [IdGenerator].
  ///
  /// This is the write-side auto-miss operation: it derives every due occurrence
  /// whose intake window has closed with no recorded intake and persists a
  /// `missed` [Intake] for each. Consumers depend on the concrete use-case type
  /// exposed here. The [settingsRepositoryProvider] import is a documented
  /// cross-feature DI seam (constitution §2.1 amendment); screens/widgets stay
  /// settings-free.
  ReconcileMissedIntakesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reconcileMissedIntakesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reconcileMissedIntakesHash();

  @$internal
  @override
  $ProviderElement<ReconcileMissedIntakes> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReconcileMissedIntakes create(Ref ref) {
    return reconcileMissedIntakes(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReconcileMissedIntakes value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReconcileMissedIntakes>(value),
    );
  }
}

String _$reconcileMissedIntakesHash() =>
    r'cc1f01a69fc493db344bc55472eb34360b68d621';

/// Runs auto-miss reconciliation ONCE per app run, on first read.
///
/// Annotated `keepAlive: true` so the future is memoised for the app's
/// lifetime: reading it again returns the same completed future rather than
/// re-reconciling. Designed to be fire-and-forget from `AppBootstrap`
/// (mirroring [devSeed]) — it folds the reconcile [Either] and **never
/// throws**: a [Left] is logged via [loggerProvider] (a generic message plus
/// the [Failure] object, which carries no PHI — never a medication name), and a
/// [Right] is discarded. A reconciliation failure can therefore never crash
/// startup. Overridable in tests via the generated `reconcileMissedOnOpenProvider`.

@ProviderFor(reconcileMissedOnOpen)
final reconcileMissedOnOpenProvider = ReconcileMissedOnOpenProvider._();

/// Runs auto-miss reconciliation ONCE per app run, on first read.
///
/// Annotated `keepAlive: true` so the future is memoised for the app's
/// lifetime: reading it again returns the same completed future rather than
/// re-reconciling. Designed to be fire-and-forget from `AppBootstrap`
/// (mirroring [devSeed]) — it folds the reconcile [Either] and **never
/// throws**: a [Left] is logged via [loggerProvider] (a generic message plus
/// the [Failure] object, which carries no PHI — never a medication name), and a
/// [Right] is discarded. A reconciliation failure can therefore never crash
/// startup. Overridable in tests via the generated `reconcileMissedOnOpenProvider`.

final class ReconcileMissedOnOpenProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Runs auto-miss reconciliation ONCE per app run, on first read.
  ///
  /// Annotated `keepAlive: true` so the future is memoised for the app's
  /// lifetime: reading it again returns the same completed future rather than
  /// re-reconciling. Designed to be fire-and-forget from `AppBootstrap`
  /// (mirroring [devSeed]) — it folds the reconcile [Either] and **never
  /// throws**: a [Left] is logged via [loggerProvider] (a generic message plus
  /// the [Failure] object, which carries no PHI — never a medication name), and a
  /// [Right] is discarded. A reconciliation failure can therefore never crash
  /// startup. Overridable in tests via the generated `reconcileMissedOnOpenProvider`.
  ReconcileMissedOnOpenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reconcileMissedOnOpenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reconcileMissedOnOpenHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return reconcileMissedOnOpen(ref);
  }
}

String _$reconcileMissedOnOpenHash() =>
    r'dad822679490a5ae711b77746e32a985b07781bd';
