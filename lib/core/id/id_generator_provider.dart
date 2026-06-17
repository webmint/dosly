/// Riverpod provider for the application-wide [IdGenerator].
///
/// Exposes the `domain/`-friendly [IdGenerator] abstraction while constructing
/// the concrete [UuidIdGenerator] here in `core/`, keeping `package:uuid` out
/// of the domain layer (constitution §2.1). Tests override
/// [idGeneratorProvider] with a deterministic stub to get predictable IDs.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'id_generator.dart';
import 'uuid_id_generator.dart';

part 'id_generator_provider.g.dart';

/// Provides the application-wide [IdGenerator].
///
/// Returns the production [UuidIdGenerator]. Kept alive for the app lifetime
/// since the generator is stateless and cheap to retain. Tests may override
/// this provider with a stub that returns deterministic identifiers.
@Riverpod(keepAlive: true)
IdGenerator idGenerator(Ref ref) => const UuidIdGenerator();
