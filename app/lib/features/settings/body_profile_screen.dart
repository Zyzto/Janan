import 'package:blood_pressure_app/features/settings/tiles/dropdown_list_tile.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/model/body_sex.dart';
import 'package:blood_pressure_app/model/storage/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Height, age, sex, and athlete mode used for scale body composition.
class BodyProfileScreen extends StatelessWidget {
  /// Create a screen to edit the body-composition profile.
  const BodyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(localizations.bodyProfile)),
      body: ListView(
        children: [
          _NumberTile(
            icon: Icons.height,
            label: localizations.bodyHeightCm,
            value: settings.bodyHeightCm,
            onChanged: (value) => settings.bodyHeightCm = value,
          ),
          _NumberTile(
            icon: Icons.cake_outlined,
            label: localizations.birthYear,
            value: settings.birthYear?.toDouble(),
            integer: true,
            onChanged: (value) => settings.birthYear = value?.round(),
          ),
          DropDownListTile<BodySex?>(
            leading: const Icon(Icons.wc),
            title: Text(localizations.bodySex),
            value: settings.bodySex,
            items: [
              DropdownMenuItem(
                value: BodySex.female,
                child: Text(localizations.bodySexFemale),
              ),
              DropdownMenuItem(
                value: BodySex.male,
                child: Text(localizations.bodySexMale),
              ),
            ],
            onChanged: (value) {
              if (value != null) settings.bodySex = value;
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.directions_run),
            title: Text(localizations.athleteMode),
            subtitle: Text(localizations.athleteModeDesc),
            value: settings.athleteMode,
            onChanged: (value) => settings.athleteMode = value,
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
