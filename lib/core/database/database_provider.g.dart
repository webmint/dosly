// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the application-wide [AppDatabase] instance.
///
/// Kept alive for the app's lifetime (the database is the system of record and
/// should not be torn down between widget rebuilds). The instance is closed via
/// [Ref.onDispose] when the provider is disposed, releasing the SQLite
/// connection. Tests override this with a database backed by an in-memory
/// executor (see [AppDatabase]'s optional-executor constructor).

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// Provides the application-wide [AppDatabase] instance.
///
/// Kept alive for the app's lifetime (the database is the system of record and
/// should not be torn down between widget rebuilds). The instance is closed via
/// [Ref.onDispose] when the provider is disposed, releasing the SQLite
/// connection. Tests override this with a database backed by an in-memory
/// executor (see [AppDatabase]'s optional-executor constructor).

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Provides the application-wide [AppDatabase] instance.
  ///
  /// Kept alive for the app's lifetime (the database is the system of record and
  /// should not be torn down between widget rebuilds). The instance is closed via
  /// [Ref.onDispose] when the provider is disposed, releasing the SQLite
  /// connection. Tests override this with a database backed by an in-memory
  /// executor (see [AppDatabase]'s optional-executor constructor).
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';
