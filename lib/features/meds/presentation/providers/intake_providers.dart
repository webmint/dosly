/// Riverpod providers wiring the intake dependency graph.
///
/// This is a meds **composition seam**: a presentation-layer file permitted to
/// import `data/` (constitution §2.1 amendment, MEMORY 2026-06-09), alongside
/// `medication_providers.dart`. It assembles the concrete data layer
/// ([IntakeLocalDataSource], [IntakeRepositoryImpl]) here and exposes only
/// **domain-typed** abstractions ([IntakeRepository], [MarkIntakeTaken],
/// [SkipIntake], [UndoIntake]) to the rest of the feature. Screens and widgets
/// consume those abstractions via the generated providers and must never import
/// `data/` themselves.
library;

import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/id/id_generator_provider.dart';
import '../../../../core/logging/logger.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/datasources/intake_local_data_source.dart';
import '../../data/repositories/intake_repository_impl.dart';
import '../../domain/entities/intake.dart';
import '../../domain/repositories/intake_repository.dart';
import '../../domain/usecases/mark_intake_taken.dart';
import '../../domain/usecases/reconcile_missed_intakes.dart';
import '../../domain/usecases/skip_intake.dart';
import '../../domain/usecases/undo_intake.dart';
import 'medication_providers.dart';

part 'intake_providers.g.dart';

/// Provides the [IntakeLocalDataSource] wired to the app-wide [AppDatabase].
///
/// The data source is the only collaborator that touches drift directly; it is
/// constructed here in the composition seam so the repository can depend on it
/// without screens/widgets reaching into `data/`.
@riverpod
IntakeLocalDataSource intakeLocalDataSource(Ref ref) =>
    IntakeLocalDataSource(ref.watch(appDatabaseProvider));

/// Provides the [IntakeRepository] implementation backed by the local data
/// source.
///
/// Exposes the domain-typed [IntakeRepository] abstraction (not the concrete
/// [IntakeRepositoryImpl]) so consumers depend on the contract rather than the
/// storage technology (constitution §2.1, DIP).
@riverpod
IntakeRepository intakeRepository(Ref ref) =>
    IntakeRepositoryImpl(ref.watch(intakeLocalDataSourceProvider));

/// Provides the [MarkIntakeTaken] use case wired to the intake repository and
/// the application-wide [IdGenerator].
///
/// This is the domain operation the today screen consumes to confirm a
/// scheduled dose as taken; it depends only on domain abstractions.
@riverpod
MarkIntakeTaken markIntakeTaken(Ref ref) => MarkIntakeTaken(
  ref.watch(intakeRepositoryProvider),
  ref.watch(idGeneratorProvider),
);

/// Provides the [SkipIntake] use case wired to the intake repository and the
/// application-wide [IdGenerator].
///
/// This is the domain operation the today screen consumes to record a
/// scheduled dose as skipped; it depends only on domain abstractions.
@riverpod
SkipIntake skipIntake(Ref ref) => SkipIntake(
  ref.watch(intakeRepositoryProvider),
  ref.watch(idGeneratorProvider),
);

/// Provides the [UndoIntake] use case wired to the intake repository.
///
/// The domain operation the today screen consumes to revert a confirmed intake
/// within its grace window (constitution §5.2); it depends only on domain
/// abstractions.
@riverpod
UndoIntake undoIntake(Ref ref) =>
    UndoIntake(ref.watch(intakeRepositoryProvider));

/// Reactively exposes all persisted intakes as `AsyncValue<List<Intake>>`.
///
/// Watches the repository's [IntakeRepository.watchAll] stream and folds each
/// `Either` emission: `Right` becomes a data value, `Left(failure)` is thrown so
/// Riverpod surfaces it as `AsyncValue.error(failure)` (constitution §3.2).
@riverpod
Stream<List<Intake>> intakesList(Ref ref) => ref
    .watch(intakeRepositoryProvider)
    .watchAll()
    .map(
      (either) => either.fold((failure) => throw failure, (intakes) => intakes),
    );

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
@riverpod
ReconcileMissedIntakes reconcileMissedIntakes(Ref ref) =>
    ReconcileMissedIntakes(
      ref.watch(medicationRepositoryProvider),
      ref.watch(intakeRepositoryProvider),
      ref.watch(settingsRepositoryProvider),
      ref.watch(idGeneratorProvider),
    );

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
@Riverpod(keepAlive: true)
Future<void> reconcileMissedOnOpen(Ref ref) async {
  final result = await ref
      .read(reconcileMissedIntakesProvider)
      .call(now: clock.now());
  result.fold(
    (failure) => ref
        .read(loggerProvider)
        .warning('Auto-miss reconciliation on open failed', failure),
    (_) {},
  );
}
