/// Injectable identifier source.
///
/// This abstraction exists so that domain code can mint new identifiers
/// without importing a concrete UUID implementation. The `package:uuid`
/// dependency is deliberately kept out of the `domain/` layer per
/// constitution §2.1 (domain must be pure Dart with no third-party SDKs).
/// Code that needs an ID depends on this interface instead, and the concrete
/// [IdGenerator] is supplied via dependency injection (mirroring the project's
/// `Clock` injection philosophy).
///
/// In tests, inject a stub implementation that returns deterministic IDs so
/// generated identifiers are predictable and assertions stay stable.
library;

/// Mints unique string identifiers.
///
/// Implementations live outside `domain/` (e.g. in `core/`) so that the
/// concrete UUID library never leaks into the pure-Dart domain layer.
abstract interface class IdGenerator {
  /// Returns a freshly generated, unique identifier.
  String newId();
}
