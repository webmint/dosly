/// Concrete [IntakeRepository] backed by the local drift database.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/intake.dart';
import '../../domain/repositories/intake_repository.dart';
import '../../domain/value_objects/intake_id.dart';
import '../datasources/intake_local_data_source.dart';
import '../mappers/intake_mapper.dart';

/// Implementation of [IntakeRepository] that delegates persistence to
/// [IntakeLocalDataSource].
///
/// Maps the domain [Intake] entity onto a drift companion via the intake
/// mapper, then writes it through the data source. Every exception thrown by
/// the data source — or by the watched query — is caught here and converted
/// into a `Left(CacheFailure)`, so a failure never escapes the data layer
/// (constitution §2.1) and is never swallowed silently.
class IntakeRepositoryImpl implements IntakeRepository {
  /// Creates an [IntakeRepositoryImpl] backed by the given [dataSource].
  const IntakeRepositoryImpl(this._dataSource);

  final IntakeLocalDataSource _dataSource;

  @override
  Stream<Either<Failure, List<Intake>>> watchAll() async* {
    try {
      await for (final rows in _dataSource.watchAllIntakes()) {
        yield Right(<Intake>[for (final row in rows) intakeFromRow(row)]);
      }
    } catch (e) {
      // A watched-query error is converted to a Left so it never escapes the
      // data layer — mirrors MedicationRepositoryImpl.watchAll()'s async*/
      // await-for/try-catch pattern, surfacing the error as a CacheFailure.
      yield Left(Failure.cache('Failed to watch intakes: $e'));
    }
  }

  @override
  Future<Either<Failure, Intake>> markTaken(Intake intake) async {
    try {
      await _dataSource.upsertIntake(intakeToCompanion(intake));
      return Right(intake);
    } catch (e) {
      return Left(Failure.cache('Failed to record taken intake: $e'));
    }
  }

  @override
  Future<Either<Failure, Intake>> skip(Intake intake) async {
    try {
      await _dataSource.upsertIntake(intakeToCompanion(intake));
      return Right(intake);
    } catch (e) {
      return Left(Failure.cache('Failed to record skipped intake: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> undo(IntakeId id) async {
    try {
      await _dataSource.deleteIntake(id.value);
      return const Right(null);
    } catch (e) {
      return Left(Failure.cache('Failed to undo intake: $e'));
    }
  }
}
