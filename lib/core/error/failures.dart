/// Core failure types for the dosly application.
///
/// All domain-layer operations that can fail return `Either<Failure, T>`.
/// Each [Failure] subclass represents a specific category of error so that
/// presentation code can pattern-match exhaustively using Dart 3 sealed-class
/// switches.
library;

/// Base failure type for the dosly domain layer.
///
/// Sealed so that the compiler enforces exhaustive handling of every subtype
/// in `switch` expressions.
sealed class Failure {
  /// Creates a [Failure].
  const Failure();
}

/// A failure originating from local cache operations (e.g. shared preferences,
/// drift database).
class CacheFailure extends Failure {
  /// Creates a [CacheFailure] with a human-readable [message].
  const CacheFailure(this.message);

  /// Human-readable description of what went wrong.
  final String message;
}
