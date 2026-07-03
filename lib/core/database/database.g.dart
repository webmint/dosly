// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MedicationsTable extends Medications
    with TableInfo<$MedicationsTable, MedicationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MedicationForm, String> form =
      GeneratedColumn<String>(
        'form',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MedicationForm>($MedicationsTable.$converterform);
  static const VerificationMeta _doseAmountMeta = const VerificationMeta(
    'doseAmount',
  );
  @override
  late final GeneratedColumn<double> doseAmount = GeneratedColumn<double>(
    'dose_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DoseUnit?, String> doseUnit =
      GeneratedColumn<String>(
        'dose_unit',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DoseUnit?>($MedicationsTable.$converterdoseUnitn);
  @override
  late final GeneratedColumnWithTypeConverter<MedicationTypeKind, String>
  typeKind = GeneratedColumn<String>(
    'type_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<MedicationTypeKind>($MedicationsTable.$convertertypeKind);
  @override
  late final GeneratedColumnWithTypeConverter<ScheduleFrequency, String>
  frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ScheduleFrequency>($MedicationsTable.$converterfrequency);
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationDaysMeta = const VerificationMeta(
    'durationDays',
  );
  @override
  late final GeneratedColumn<int> durationDays = GeneratedColumn<int>(
    'duration_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pauseDaysMeta = const VerificationMeta(
    'pauseDays',
  );
  @override
  late final GeneratedColumn<int> pauseDays = GeneratedColumn<int>(
    'pause_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockRemainingMeta = const VerificationMeta(
    'stockRemaining',
  );
  @override
  late final GeneratedColumn<int> stockRemaining = GeneratedColumn<int>(
    'stock_remaining',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockTotalMeta = const VerificationMeta(
    'stockTotal',
  );
  @override
  late final GeneratedColumn<int> stockTotal = GeneratedColumn<int>(
    'stock_total',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockWarnAtMeta = const VerificationMeta(
    'stockWarnAt',
  );
  @override
  late final GeneratedColumn<int> stockWarnAt = GeneratedColumn<int>(
    'stock_warn_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    form,
    doseAmount,
    doseUnit,
    typeKind,
    frequency,
    startDate,
    durationDays,
    pauseDays,
    stockRemaining,
    stockTotal,
    stockWarnAt,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dose_amount')) {
      context.handle(
        _doseAmountMeta,
        doseAmount.isAcceptableOrUnknown(data['dose_amount']!, _doseAmountMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('duration_days')) {
      context.handle(
        _durationDaysMeta,
        durationDays.isAcceptableOrUnknown(
          data['duration_days']!,
          _durationDaysMeta,
        ),
      );
    }
    if (data.containsKey('pause_days')) {
      context.handle(
        _pauseDaysMeta,
        pauseDays.isAcceptableOrUnknown(data['pause_days']!, _pauseDaysMeta),
      );
    }
    if (data.containsKey('stock_remaining')) {
      context.handle(
        _stockRemainingMeta,
        stockRemaining.isAcceptableOrUnknown(
          data['stock_remaining']!,
          _stockRemainingMeta,
        ),
      );
    }
    if (data.containsKey('stock_total')) {
      context.handle(
        _stockTotalMeta,
        stockTotal.isAcceptableOrUnknown(data['stock_total']!, _stockTotalMeta),
      );
    }
    if (data.containsKey('stock_warn_at')) {
      context.handle(
        _stockWarnAtMeta,
        stockWarnAt.isAcceptableOrUnknown(
          data['stock_warn_at']!,
          _stockWarnAtMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      form: $MedicationsTable.$converterform.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}form'],
        )!,
      ),
      doseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dose_amount'],
      ),
      doseUnit: $MedicationsTable.$converterdoseUnitn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}dose_unit'],
        ),
      ),
      typeKind: $MedicationsTable.$convertertypeKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type_kind'],
        )!,
      ),
      frequency: $MedicationsTable.$converterfrequency.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}frequency'],
        )!,
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      durationDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_days'],
      ),
      pauseDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pause_days'],
      ),
      stockRemaining: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_remaining'],
      ),
      stockTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_total'],
      ),
      stockWarnAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_warn_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MedicationsTable createAlias(String alias) {
    return $MedicationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MedicationForm, String, String> $converterform =
      const EnumNameConverter<MedicationForm>(MedicationForm.values);
  static JsonTypeConverter2<DoseUnit, String, String> $converterdoseUnit =
      const EnumNameConverter<DoseUnit>(DoseUnit.values);
  static JsonTypeConverter2<DoseUnit?, String?, String?> $converterdoseUnitn =
      JsonTypeConverter2.asNullable($converterdoseUnit);
  static JsonTypeConverter2<MedicationTypeKind, String, String>
  $convertertypeKind = const EnumNameConverter<MedicationTypeKind>(
    MedicationTypeKind.values,
  );
  static JsonTypeConverter2<ScheduleFrequency, String, String>
  $converterfrequency = const EnumNameConverter<ScheduleFrequency>(
    ScheduleFrequency.values,
  );
}

class MedicationRow extends DataClass implements Insertable<MedicationRow> {
  /// Stable unique identifier (domain `MedicationId` value). Primary key.
  final String id;

  /// Display name of the medication.
  final String name;

  /// Physical form (tablet, syrup, …). Stored by enum name.
  final MedicationForm form;

  /// Per-intake dose amount, when a dose is tracked. `null` when untracked.
  final double? doseAmount;

  /// Unit for [doseAmount], when a dose is tracked. Stored by enum name.
  final DoseUnit? doseUnit;

  /// Whether this medication is continuous or a (cyclic) course.
  final MedicationTypeKind typeKind;

  /// Recurrence frequency. Non-nullable; the mapper always supplies it (MVP
  /// defaults to `daily`), so no DB default is needed. Stored by enum name.
  final ScheduleFrequency frequency;

  /// First day the medication applies (UTC, per the UTC-storage convention).
  final DateTime startDate;

  /// Course duration in days. `null` for continuous medications.
  final int? durationDays;

  /// Pause length in days for a cyclic course (`0` = single bounded course).
  /// `null` for continuous medications.
  final int? pauseDays;

  /// Remaining pack inventory. `null` when stock is not tracked.
  final int? stockRemaining;

  /// Total pack inventory. `null` when stock is not tracked.
  final int? stockTotal;

  /// Low-stock warning threshold. `null` when stock is not tracked.
  final int? stockWarnAt;

  /// Optional free-text notes.
  final String? notes;

  /// Creation timestamp (UTC).
  final DateTime createdAt;
  const MedicationRow({
    required this.id,
    required this.name,
    required this.form,
    this.doseAmount,
    this.doseUnit,
    required this.typeKind,
    required this.frequency,
    required this.startDate,
    this.durationDays,
    this.pauseDays,
    this.stockRemaining,
    this.stockTotal,
    this.stockWarnAt,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['form'] = Variable<String>(
        $MedicationsTable.$converterform.toSql(form),
      );
    }
    if (!nullToAbsent || doseAmount != null) {
      map['dose_amount'] = Variable<double>(doseAmount);
    }
    if (!nullToAbsent || doseUnit != null) {
      map['dose_unit'] = Variable<String>(
        $MedicationsTable.$converterdoseUnitn.toSql(doseUnit),
      );
    }
    {
      map['type_kind'] = Variable<String>(
        $MedicationsTable.$convertertypeKind.toSql(typeKind),
      );
    }
    {
      map['frequency'] = Variable<String>(
        $MedicationsTable.$converterfrequency.toSql(frequency),
      );
    }
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || durationDays != null) {
      map['duration_days'] = Variable<int>(durationDays);
    }
    if (!nullToAbsent || pauseDays != null) {
      map['pause_days'] = Variable<int>(pauseDays);
    }
    if (!nullToAbsent || stockRemaining != null) {
      map['stock_remaining'] = Variable<int>(stockRemaining);
    }
    if (!nullToAbsent || stockTotal != null) {
      map['stock_total'] = Variable<int>(stockTotal);
    }
    if (!nullToAbsent || stockWarnAt != null) {
      map['stock_warn_at'] = Variable<int>(stockWarnAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(
      id: Value(id),
      name: Value(name),
      form: Value(form),
      doseAmount: doseAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(doseAmount),
      doseUnit: doseUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(doseUnit),
      typeKind: Value(typeKind),
      frequency: Value(frequency),
      startDate: Value(startDate),
      durationDays: durationDays == null && nullToAbsent
          ? const Value.absent()
          : Value(durationDays),
      pauseDays: pauseDays == null && nullToAbsent
          ? const Value.absent()
          : Value(pauseDays),
      stockRemaining: stockRemaining == null && nullToAbsent
          ? const Value.absent()
          : Value(stockRemaining),
      stockTotal: stockTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(stockTotal),
      stockWarnAt: stockWarnAt == null && nullToAbsent
          ? const Value.absent()
          : Value(stockWarnAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory MedicationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      form: $MedicationsTable.$converterform.fromJson(
        serializer.fromJson<String>(json['form']),
      ),
      doseAmount: serializer.fromJson<double?>(json['doseAmount']),
      doseUnit: $MedicationsTable.$converterdoseUnitn.fromJson(
        serializer.fromJson<String?>(json['doseUnit']),
      ),
      typeKind: $MedicationsTable.$convertertypeKind.fromJson(
        serializer.fromJson<String>(json['typeKind']),
      ),
      frequency: $MedicationsTable.$converterfrequency.fromJson(
        serializer.fromJson<String>(json['frequency']),
      ),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      durationDays: serializer.fromJson<int?>(json['durationDays']),
      pauseDays: serializer.fromJson<int?>(json['pauseDays']),
      stockRemaining: serializer.fromJson<int?>(json['stockRemaining']),
      stockTotal: serializer.fromJson<int?>(json['stockTotal']),
      stockWarnAt: serializer.fromJson<int?>(json['stockWarnAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'form': serializer.toJson<String>(
        $MedicationsTable.$converterform.toJson(form),
      ),
      'doseAmount': serializer.toJson<double?>(doseAmount),
      'doseUnit': serializer.toJson<String?>(
        $MedicationsTable.$converterdoseUnitn.toJson(doseUnit),
      ),
      'typeKind': serializer.toJson<String>(
        $MedicationsTable.$convertertypeKind.toJson(typeKind),
      ),
      'frequency': serializer.toJson<String>(
        $MedicationsTable.$converterfrequency.toJson(frequency),
      ),
      'startDate': serializer.toJson<DateTime>(startDate),
      'durationDays': serializer.toJson<int?>(durationDays),
      'pauseDays': serializer.toJson<int?>(pauseDays),
      'stockRemaining': serializer.toJson<int?>(stockRemaining),
      'stockTotal': serializer.toJson<int?>(stockTotal),
      'stockWarnAt': serializer.toJson<int?>(stockWarnAt),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MedicationRow copyWith({
    String? id,
    String? name,
    MedicationForm? form,
    Value<double?> doseAmount = const Value.absent(),
    Value<DoseUnit?> doseUnit = const Value.absent(),
    MedicationTypeKind? typeKind,
    ScheduleFrequency? frequency,
    DateTime? startDate,
    Value<int?> durationDays = const Value.absent(),
    Value<int?> pauseDays = const Value.absent(),
    Value<int?> stockRemaining = const Value.absent(),
    Value<int?> stockTotal = const Value.absent(),
    Value<int?> stockWarnAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => MedicationRow(
    id: id ?? this.id,
    name: name ?? this.name,
    form: form ?? this.form,
    doseAmount: doseAmount.present ? doseAmount.value : this.doseAmount,
    doseUnit: doseUnit.present ? doseUnit.value : this.doseUnit,
    typeKind: typeKind ?? this.typeKind,
    frequency: frequency ?? this.frequency,
    startDate: startDate ?? this.startDate,
    durationDays: durationDays.present ? durationDays.value : this.durationDays,
    pauseDays: pauseDays.present ? pauseDays.value : this.pauseDays,
    stockRemaining: stockRemaining.present
        ? stockRemaining.value
        : this.stockRemaining,
    stockTotal: stockTotal.present ? stockTotal.value : this.stockTotal,
    stockWarnAt: stockWarnAt.present ? stockWarnAt.value : this.stockWarnAt,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  MedicationRow copyWithCompanion(MedicationsCompanion data) {
    return MedicationRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      form: data.form.present ? data.form.value : this.form,
      doseAmount: data.doseAmount.present
          ? data.doseAmount.value
          : this.doseAmount,
      doseUnit: data.doseUnit.present ? data.doseUnit.value : this.doseUnit,
      typeKind: data.typeKind.present ? data.typeKind.value : this.typeKind,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      durationDays: data.durationDays.present
          ? data.durationDays.value
          : this.durationDays,
      pauseDays: data.pauseDays.present ? data.pauseDays.value : this.pauseDays,
      stockRemaining: data.stockRemaining.present
          ? data.stockRemaining.value
          : this.stockRemaining,
      stockTotal: data.stockTotal.present
          ? data.stockTotal.value
          : this.stockTotal,
      stockWarnAt: data.stockWarnAt.present
          ? data.stockWarnAt.value
          : this.stockWarnAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('form: $form, ')
          ..write('doseAmount: $doseAmount, ')
          ..write('doseUnit: $doseUnit, ')
          ..write('typeKind: $typeKind, ')
          ..write('frequency: $frequency, ')
          ..write('startDate: $startDate, ')
          ..write('durationDays: $durationDays, ')
          ..write('pauseDays: $pauseDays, ')
          ..write('stockRemaining: $stockRemaining, ')
          ..write('stockTotal: $stockTotal, ')
          ..write('stockWarnAt: $stockWarnAt, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    form,
    doseAmount,
    doseUnit,
    typeKind,
    frequency,
    startDate,
    durationDays,
    pauseDays,
    stockRemaining,
    stockTotal,
    stockWarnAt,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.form == this.form &&
          other.doseAmount == this.doseAmount &&
          other.doseUnit == this.doseUnit &&
          other.typeKind == this.typeKind &&
          other.frequency == this.frequency &&
          other.startDate == this.startDate &&
          other.durationDays == this.durationDays &&
          other.pauseDays == this.pauseDays &&
          other.stockRemaining == this.stockRemaining &&
          other.stockTotal == this.stockTotal &&
          other.stockWarnAt == this.stockWarnAt &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class MedicationsCompanion extends UpdateCompanion<MedicationRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<MedicationForm> form;
  final Value<double?> doseAmount;
  final Value<DoseUnit?> doseUnit;
  final Value<MedicationTypeKind> typeKind;
  final Value<ScheduleFrequency> frequency;
  final Value<DateTime> startDate;
  final Value<int?> durationDays;
  final Value<int?> pauseDays;
  final Value<int?> stockRemaining;
  final Value<int?> stockTotal;
  final Value<int?> stockWarnAt;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.form = const Value.absent(),
    this.doseAmount = const Value.absent(),
    this.doseUnit = const Value.absent(),
    this.typeKind = const Value.absent(),
    this.frequency = const Value.absent(),
    this.startDate = const Value.absent(),
    this.durationDays = const Value.absent(),
    this.pauseDays = const Value.absent(),
    this.stockRemaining = const Value.absent(),
    this.stockTotal = const Value.absent(),
    this.stockWarnAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationsCompanion.insert({
    required String id,
    required String name,
    required MedicationForm form,
    this.doseAmount = const Value.absent(),
    this.doseUnit = const Value.absent(),
    required MedicationTypeKind typeKind,
    required ScheduleFrequency frequency,
    required DateTime startDate,
    this.durationDays = const Value.absent(),
    this.pauseDays = const Value.absent(),
    this.stockRemaining = const Value.absent(),
    this.stockTotal = const Value.absent(),
    this.stockWarnAt = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       form = Value(form),
       typeKind = Value(typeKind),
       frequency = Value(frequency),
       startDate = Value(startDate),
       createdAt = Value(createdAt);
  static Insertable<MedicationRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? form,
    Expression<double>? doseAmount,
    Expression<String>? doseUnit,
    Expression<String>? typeKind,
    Expression<String>? frequency,
    Expression<DateTime>? startDate,
    Expression<int>? durationDays,
    Expression<int>? pauseDays,
    Expression<int>? stockRemaining,
    Expression<int>? stockTotal,
    Expression<int>? stockWarnAt,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (form != null) 'form': form,
      if (doseAmount != null) 'dose_amount': doseAmount,
      if (doseUnit != null) 'dose_unit': doseUnit,
      if (typeKind != null) 'type_kind': typeKind,
      if (frequency != null) 'frequency': frequency,
      if (startDate != null) 'start_date': startDate,
      if (durationDays != null) 'duration_days': durationDays,
      if (pauseDays != null) 'pause_days': pauseDays,
      if (stockRemaining != null) 'stock_remaining': stockRemaining,
      if (stockTotal != null) 'stock_total': stockTotal,
      if (stockWarnAt != null) 'stock_warn_at': stockWarnAt,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<MedicationForm>? form,
    Value<double?>? doseAmount,
    Value<DoseUnit?>? doseUnit,
    Value<MedicationTypeKind>? typeKind,
    Value<ScheduleFrequency>? frequency,
    Value<DateTime>? startDate,
    Value<int?>? durationDays,
    Value<int?>? pauseDays,
    Value<int?>? stockRemaining,
    Value<int?>? stockTotal,
    Value<int?>? stockWarnAt,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MedicationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      form: form ?? this.form,
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      typeKind: typeKind ?? this.typeKind,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      durationDays: durationDays ?? this.durationDays,
      pauseDays: pauseDays ?? this.pauseDays,
      stockRemaining: stockRemaining ?? this.stockRemaining,
      stockTotal: stockTotal ?? this.stockTotal,
      stockWarnAt: stockWarnAt ?? this.stockWarnAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (form.present) {
      map['form'] = Variable<String>(
        $MedicationsTable.$converterform.toSql(form.value),
      );
    }
    if (doseAmount.present) {
      map['dose_amount'] = Variable<double>(doseAmount.value);
    }
    if (doseUnit.present) {
      map['dose_unit'] = Variable<String>(
        $MedicationsTable.$converterdoseUnitn.toSql(doseUnit.value),
      );
    }
    if (typeKind.present) {
      map['type_kind'] = Variable<String>(
        $MedicationsTable.$convertertypeKind.toSql(typeKind.value),
      );
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(
        $MedicationsTable.$converterfrequency.toSql(frequency.value),
      );
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (durationDays.present) {
      map['duration_days'] = Variable<int>(durationDays.value);
    }
    if (pauseDays.present) {
      map['pause_days'] = Variable<int>(pauseDays.value);
    }
    if (stockRemaining.present) {
      map['stock_remaining'] = Variable<int>(stockRemaining.value);
    }
    if (stockTotal.present) {
      map['stock_total'] = Variable<int>(stockTotal.value);
    }
    if (stockWarnAt.present) {
      map['stock_warn_at'] = Variable<int>(stockWarnAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('form: $form, ')
          ..write('doseAmount: $doseAmount, ')
          ..write('doseUnit: $doseUnit, ')
          ..write('typeKind: $typeKind, ')
          ..write('frequency: $frequency, ')
          ..write('startDate: $startDate, ')
          ..write('durationDays: $durationDays, ')
          ..write('pauseDays: $pauseDays, ')
          ..write('stockRemaining: $stockRemaining, ')
          ..write('stockTotal: $stockTotal, ')
          ..write('stockWarnAt: $stockWarnAt, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimeSlotsTable extends TimeSlots
    with TableInfo<$TimeSlotsTable, TimeSlotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimeSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medications (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _minuteOfDayMeta = const VerificationMeta(
    'minuteOfDay',
  );
  @override
  late final GeneratedColumn<int> minuteOfDay = GeneratedColumn<int>(
    'minute_of_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doseAmountMeta = const VerificationMeta(
    'doseAmount',
  );
  @override
  late final GeneratedColumn<double> doseAmount = GeneratedColumn<double>(
    'dose_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DoseUnit?, String> doseUnit =
      GeneratedColumn<String>(
        'dose_unit',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DoseUnit?>($TimeSlotsTable.$converterdoseUnitn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    minuteOfDay,
    doseAmount,
    doseUnit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'time_slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimeSlotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('minute_of_day')) {
      context.handle(
        _minuteOfDayMeta,
        minuteOfDay.isAcceptableOrUnknown(
          data['minute_of_day']!,
          _minuteOfDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minuteOfDayMeta);
    }
    if (data.containsKey('dose_amount')) {
      context.handle(
        _doseAmountMeta,
        doseAmount.isAcceptableOrUnknown(data['dose_amount']!, _doseAmountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimeSlotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimeSlotRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      minuteOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute_of_day'],
      )!,
      doseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dose_amount'],
      ),
      doseUnit: $TimeSlotsTable.$converterdoseUnitn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}dose_unit'],
        ),
      ),
    );
  }

  @override
  $TimeSlotsTable createAlias(String alias) {
    return $TimeSlotsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DoseUnit, String, String> $converterdoseUnit =
      const EnumNameConverter<DoseUnit>(DoseUnit.values);
  static JsonTypeConverter2<DoseUnit?, String?, String?> $converterdoseUnitn =
      JsonTypeConverter2.asNullable($converterdoseUnit);
}

class TimeSlotRow extends DataClass implements Insertable<TimeSlotRow> {
  /// Stable unique identifier (domain `TimeSlot` id). Primary key.
  final String id;

  /// Owning medication. Cascades on delete so slots never outlive their med.
  final String medicationId;

  /// Local time of day, in minutes from midnight (`0..1439`).
  final int minuteOfDay;

  /// Per-slot dose amount override. `null` uses the medication default.
  final double? doseAmount;

  /// Unit for [doseAmount] override. Stored by enum name. `null` uses default.
  final DoseUnit? doseUnit;
  const TimeSlotRow({
    required this.id,
    required this.medicationId,
    required this.minuteOfDay,
    this.doseAmount,
    this.doseUnit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['medication_id'] = Variable<String>(medicationId);
    map['minute_of_day'] = Variable<int>(minuteOfDay);
    if (!nullToAbsent || doseAmount != null) {
      map['dose_amount'] = Variable<double>(doseAmount);
    }
    if (!nullToAbsent || doseUnit != null) {
      map['dose_unit'] = Variable<String>(
        $TimeSlotsTable.$converterdoseUnitn.toSql(doseUnit),
      );
    }
    return map;
  }

  TimeSlotsCompanion toCompanion(bool nullToAbsent) {
    return TimeSlotsCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      minuteOfDay: Value(minuteOfDay),
      doseAmount: doseAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(doseAmount),
      doseUnit: doseUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(doseUnit),
    );
  }

  factory TimeSlotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimeSlotRow(
      id: serializer.fromJson<String>(json['id']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      minuteOfDay: serializer.fromJson<int>(json['minuteOfDay']),
      doseAmount: serializer.fromJson<double?>(json['doseAmount']),
      doseUnit: $TimeSlotsTable.$converterdoseUnitn.fromJson(
        serializer.fromJson<String?>(json['doseUnit']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'medicationId': serializer.toJson<String>(medicationId),
      'minuteOfDay': serializer.toJson<int>(minuteOfDay),
      'doseAmount': serializer.toJson<double?>(doseAmount),
      'doseUnit': serializer.toJson<String?>(
        $TimeSlotsTable.$converterdoseUnitn.toJson(doseUnit),
      ),
    };
  }

  TimeSlotRow copyWith({
    String? id,
    String? medicationId,
    int? minuteOfDay,
    Value<double?> doseAmount = const Value.absent(),
    Value<DoseUnit?> doseUnit = const Value.absent(),
  }) => TimeSlotRow(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    minuteOfDay: minuteOfDay ?? this.minuteOfDay,
    doseAmount: doseAmount.present ? doseAmount.value : this.doseAmount,
    doseUnit: doseUnit.present ? doseUnit.value : this.doseUnit,
  );
  TimeSlotRow copyWithCompanion(TimeSlotsCompanion data) {
    return TimeSlotRow(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      minuteOfDay: data.minuteOfDay.present
          ? data.minuteOfDay.value
          : this.minuteOfDay,
      doseAmount: data.doseAmount.present
          ? data.doseAmount.value
          : this.doseAmount,
      doseUnit: data.doseUnit.present ? data.doseUnit.value : this.doseUnit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimeSlotRow(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('minuteOfDay: $minuteOfDay, ')
          ..write('doseAmount: $doseAmount, ')
          ..write('doseUnit: $doseUnit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, medicationId, minuteOfDay, doseAmount, doseUnit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimeSlotRow &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.minuteOfDay == this.minuteOfDay &&
          other.doseAmount == this.doseAmount &&
          other.doseUnit == this.doseUnit);
}

class TimeSlotsCompanion extends UpdateCompanion<TimeSlotRow> {
  final Value<String> id;
  final Value<String> medicationId;
  final Value<int> minuteOfDay;
  final Value<double?> doseAmount;
  final Value<DoseUnit?> doseUnit;
  final Value<int> rowid;
  const TimeSlotsCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.minuteOfDay = const Value.absent(),
    this.doseAmount = const Value.absent(),
    this.doseUnit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimeSlotsCompanion.insert({
    required String id,
    required String medicationId,
    required int minuteOfDay,
    this.doseAmount = const Value.absent(),
    this.doseUnit = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       medicationId = Value(medicationId),
       minuteOfDay = Value(minuteOfDay);
  static Insertable<TimeSlotRow> custom({
    Expression<String>? id,
    Expression<String>? medicationId,
    Expression<int>? minuteOfDay,
    Expression<double>? doseAmount,
    Expression<String>? doseUnit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (minuteOfDay != null) 'minute_of_day': minuteOfDay,
      if (doseAmount != null) 'dose_amount': doseAmount,
      if (doseUnit != null) 'dose_unit': doseUnit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimeSlotsCompanion copyWith({
    Value<String>? id,
    Value<String>? medicationId,
    Value<int>? minuteOfDay,
    Value<double?>? doseAmount,
    Value<DoseUnit?>? doseUnit,
    Value<int>? rowid,
  }) {
    return TimeSlotsCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      minuteOfDay: minuteOfDay ?? this.minuteOfDay,
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (minuteOfDay.present) {
      map['minute_of_day'] = Variable<int>(minuteOfDay.value);
    }
    if (doseAmount.present) {
      map['dose_amount'] = Variable<double>(doseAmount.value);
    }
    if (doseUnit.present) {
      map['dose_unit'] = Variable<String>(
        $TimeSlotsTable.$converterdoseUnitn.toSql(doseUnit.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimeSlotsCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('minuteOfDay: $minuteOfDay, ')
          ..write('doseAmount: $doseAmount, ')
          ..write('doseUnit: $doseUnit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IntakesTable extends Intakes with TableInfo<$IntakesTable, IntakeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntakesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medications (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _slotIdMeta = const VerificationMeta('slotId');
  @override
  late final GeneratedColumn<String> slotId = GeneratedColumn<String>(
    'slot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<DateTime> confirmedAt = GeneratedColumn<DateTime>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<IntakeStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<IntakeStatus>($IntakesTable.$converterstatus);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    slotId,
    scheduledAt,
    confirmedAt,
    status,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intakes';
  @override
  VerificationContext validateIntegrity(
    Insertable<IntakeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('slot_id')) {
      context.handle(
        _slotIdMeta,
        slotId.isAcceptableOrUnknown(data['slot_id']!, _slotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_slotIdMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {medicationId, slotId, scheduledAt},
  ];
  @override
  IntakeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntakeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      slotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot_id'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}confirmed_at'],
      ),
      status: $IntakesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $IntakesTable createAlias(String alias) {
    return $IntakesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<IntakeStatus, String, String> $converterstatus =
      const EnumNameConverter<IntakeStatus>(IntakeStatus.values);
}

class IntakeRow extends DataClass implements Insertable<IntakeRow> {
  /// Stable unique identifier (domain `IntakeId` value). Primary key.
  final String id;

  /// Owning medication. Cascades on delete so intakes never outlive their med.
  final String medicationId;

  /// The schedule slot this occurrence belongs to (domain `TimeSlot` id).
  ///
  /// Intentionally a PLAIN text column with NO foreign key. Slot rows are
  /// reconciled — inserted, updated, and deleted — whenever a medication's
  /// schedule is edited. An FK with `onDelete: cascade` would wipe historical
  /// intake rows the moment their slot was reconciled away, silently erasing a
  /// user's adherence history. Keeping [slotId] a plain column decouples intake
  /// history from slot reconciliation.
  final String slotId;

  /// UTC instant of the scheduled dose (per the UTC-storage convention).
  final DateTime scheduledAt;

  /// UTC instant the user acted on the occurrence. `null` until confirmed.
  final DateTime? confirmedAt;

  /// Lifecycle state of this occurrence. Stored by enum name.
  final IntakeStatus status;

  /// Optional free-text notes. Unused in the current slice.
  final String? notes;
  const IntakeRow({
    required this.id,
    required this.medicationId,
    required this.slotId,
    required this.scheduledAt,
    this.confirmedAt,
    required this.status,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['medication_id'] = Variable<String>(medicationId);
    map['slot_id'] = Variable<String>(slotId);
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt);
    }
    {
      map['status'] = Variable<String>(
        $IntakesTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  IntakesCompanion toCompanion(bool nullToAbsent) {
    return IntakesCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      slotId: Value(slotId),
      scheduledAt: Value(scheduledAt),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
      status: Value(status),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory IntakeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntakeRow(
      id: serializer.fromJson<String>(json['id']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      slotId: serializer.fromJson<String>(json['slotId']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      confirmedAt: serializer.fromJson<DateTime?>(json['confirmedAt']),
      status: $IntakesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'medicationId': serializer.toJson<String>(medicationId),
      'slotId': serializer.toJson<String>(slotId),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'confirmedAt': serializer.toJson<DateTime?>(confirmedAt),
      'status': serializer.toJson<String>(
        $IntakesTable.$converterstatus.toJson(status),
      ),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  IntakeRow copyWith({
    String? id,
    String? medicationId,
    String? slotId,
    DateTime? scheduledAt,
    Value<DateTime?> confirmedAt = const Value.absent(),
    IntakeStatus? status,
    Value<String?> notes = const Value.absent(),
  }) => IntakeRow(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    slotId: slotId ?? this.slotId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
    status: status ?? this.status,
    notes: notes.present ? notes.value : this.notes,
  );
  IntakeRow copyWithCompanion(IntakesCompanion data) {
    return IntakeRow(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      slotId: data.slotId.present ? data.slotId.value : this.slotId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntakeRow(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('slotId: $slotId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('status: $status, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    medicationId,
    slotId,
    scheduledAt,
    confirmedAt,
    status,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntakeRow &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.slotId == this.slotId &&
          other.scheduledAt == this.scheduledAt &&
          other.confirmedAt == this.confirmedAt &&
          other.status == this.status &&
          other.notes == this.notes);
}

class IntakesCompanion extends UpdateCompanion<IntakeRow> {
  final Value<String> id;
  final Value<String> medicationId;
  final Value<String> slotId;
  final Value<DateTime> scheduledAt;
  final Value<DateTime?> confirmedAt;
  final Value<IntakeStatus> status;
  final Value<String?> notes;
  final Value<int> rowid;
  const IntakesCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.slotId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntakesCompanion.insert({
    required String id,
    required String medicationId,
    required String slotId,
    required DateTime scheduledAt,
    this.confirmedAt = const Value.absent(),
    required IntakeStatus status,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       medicationId = Value(medicationId),
       slotId = Value(slotId),
       scheduledAt = Value(scheduledAt),
       status = Value(status);
  static Insertable<IntakeRow> custom({
    Expression<String>? id,
    Expression<String>? medicationId,
    Expression<String>? slotId,
    Expression<DateTime>? scheduledAt,
    Expression<DateTime>? confirmedAt,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (slotId != null) 'slot_id': slotId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntakesCompanion copyWith({
    Value<String>? id,
    Value<String>? medicationId,
    Value<String>? slotId,
    Value<DateTime>? scheduledAt,
    Value<DateTime?>? confirmedAt,
    Value<IntakeStatus>? status,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return IntakesCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      slotId: slotId ?? this.slotId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (slotId.present) {
      map['slot_id'] = Variable<String>(slotId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $IntakesTable.$converterstatus.toSql(status.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntakesCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('slotId: $slotId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MedicationsTable medications = $MedicationsTable(this);
  late final $TimeSlotsTable timeSlots = $TimeSlotsTable(this);
  late final $IntakesTable intakes = $IntakesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    medications,
    timeSlots,
    intakes,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'medications',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('time_slots', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'medications',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('intakes', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$MedicationsTableCreateCompanionBuilder =
    MedicationsCompanion Function({
      required String id,
      required String name,
      required MedicationForm form,
      Value<double?> doseAmount,
      Value<DoseUnit?> doseUnit,
      required MedicationTypeKind typeKind,
      required ScheduleFrequency frequency,
      required DateTime startDate,
      Value<int?> durationDays,
      Value<int?> pauseDays,
      Value<int?> stockRemaining,
      Value<int?> stockTotal,
      Value<int?> stockWarnAt,
      Value<String?> notes,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$MedicationsTableUpdateCompanionBuilder =
    MedicationsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<MedicationForm> form,
      Value<double?> doseAmount,
      Value<DoseUnit?> doseUnit,
      Value<MedicationTypeKind> typeKind,
      Value<ScheduleFrequency> frequency,
      Value<DateTime> startDate,
      Value<int?> durationDays,
      Value<int?> pauseDays,
      Value<int?> stockRemaining,
      Value<int?> stockTotal,
      Value<int?> stockWarnAt,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$MedicationsTableReferences
    extends BaseReferences<_$AppDatabase, $MedicationsTable, MedicationRow> {
  $$MedicationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TimeSlotsTable, List<TimeSlotRow>>
  _timeSlotsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.timeSlots,
    aliasName: $_aliasNameGenerator(
      db.medications.id,
      db.timeSlots.medicationId,
    ),
  );

  $$TimeSlotsTableProcessedTableManager get timeSlotsRefs {
    final manager = $$TimeSlotsTableTableManager(
      $_db,
      $_db.timeSlots,
    ).filter((f) => f.medicationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_timeSlotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$IntakesTable, List<IntakeRow>> _intakesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.intakes,
    aliasName: $_aliasNameGenerator(db.medications.id, db.intakes.medicationId),
  );

  $$IntakesTableProcessedTableManager get intakesRefs {
    final manager = $$IntakesTableTableManager(
      $_db,
      $_db.intakes,
    ).filter((f) => f.medicationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_intakesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MedicationsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MedicationForm, MedicationForm, String>
  get form => $composableBuilder(
    column: $table.form,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DoseUnit?, DoseUnit, String> get doseUnit =>
      $composableBuilder(
        column: $table.doseUnit,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<MedicationTypeKind, MedicationTypeKind, String>
  get typeKind => $composableBuilder(
    column: $table.typeKind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ScheduleFrequency, ScheduleFrequency, String>
  get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pauseDays => $composableBuilder(
    column: $table.pauseDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockRemaining => $composableBuilder(
    column: $table.stockRemaining,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockTotal => $composableBuilder(
    column: $table.stockTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockWarnAt => $composableBuilder(
    column: $table.stockWarnAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> timeSlotsRefs(
    Expression<bool> Function($$TimeSlotsTableFilterComposer f) f,
  ) {
    final $$TimeSlotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timeSlots,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimeSlotsTableFilterComposer(
            $db: $db,
            $table: $db.timeSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> intakesRefs(
    Expression<bool> Function($$IntakesTableFilterComposer f) f,
  ) {
    final $$IntakesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.intakes,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntakesTableFilterComposer(
            $db: $db,
            $table: $db.intakes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MedicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get form => $composableBuilder(
    column: $table.form,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doseUnit => $composableBuilder(
    column: $table.doseUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeKind => $composableBuilder(
    column: $table.typeKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pauseDays => $composableBuilder(
    column: $table.pauseDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockRemaining => $composableBuilder(
    column: $table.stockRemaining,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockTotal => $composableBuilder(
    column: $table.stockTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockWarnAt => $composableBuilder(
    column: $table.stockWarnAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MedicationForm, String> get form =>
      $composableBuilder(column: $table.form, builder: (column) => column);

  GeneratedColumn<double> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DoseUnit?, String> get doseUnit =>
      $composableBuilder(column: $table.doseUnit, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MedicationTypeKind, String> get typeKind =>
      $composableBuilder(column: $table.typeKind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ScheduleFrequency, String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pauseDays =>
      $composableBuilder(column: $table.pauseDays, builder: (column) => column);

  GeneratedColumn<int> get stockRemaining => $composableBuilder(
    column: $table.stockRemaining,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stockTotal => $composableBuilder(
    column: $table.stockTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stockWarnAt => $composableBuilder(
    column: $table.stockWarnAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> timeSlotsRefs<T extends Object>(
    Expression<T> Function($$TimeSlotsTableAnnotationComposer a) f,
  ) {
    final $$TimeSlotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timeSlots,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimeSlotsTableAnnotationComposer(
            $db: $db,
            $table: $db.timeSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> intakesRefs<T extends Object>(
    Expression<T> Function($$IntakesTableAnnotationComposer a) f,
  ) {
    final $$IntakesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.intakes,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntakesTableAnnotationComposer(
            $db: $db,
            $table: $db.intakes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MedicationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationsTable,
          MedicationRow,
          $$MedicationsTableFilterComposer,
          $$MedicationsTableOrderingComposer,
          $$MedicationsTableAnnotationComposer,
          $$MedicationsTableCreateCompanionBuilder,
          $$MedicationsTableUpdateCompanionBuilder,
          (MedicationRow, $$MedicationsTableReferences),
          MedicationRow,
          PrefetchHooks Function({bool timeSlotsRefs, bool intakesRefs})
        > {
  $$MedicationsTableTableManager(_$AppDatabase db, $MedicationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<MedicationForm> form = const Value.absent(),
                Value<double?> doseAmount = const Value.absent(),
                Value<DoseUnit?> doseUnit = const Value.absent(),
                Value<MedicationTypeKind> typeKind = const Value.absent(),
                Value<ScheduleFrequency> frequency = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<int?> durationDays = const Value.absent(),
                Value<int?> pauseDays = const Value.absent(),
                Value<int?> stockRemaining = const Value.absent(),
                Value<int?> stockTotal = const Value.absent(),
                Value<int?> stockWarnAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion(
                id: id,
                name: name,
                form: form,
                doseAmount: doseAmount,
                doseUnit: doseUnit,
                typeKind: typeKind,
                frequency: frequency,
                startDate: startDate,
                durationDays: durationDays,
                pauseDays: pauseDays,
                stockRemaining: stockRemaining,
                stockTotal: stockTotal,
                stockWarnAt: stockWarnAt,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required MedicationForm form,
                Value<double?> doseAmount = const Value.absent(),
                Value<DoseUnit?> doseUnit = const Value.absent(),
                required MedicationTypeKind typeKind,
                required ScheduleFrequency frequency,
                required DateTime startDate,
                Value<int?> durationDays = const Value.absent(),
                Value<int?> pauseDays = const Value.absent(),
                Value<int?> stockRemaining = const Value.absent(),
                Value<int?> stockTotal = const Value.absent(),
                Value<int?> stockWarnAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion.insert(
                id: id,
                name: name,
                form: form,
                doseAmount: doseAmount,
                doseUnit: doseUnit,
                typeKind: typeKind,
                frequency: frequency,
                startDate: startDate,
                durationDays: durationDays,
                pauseDays: pauseDays,
                stockRemaining: stockRemaining,
                stockTotal: stockTotal,
                stockWarnAt: stockWarnAt,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MedicationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({timeSlotsRefs = false, intakesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (timeSlotsRefs) db.timeSlots,
                    if (intakesRefs) db.intakes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (timeSlotsRefs)
                        await $_getPrefetchedData<
                          MedicationRow,
                          $MedicationsTable,
                          TimeSlotRow
                        >(
                          currentTable: table,
                          referencedTable: $$MedicationsTableReferences
                              ._timeSlotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MedicationsTableReferences(
                                db,
                                table,
                                p0,
                              ).timeSlotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.medicationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (intakesRefs)
                        await $_getPrefetchedData<
                          MedicationRow,
                          $MedicationsTable,
                          IntakeRow
                        >(
                          currentTable: table,
                          referencedTable: $$MedicationsTableReferences
                              ._intakesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MedicationsTableReferences(
                                db,
                                table,
                                p0,
                              ).intakesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.medicationId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MedicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationsTable,
      MedicationRow,
      $$MedicationsTableFilterComposer,
      $$MedicationsTableOrderingComposer,
      $$MedicationsTableAnnotationComposer,
      $$MedicationsTableCreateCompanionBuilder,
      $$MedicationsTableUpdateCompanionBuilder,
      (MedicationRow, $$MedicationsTableReferences),
      MedicationRow,
      PrefetchHooks Function({bool timeSlotsRefs, bool intakesRefs})
    >;
typedef $$TimeSlotsTableCreateCompanionBuilder =
    TimeSlotsCompanion Function({
      required String id,
      required String medicationId,
      required int minuteOfDay,
      Value<double?> doseAmount,
      Value<DoseUnit?> doseUnit,
      Value<int> rowid,
    });
typedef $$TimeSlotsTableUpdateCompanionBuilder =
    TimeSlotsCompanion Function({
      Value<String> id,
      Value<String> medicationId,
      Value<int> minuteOfDay,
      Value<double?> doseAmount,
      Value<DoseUnit?> doseUnit,
      Value<int> rowid,
    });

final class $$TimeSlotsTableReferences
    extends BaseReferences<_$AppDatabase, $TimeSlotsTable, TimeSlotRow> {
  $$TimeSlotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MedicationsTable _medicationIdTable(_$AppDatabase db) =>
      db.medications.createAlias(
        $_aliasNameGenerator(db.timeSlots.medicationId, db.medications.id),
      );

  $$MedicationsTableProcessedTableManager get medicationId {
    final $_column = $_itemColumn<String>('medication_id')!;

    final manager = $$MedicationsTableTableManager(
      $_db,
      $_db.medications,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_medicationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TimeSlotsTableFilterComposer
    extends Composer<_$AppDatabase, $TimeSlotsTable> {
  $$TimeSlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minuteOfDay => $composableBuilder(
    column: $table.minuteOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DoseUnit?, DoseUnit, String> get doseUnit =>
      $composableBuilder(
        column: $table.doseUnit,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$MedicationsTableFilterComposer get medicationId {
    final $$MedicationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableFilterComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimeSlotsTableOrderingComposer
    extends Composer<_$AppDatabase, $TimeSlotsTable> {
  $$TimeSlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minuteOfDay => $composableBuilder(
    column: $table.minuteOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doseUnit => $composableBuilder(
    column: $table.doseUnit,
    builder: (column) => ColumnOrderings(column),
  );

  $$MedicationsTableOrderingComposer get medicationId {
    final $$MedicationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableOrderingComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimeSlotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimeSlotsTable> {
  $$TimeSlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get minuteOfDay => $composableBuilder(
    column: $table.minuteOfDay,
    builder: (column) => column,
  );

  GeneratedColumn<double> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DoseUnit?, String> get doseUnit =>
      $composableBuilder(column: $table.doseUnit, builder: (column) => column);

  $$MedicationsTableAnnotationComposer get medicationId {
    final $$MedicationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableAnnotationComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimeSlotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimeSlotsTable,
          TimeSlotRow,
          $$TimeSlotsTableFilterComposer,
          $$TimeSlotsTableOrderingComposer,
          $$TimeSlotsTableAnnotationComposer,
          $$TimeSlotsTableCreateCompanionBuilder,
          $$TimeSlotsTableUpdateCompanionBuilder,
          (TimeSlotRow, $$TimeSlotsTableReferences),
          TimeSlotRow,
          PrefetchHooks Function({bool medicationId})
        > {
  $$TimeSlotsTableTableManager(_$AppDatabase db, $TimeSlotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimeSlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimeSlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimeSlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<int> minuteOfDay = const Value.absent(),
                Value<double?> doseAmount = const Value.absent(),
                Value<DoseUnit?> doseUnit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimeSlotsCompanion(
                id: id,
                medicationId: medicationId,
                minuteOfDay: minuteOfDay,
                doseAmount: doseAmount,
                doseUnit: doseUnit,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String medicationId,
                required int minuteOfDay,
                Value<double?> doseAmount = const Value.absent(),
                Value<DoseUnit?> doseUnit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimeSlotsCompanion.insert(
                id: id,
                medicationId: medicationId,
                minuteOfDay: minuteOfDay,
                doseAmount: doseAmount,
                doseUnit: doseUnit,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TimeSlotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({medicationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (medicationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.medicationId,
                                referencedTable: $$TimeSlotsTableReferences
                                    ._medicationIdTable(db),
                                referencedColumn: $$TimeSlotsTableReferences
                                    ._medicationIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TimeSlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimeSlotsTable,
      TimeSlotRow,
      $$TimeSlotsTableFilterComposer,
      $$TimeSlotsTableOrderingComposer,
      $$TimeSlotsTableAnnotationComposer,
      $$TimeSlotsTableCreateCompanionBuilder,
      $$TimeSlotsTableUpdateCompanionBuilder,
      (TimeSlotRow, $$TimeSlotsTableReferences),
      TimeSlotRow,
      PrefetchHooks Function({bool medicationId})
    >;
typedef $$IntakesTableCreateCompanionBuilder =
    IntakesCompanion Function({
      required String id,
      required String medicationId,
      required String slotId,
      required DateTime scheduledAt,
      Value<DateTime?> confirmedAt,
      required IntakeStatus status,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$IntakesTableUpdateCompanionBuilder =
    IntakesCompanion Function({
      Value<String> id,
      Value<String> medicationId,
      Value<String> slotId,
      Value<DateTime> scheduledAt,
      Value<DateTime?> confirmedAt,
      Value<IntakeStatus> status,
      Value<String?> notes,
      Value<int> rowid,
    });

final class $$IntakesTableReferences
    extends BaseReferences<_$AppDatabase, $IntakesTable, IntakeRow> {
  $$IntakesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MedicationsTable _medicationIdTable(_$AppDatabase db) =>
      db.medications.createAlias(
        $_aliasNameGenerator(db.intakes.medicationId, db.medications.id),
      );

  $$MedicationsTableProcessedTableManager get medicationId {
    final $_column = $_itemColumn<String>('medication_id')!;

    final manager = $$MedicationsTableTableManager(
      $_db,
      $_db.medications,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_medicationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IntakesTableFilterComposer
    extends Composer<_$AppDatabase, $IntakesTable> {
  $$IntakesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slotId => $composableBuilder(
    column: $table.slotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<IntakeStatus, IntakeStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$MedicationsTableFilterComposer get medicationId {
    final $$MedicationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableFilterComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntakesTableOrderingComposer
    extends Composer<_$AppDatabase, $IntakesTable> {
  $$IntakesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slotId => $composableBuilder(
    column: $table.slotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$MedicationsTableOrderingComposer get medicationId {
    final $$MedicationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableOrderingComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntakesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntakesTable> {
  $$IntakesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slotId =>
      $composableBuilder(column: $table.slotId, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<IntakeStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$MedicationsTableAnnotationComposer get medicationId {
    final $$MedicationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableAnnotationComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntakesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IntakesTable,
          IntakeRow,
          $$IntakesTableFilterComposer,
          $$IntakesTableOrderingComposer,
          $$IntakesTableAnnotationComposer,
          $$IntakesTableCreateCompanionBuilder,
          $$IntakesTableUpdateCompanionBuilder,
          (IntakeRow, $$IntakesTableReferences),
          IntakeRow,
          PrefetchHooks Function({bool medicationId})
        > {
  $$IntakesTableTableManager(_$AppDatabase db, $IntakesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntakesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntakesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntakesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<String> slotId = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
                Value<IntakeStatus> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IntakesCompanion(
                id: id,
                medicationId: medicationId,
                slotId: slotId,
                scheduledAt: scheduledAt,
                confirmedAt: confirmedAt,
                status: status,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String medicationId,
                required String slotId,
                required DateTime scheduledAt,
                Value<DateTime?> confirmedAt = const Value.absent(),
                required IntakeStatus status,
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IntakesCompanion.insert(
                id: id,
                medicationId: medicationId,
                slotId: slotId,
                scheduledAt: scheduledAt,
                confirmedAt: confirmedAt,
                status: status,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IntakesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({medicationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (medicationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.medicationId,
                                referencedTable: $$IntakesTableReferences
                                    ._medicationIdTable(db),
                                referencedColumn: $$IntakesTableReferences
                                    ._medicationIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IntakesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IntakesTable,
      IntakeRow,
      $$IntakesTableFilterComposer,
      $$IntakesTableOrderingComposer,
      $$IntakesTableAnnotationComposer,
      $$IntakesTableCreateCompanionBuilder,
      $$IntakesTableUpdateCompanionBuilder,
      (IntakeRow, $$IntakesTableReferences),
      IntakeRow,
      PrefetchHooks Function({bool medicationId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db, _db.medications);
  $$TimeSlotsTableTableManager get timeSlots =>
      $$TimeSlotsTableTableManager(_db, _db.timeSlots);
  $$IntakesTableTableManager get intakes =>
      $$IntakesTableTableManager(_db, _db.intakes);
}
