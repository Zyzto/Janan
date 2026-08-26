import 'package:blood_pressure_app/features/settings/app_settings.dart';
import 'package:blood_pressure_app/features/settings/registry.dart';
import 'package:blood_pressure_app/features/settings/tiles/dropdown_list_tile.dart';
import 'package:blood_pressure_app/model/body_sex.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart';

/// Height, age, sex, and athlete mode used for scale body composition.
class BodyProfileScreen extends ConsumerWidget {
  /// Create a screen to edit the body-composition profile.
  const BodyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('bodyProfile'.tr())),
      body: ListView(
        children: [
          _NumberTile(
            icon: Icons.height,
            label: 'bodyHeightCm'.tr(),
            value: settings.bodyHeightCm,
            onChanged: (value) => ref.updateSetting(bodyHeightCmSetting, value ?? 0),
          ),
          _NumberTile(
            icon: Icons.cake_outlined,
            label: 'birthYear'.tr(),
            value: settings.birthYear?.toDouble(),
            integer: true,
            onChanged: (value) => ref.updateSetting(birthYearSetting, value?.round() ?? 0),
          ),
          DropDownListTile<BodySex?>(
            leading: const Icon(Icons.wc),
            title: Text('bodySex'.tr()),
            value: settings.bodySex,
            items: [
              DropdownMenuItem(
                value: BodySex.female,
                child: Text('bodySexFemale'.tr()),
              ),
              DropdownMenuItem(
                value: BodySex.male,
                child: Text('bodySexMale'.tr()),
              ),
            ],
            onChanged: (value) {
              if (value != null) ref.setBodySex(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.directions_run),
            title: Text('athleteMode'.tr()),
            subtitle: Text('athleteModeDesc'.tr()),
            value: settings.athleteMode,
            onChanged: (value) => ref.updateSetting(athleteModeSetting, value),
          ),
        ],
      ),
    );
  }
}

class _NumberTile extends StatefulWidget {
  const _NumberTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.integer = false,
  });

  final IconData icon;
  final String label;
  final double? value;
  final bool integer;
  final ValueChanged<double?> onChanged;

  @override
  State<_NumberTile> createState() => _NumberTileState();
}

class _NumberTileState extends State<_NumberTile> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value == null
          ? ''
          : widget.integer
              ? widget.value!.round().toString()
              : widget.value.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(widget.icon),
    title: TextField(
      controller: _controller,
      decoration: InputDecoration(labelText: widget.label),
      keyboardType: TextInputType.numberWithOptions(decimal: !widget.integer),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          widget.integer ? RegExp(r'[0-9]') : RegExp(r'[0-9,.]'),
        ),
      ],
      onChanged: (text) {
        if (text.isEmpty) {
          widget.onChanged(null);
          return;
        }
        widget.onChanged(double.tryParse(text.replaceAll(',', '.')));
      },
    ),
  );
}
