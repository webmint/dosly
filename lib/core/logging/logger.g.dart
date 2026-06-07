// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logger.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keep-alive provider exposing the app-wide named [Logger].
///
/// This is the consumption point for the logging pipeline: on first build it
/// calls [configureLogging] (level from [levelFor] / `kReleaseMode`, error
/// detail from `kDebugMode`) and binds the resulting subscription's
/// cancellation to the provider lifetime via `ref.onDispose`.
///
/// Call sites log through the returned instance, e.g.
/// `ref.read(loggerProvider).warning('msg', failure)`.

@ProviderFor(logger)
final loggerProvider = LoggerProvider._();

/// Keep-alive provider exposing the app-wide named [Logger].
///
/// This is the consumption point for the logging pipeline: on first build it
/// calls [configureLogging] (level from [levelFor] / `kReleaseMode`, error
/// detail from `kDebugMode`) and binds the resulting subscription's
/// cancellation to the provider lifetime via `ref.onDispose`.
///
/// Call sites log through the returned instance, e.g.
/// `ref.read(loggerProvider).warning('msg', failure)`.

final class LoggerProvider extends $FunctionalProvider<Logger, Logger, Logger>
    with $Provider<Logger> {
  /// Keep-alive provider exposing the app-wide named [Logger].
  ///
  /// This is the consumption point for the logging pipeline: on first build it
  /// calls [configureLogging] (level from [levelFor] / `kReleaseMode`, error
  /// detail from `kDebugMode`) and binds the resulting subscription's
  /// cancellation to the provider lifetime via `ref.onDispose`.
  ///
  /// Call sites log through the returned instance, e.g.
  /// `ref.read(loggerProvider).warning('msg', failure)`.
  LoggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loggerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loggerHash();

  @$internal
  @override
  $ProviderElement<Logger> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Logger create(Ref ref) {
    return logger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Logger value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Logger>(value),
    );
  }
}

String _$loggerHash() => r'64d0e1bffd6f36e0c74465b89cc9a3414072707f';
