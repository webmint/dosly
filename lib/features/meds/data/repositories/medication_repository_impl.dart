/// Concrete [MedicationRepository] backed by the local drift database.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/database/database.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../domain/value_objects/medication_id.dart';
import '../datasources/medication_local_data_source.dart';
import '../mappers/medication_mapper.dart';

/// Implementation of [MedicationRepository] that delegates persistence to
/// [MedicationLocalDataSource].
///
/// Maps the domain [Medication] aggregate onto drift companions via the
/// medication mapper, then writes them through the data source. Every exception
/// thrown by the data source is caught here and converted into a
/// `Left(Failure)`, so failures never escape the data layer (constitution
/// §2.1).
class MedicationRepositoryImpl implements MedicationRepository {
  /// Creates a [MedicationRepositoryImpl] backed by the given [dataSource].
  const MedicationRepositoryImpl(this._dataSource);

  final MedicationLocalDataSource _dataSource;

  @override
  Future<Either<Failure, Medication>> add(Medication medication) async {
    try {
      await _dataSource.insertMedication(
        medicationToCompanion(medication),
        timeSlotsToCompanions(medication),
      );
      return Right(medication);
    } catch (e, st) {
      return Left(Failure.unknown(e, st));
    }
  }

  @override
  Future<Either<Failure, Medication>> update(Medication medication) async {
    try {
      await _dataSource.upsertMedication(
        medicationToCompanion(medication),
        timeSlotsToCompanions(medication),
      );
      return Right(medication);
    } catch (e, st) {
      return Left(Failure.unknown(e, st));
    }
  }

  @override
  Future<Either<Failure, void>> delete(MedicationId id) async {
    try {
      await _dataSource.deleteMedication(id.value);
      return const Right(null);
    } catch (e, st) {
      return Left(Failure.unknown(e, st));
    }
  }

  @override
  Stream<Either<Failure, List<Medication>>> watchAll() async* {
    try {
      await for (final rows in _dataSource.watchAllMedications()) {
        yield Right(
          <Medication>[
            for (final (MedicationRow, List<TimeSlotRow>) r in rows)
              medicationFromRows(r.$1, r.$2),
          ],
        );
      }
    } catch (e, st) {
      // Any failure — a query error or a corrupt-row [StateError] thrown by
      // [medicationFromRows] — is converted to a Left so it never escapes the
      // data layer.
      yield Left(Failure.unknown(e, st));
    }
  }
}
