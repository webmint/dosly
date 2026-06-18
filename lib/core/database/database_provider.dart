/// Riverpod provider for the app-wide [AppDatabase].
///
/// Mirrors the keep-alive style of `core/providers/shared_preferences_provider`:
/// a single long-lived instance shared across the app, disposed when the owning
/// `ProviderContainer` is torn down. Tests may override this provider with an
/// `AppDatabase` built on an in-memory executor.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'database.dart';

part 'database_provider.g.dart';

/// Provides the application-wide [AppDatabase] instance.
///
/// Kept alive for the app's lifetime (the database is the system of record and
/// should not be torn down between widget rebuilds). The instance is closed via
/// [Ref.onDispose] when the provider is disposed, releasing the SQLite
/// connection. Tests override this with a database backed by an in-memory
/// executor (see [AppDatabase]'s optional-executor constructor).
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
