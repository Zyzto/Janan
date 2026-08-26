// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bloodPressureRecords)
final bloodPressureRecordsProvider = BloodPressureRecordsFamily._();

final class BloodPressureRecordsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BloodPressureRecord>>,
          List<BloodPressureRecord>,
          Stream<List<BloodPressureRecord>>
        >
    with
        $FutureModifier<List<BloodPressureRecord>>,
        $StreamProvider<List<BloodPressureRecord>> {
  BloodPressureRecordsProvider._({
    required BloodPressureRecordsFamily super.from,
    required IntervalStoreManagerLocation super.argument,
  }) : super(
         retry: null,
         name: r'bloodPressureRecordsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bloodPressureRecordsHash();

  @override
  String toString() {
    return r'bloodPressureRecordsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<BloodPressureRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BloodPressureRecord>> create(Ref ref) {
    final argument = this.argument as IntervalStoreManagerLocation;
    return bloodPressureRecords(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BloodPressureRecordsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bloodPressureRecordsHash() =>
    r'6cac81ceb85a3fd7f530cbd6859cd46e0a53ed0b';

final class BloodPressureRecordsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<BloodPressureRecord>>,
          IntervalStoreManagerLocation
        > {
  BloodPressureRecordsFamily._()
    : super(
        retry: null,
        name: r'bloodPressureRecordsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BloodPressureRecordsProvider call(IntervalStoreManagerLocation location) =>
      BloodPressureRecordsProvider._(argument: location, from: this);

  @override
  String toString() => r'bloodPressureRecordsProvider';
}

@ProviderFor(notes)
final notesProvider = NotesFamily._();

final class NotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Note>>,
          List<Note>,
          Stream<List<Note>>
        >
    with $FutureModifier<List<Note>>, $StreamProvider<List<Note>> {
  NotesProvider._({
    required NotesFamily super.from,
    required IntervalStoreManagerLocation super.argument,
  }) : super(
         retry: null,
         name: r'notesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$notesHash();

  @override
  String toString() {
    return r'notesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Note>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Note>> create(Ref ref) {
    final argument = this.argument as IntervalStoreManagerLocation;
    return notes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NotesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$notesHash() => r'1dd1ad295fefe0c44eecd92759baad668334fb54';

final class NotesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<Note>>,
          IntervalStoreManagerLocation
        > {
  NotesFamily._()
    : super(
        retry: null,
        name: r'notesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NotesProvider call(IntervalStoreManagerLocation location) =>
      NotesProvider._(argument: location, from: this);

  @override
  String toString() => r'notesProvider';
}

@ProviderFor(medicineIntakes)
final medicineIntakesProvider = MedicineIntakesFamily._();

final class MedicineIntakesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MedicineIntake>>,
          List<MedicineIntake>,
          Stream<List<MedicineIntake>>
        >
    with
        $FutureModifier<List<MedicineIntake>>,
        $StreamProvider<List<MedicineIntake>> {
  MedicineIntakesProvider._({
    required MedicineIntakesFamily super.from,
    required IntervalStoreManagerLocation super.argument,
  }) : super(
         retry: null,
         name: r'medicineIntakesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$medicineIntakesHash();

  @override
  String toString() {
    return r'medicineIntakesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MedicineIntake>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MedicineIntake>> create(Ref ref) {
    final argument = this.argument as IntervalStoreManagerLocation;
    return medicineIntakes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MedicineIntakesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$medicineIntakesHash() => r'8a4206c4d652e3b17f81189f3e2451f51c400ef5';

final class MedicineIntakesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<MedicineIntake>>,
          IntervalStoreManagerLocation
        > {
  MedicineIntakesFamily._()
    : super(
        retry: null,
        name: r'medicineIntakesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MedicineIntakesProvider call(IntervalStoreManagerLocation location) =>
      MedicineIntakesProvider._(argument: location, from: this);

  @override
  String toString() => r'medicineIntakesProvider';
}

@ProviderFor(bodyweightRecords)
final bodyweightRecordsProvider = BodyweightRecordsFamily._();

final class BodyweightRecordsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BodyweightRecord>>,
          List<BodyweightRecord>,
          Stream<List<BodyweightRecord>>
        >
    with
        $FutureModifier<List<BodyweightRecord>>,
        $StreamProvider<List<BodyweightRecord>> {
  BodyweightRecordsProvider._({
    required BodyweightRecordsFamily super.from,
    required IntervalStoreManagerLocation super.argument,
  }) : super(
         retry: null,
         name: r'bodyweightRecordsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bodyweightRecordsHash();

  @override
  String toString() {
    return r'bodyweightRecordsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<BodyweightRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BodyweightRecord>> create(Ref ref) {
    final argument = this.argument as IntervalStoreManagerLocation;
    return bodyweightRecords(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BodyweightRecordsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bodyweightRecordsHash() => r'a84836f18e38f71c4161f261bdc456e7a9118922';

final class BodyweightRecordsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<BodyweightRecord>>,
          IntervalStoreManagerLocation
        > {
  BodyweightRecordsFamily._()
    : super(
        retry: null,
        name: r'bodyweightRecordsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BodyweightRecordsProvider call(IntervalStoreManagerLocation location) =>
      BodyweightRecordsProvider._(argument: location, from: this);

  @override
  String toString() => r'bodyweightRecordsProvider';
}

@ProviderFor(medicines)
final medicinesProvider = MedicinesProvider._();

final class MedicinesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Medicine>>,
          List<Medicine>,
          Stream<List<Medicine>>
        >
    with $FutureModifier<List<Medicine>>, $StreamProvider<List<Medicine>> {
  MedicinesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'medicinesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$medicinesHash();

  @$internal
  @override
  $StreamProviderElement<List<Medicine>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Medicine>> create(Ref ref) {
    return medicines(ref);
  }
}

String _$medicinesHash() => r'53921c0643310900a941a0f9be210e1ebc2e2e61';
