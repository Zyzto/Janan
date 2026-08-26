// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Local-only PowerSync database. Override after [HealthDatabase.open].

@ProviderFor(healthDatabase)
final healthDatabaseProvider = HealthDatabaseProvider._();

/// Local-only PowerSync database. Override after [HealthDatabase.open].

final class HealthDatabaseProvider
    extends
        $FunctionalProvider<
          PowerSyncDatabase,
          PowerSyncDatabase,
          PowerSyncDatabase
        >
    with $Provider<PowerSyncDatabase> {
  /// Local-only PowerSync database. Override after [HealthDatabase.open].
  HealthDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthDatabaseHash();

  @$internal
  @override
  $ProviderElement<PowerSyncDatabase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PowerSyncDatabase create(Ref ref) {
    return healthDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PowerSyncDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PowerSyncDatabase>(value),
    );
  }
}

String _$healthDatabaseHash() => r'dbd5e5615800e4e4f3815a01f3466ec746cef82f';
