import 'package:blood_pressure_app/features/bluetooth/backend/bluetooth_manager.dart';
import 'package:blood_pressure_app/features/bluetooth/bluetooth_input.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/bluetooth_cubit.dart';
import 'package:blood_pressure_app/features/input/forms/add_entry_form.dart';
import 'package:blood_pressure_app/features/input/forms/form_base.dart';
import 'package:blood_pressure_app/features/old_bluetooth/bluetooth_input.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/logging.dart';
import 'package:blood_pressure_app/model/bluetooth_input_mode.dart';
import 'package:blood_pressure_app/model/combined_entry.dart';
import 'package:blood_pressure_app/model/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:health_data_store/health_data_store.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Adds bluetooth functionality to [AddEntryForm] providing an interface to
/// manage multiple entries.
///
/// - Doesn't allow entering empty lists,
/// - Single element lists are the default case and work like [AddEntryForm],
/// - Multi element display a short list of entries and allow quickly removing
///   single entries.
class AddMultipleEntriesForm extends FormBase<List<CombinedEntry>> {
  const AddMultipleEntriesForm({super.key,
    super.initialValue,
    this.bluetoothCubit,
    this.mockBleInput,
  });

  /// Function to customize [BluetoothCubit] creation.
  ///
  /// Works on [BluetoothInputMode.newBluetoothInputCrossPlatform].
  @visibleForTesting
  final BluetoothCubit Function()? bluetoothCubit;

  /// A builder for a widget that can act as a bluetooth input.
  @visibleForTesting
  final Widget Function(void Function(List<BloodPressureRecord>))? mockBleInput;

  @override
  FormStateBase<List<CombinedEntry>, FormBase<List<CombinedEntry>>> createState() => AddMultipleEntriesFormState();

}

class AddMultipleEntriesFormState
    extends FormStateBase<List<CombinedEntry>, AddMultipleEntriesForm>
    with TypeLogger {
  /// Points to a form, when there is exactly 1 entry.
  final _singleEntryForm = GlobalKey<AddEntryFormState>();

  /// Initial entry of the form, may not always be up-to-date.
  CombinedEntry? _singleEntry;

  /// Non-null when there are more than 1 entries.
  List<CombinedEntry>? _multipleValues;

  void _setSingleEntry(CombinedEntry value) {
    setState(() {
      _multipleValues = null;
      _singleEntry = value;
    });
    _singleEntryForm.currentState?.fillForm(value);
  }

  void _setMultipleValues(List<CombinedEntry> value) {
    assert(value.isNotEmpty);
    if (value.length == 1) return _setSingleEntry(value.first);
    setState(() {
      _multipleValues = value;
      _singleEntry = null;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.length == 1) {
      _multipleValues = null;
      _singleEntry = widget.initialValue!.first;
    } else if (widget.initialValue != null && widget.initialValue!.length > 1) {
      _multipleValues = widget.initialValue?.toList();
      _singleEntry = null;
    }
  }

  @override
  void fillForm(List<CombinedEntry>? value) {
    if (value == null || value.isEmpty) {
      setState(() {
        _multipleValues = null;
        _singleEntry = null;
      });
      _singleEntryForm.currentState?.fillForm(null);
    } else {
      _setMultipleValues(value);
    }
  }

  @override
  bool get isEmpty => (_multipleValues != null && _multipleValues!.length > 1)
            || (_singleEntryForm.currentState?.isEmpty ?? true);

  @override
  bool get isDirty {
    if (_multipleValues != null && _multipleValues!.length > 1) {
      final initial = widget.initialValue;
      if (initial == null || initial.length != _multipleValues!.length) {
        return true;
      }
      for (var i = 0; i < initial.length; i++) {
        if (initial[i] != _multipleValues![i]) return true;
      }
      return false;
    }
    return _singleEntryForm.currentState?.isDirty ?? false;
  }

  @override
  bool isEmptyInputFocused() => false;

  @override
  List<CombinedEntry>? save() {
    if (_multipleValues case final List<CombinedEntry> values) {
      assert(values.length > 1);
      return values;
    }
    assert(_singleEntryForm.currentState != null);
    final value = _singleEntryForm.currentState?.save();
    if (value != null) return [value];
    return null;
  }

  @override
  bool validate() {
    assert(_multipleValues == null || _multipleValues!.length > 1);
    if (_multipleValues != null) return true;
    assert(_singleEntryForm.currentState != null);
    return _singleEntryForm.currentState?.validate() ?? true;
  }

  /// Gets called on inputs from a bluetooth device or similar. (multiple records)
  void _onExternalMeasurements(List<BloodPressureRecord> records) {
    if (records.isEmpty || !mounted) return;
    logger.finer('_onExternalMeasurements: importing ${records.length} records');
    if (records.length == 1) return _onExternalMeasurement(records.first);
    _setMultipleValues([
      for (final record in records)
        CombinedEntry(time: record.time, record: record),
    ]);
  }

  /// Gets called on single ble measurement.
  void _onExternalMeasurement(BloodPressureRecord record) {
    if (_singleEntryForm.currentState case final AddEntryFormState state) {
      state.onExternalMeasurement(record);
    } else {
      logger.warning("Received external measurement but couldn't fill form.");
    }
  }

  void _onExternalWeight(BodyweightRecord record) {
    if (_singleEntryForm.currentState case final AddEntryFormState state) {
      state.onExternalWeight(record);
    } else {
      logger.warning("Received external weight but couldn't fill form.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_multipleValues case final List<CombinedEntry> values) {
      assert(values.length > 1);
      final formatter = DateFormat(context.select((Settings s) => s.dateFormatString));
      return ListView.builder(
        itemCount: values.length,
        itemBuilder: (context, idx) => ListTile(
          title: Text(formatter.format(values[idx].time)),
          subtitle: Row(
            spacing: 6.0,
            children: [
              Text(values[idx].sys?.toString() ?? '-'),
              Text(values[idx].dia?.toString() ?? '-'),
              Text(values[idx].pul?.toString() ?? '-'),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              values.removeAt(idx);
              _setMultipleValues(values);
            },
          ),
        ),
      );
    }
    final bleInput = context.select((Settings s) => s.bleInput);
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      children: [
        if (widget.mockBleInput != null)
          widget.mockBleInput!.call(_onExternalMeasurements),
        switch (bleInput) {
          BluetoothInputMode.disabled => const SizedBox.shrink(),
          BluetoothInputMode.oldBluetoothInput => OldBluetoothInput(
            onMeasurement: _onExternalMeasurement,
          ),
          BluetoothInputMode.newBluetoothInputCrossPlatform => BluetoothInput(
            manager: BluetoothManager.create(),
            onMeasurement: _onExternalMeasurement,
            onAllMeasurements: _onExternalMeasurements,
            onWeight: _onExternalWeight,
            bluetoothCubit: widget.bluetoothCubit,
          ),
        },
        if (widget.mockBleInput != null || bleInput != BluetoothInputMode.disabled)
          const _OrEnterManually(),
        AddEntryForm(
          key: _singleEntryForm,
          initialValue: _singleEntry,
        ),
      ],
    );
  }

}

class _OrEnterManually extends StatelessWidget {
  const _OrEnterManually();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              AppLocalizations.of(context)!.orEnterManually,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
