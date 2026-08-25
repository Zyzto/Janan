import 'package:blood_pressure_app/app.dart';
import 'package:blood_pressure_app/config.dart';
import 'package:blood_pressure_app/data_util/combined_entry_builder.dart';
import 'package:blood_pressure_app/features/data_picker/interval_picker.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/ble_launch_sync_host.dart';
import 'package:blood_pressure_app/features/home/ble_home_sync_indicator.dart';
import 'package:blood_pressure_app/features/home/navigation_action_buttons.dart';
import 'package:blood_pressure_app/features/measurement_list/compact_measurement_list.dart';
import 'package:blood_pressure_app/features/measurement_list/measurement_list.dart';
import 'package:blood_pressure_app/features/measurement_list/weight_list.dart';
import 'package:blood_pressure_app/features/statistics/value_graph.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/logging.dart';
import 'package:blood_pressure_app/model/storage/interval_store_manager.dart';
import 'package:blood_pressure_app/model/storage/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Central screen of the app with graph and measurement list that is the center
/// of navigation.
class AppHome extends StatelessWidget with TypeLogger {
  /// Create a home screen.
  const AppHome({super.key});

  PreferredSizeWidget _buildAppBar(BuildContext context, {bool showWeightTabs = false}) {
    final localizations = AppLocalizations.of(context)!;
    return AppBar(
      leadingWidth: 104,
      leading: Row(
        children: [
          IconButton(
            tooltip: localizations.settings,
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed(AppRoute.settings.path),
          ),
          IconButton(
            tooltip: localizations.statistics,
            icon: const Icon(Icons.insights),
            onPressed: () => Navigator.of(context).pushNamed(AppRoute.statistics.path),
          ),
        ],
      ),
      title: Text(localizations.title),
      actions: const [BleHomeSyncIndicator()],
      bottom: showWeightTabs
          ? const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.monitor_heart)),
                Tab(icon: Icon(Icons.scale)),
              ],
            )
          : null,
    );
  }

  Widget _buildValueGraph(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: SizedBox(
          height: 240.0,
          width: MediaQuery.of(context).size.width,
          child: CombinedEntryBuilder(
            rangeType: IntervalStoreManagerLocation.mainPage,
            onData: (context, records, intakes, notes) => BloodPressureValueGraph(
              records: records,
              colors: notes,
              intakes: intakes,
            ),
          ),
        ),
      ),
      IntervalPicker(type: IntervalStoreManagerLocation.mainPage),
    ],
  );

  Widget _buildMeasurementList(BuildContext context) => CombinedEntryBuilder(
    rangeType: IntervalStoreManagerLocation.mainPage,
    onEntries: (context, entries) => Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: (context.select<Settings, bool>((s) => s.compactList))
        ? CompactMeasurementList(data: entries)
        : MeasurementList(entries: entries),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final weightInput = context.select<Settings, bool>((s) => s.weightInput);
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        if (showValueGraphAsHomeScreenInLandscapeMode && orientation == Orientation.landscape) {
          return Scaffold(
            appBar: _buildAppBar(context),
            body: SafeArea(
              top: false,
              child: BleLaunchSyncPopout(
                child: _buildValueGraph(context),
              ),
            ),
          );
        }
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: _buildAppBar(context, showWeightTabs: weightInput),
            body: SafeArea(
              top: false,
              child: BleLaunchSyncPopout(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildValueGraph(context),),
                    if (!weightInput)
                      SliverFillRemaining(child: _buildMeasurementList(context)),
                    if (weightInput)
                      SliverFillRemaining(
                        child: TabBarView(
                          children: [
                            _buildMeasurementList(context),
                            const WeightList(rangeType: IntervalStoreManagerLocation.mainPage),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            floatingActionButton: const NavigationActionButtons(),
          ),
        );
      },
    );
  }
}
