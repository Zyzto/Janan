
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/bluetooth_cubit.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/closed_bluetooth_input.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/model/known_ble_device.dart';
import 'package:blood_pressure_app/model/storage/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../util.dart';

class MockBluetoothCubit extends MockCubit<BluetoothState>
    implements BluetoothCubit {
  @override
  Future<bool> enableBluetooth() async => true;
  @override
  Future<void> forceRefresh() async {}
}

void main() {
  testWidgets('should show states correctly', (WidgetTester tester) async {
    final states = StreamController<BluetoothState>.broadcast();

    final cubit = MockBluetoothCubit();
    whenListen(cubit, states.stream, initialState: BluetoothStateInitial());

    int startCount = 0;
    await tester.pumpWidget(materialApp(ClosedBluetoothInput(
      bluetoothCubit: cubit,
      onStarted: () {
        startCount++;
      }
    )));
    await tester.pumpAndSettle();

    expect(find.byType(SizedBox), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);

    states.sink.add(BluetoothStateUnfeasible());
    await tester.pump();
    expect(find.byType(SizedBox), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);

    states.sink.add(BluetoothStateUnauthorized());
    await tester.pump();
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(localizations.errBleNoPerms), findsOneWidget);
    expect(find.text(localizations.tapToGrantBlePermission), findsOneWidget);

    await tester.tap(find.byType(ClosedBluetoothInput));
    expect(startCount, 0);

    states.sink.add(BluetoothStateDisabled());
    await tester.pump();
    expect(find.text(localizations.bluetoothDisabled), findsOneWidget);
    expect(find.text(localizations.tapToEnableBluetooth), findsOneWidget);

    await tester.tap(find.byType(ClosedBluetoothInput));
    expect(startCount, 0);

    states.sink.add(BluetoothStateReady());
    await tester.pump();
    expect(find.text(localizations.bluetoothInput), findsOneWidget);
    expect(find.text(localizations.tapToConnect), findsOneWidget);
    expect(find.text(localizations.connect), findsOneWidget);

    await tester.tap(find.byType(ClosedBluetoothInput));
    expect(startCount, 1);
  });

  testWidgets('shows paired device name when ready', (WidgetTester tester) async {
    final cubit = MockBluetoothCubit();
    whenListen(cubit, const Stream<BluetoothState>.empty(),
        initialState: BluetoothStateReady());

    await tester.pumpWidget(materialApp(
      ClosedBluetoothInput(
        bluetoothCubit: cubit,
        onStarted: () {},
      ),
      settings: Settings(knownBleDev: const [
        KnownBleDevice(id: 'abc', name: 'X4 Smart'),
      ]),
    ));
    await tester.pumpAndSettle();

    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(localizations.readFromDevice('X4 Smart')), findsOneWidget);
    expect(find.text(localizations.tapToConnect), findsOneWidget);
    expect(find.text(localizations.bluetoothInput), findsNothing);
  });
}
