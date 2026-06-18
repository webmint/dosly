/// UUID-backed [IdGenerator] implementation.
///
/// This lives in `core/` (not `domain/`), so importing `package:uuid` here is
/// allowed — it keeps the UUID dependency out of the pure-Dart domain layer
/// per constitution §2.1.
library;

import 'package:uuid/uuid.dart';

import 'id_generator.dart';

/// An [IdGenerator] that produces random version-4 UUIDs.
///
/// Each call to [newId] returns a new RFC 4122 v4 UUID string. This is the
/// production implementation wired in via `idGeneratorProvider`; tests inject
/// a deterministic stub instead.
class UuidIdGenerator implements IdGenerator {
  /// Creates a UUID-backed identifier generator.
  const UuidIdGenerator();

  @override
  String newId() => const Uuid().v4();
}
