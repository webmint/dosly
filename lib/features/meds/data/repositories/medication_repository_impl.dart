/// Concrete [MedicationRepository] backed by the local drift database.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
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
}
