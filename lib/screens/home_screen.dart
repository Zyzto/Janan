import 'package:blood_pressure_app/config.dart';
import 'package:blood_pressure_app/data_util/combined_entry_builder.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/ble_launch_sync_host.dart';
import 'package:blood_pressure_app/features/home/home_bp_chart.dart';
import 'package:blood_pressure_app/features/measurement_list/measurement_list.dart';
import 'package:blood_pressure_app/features/statistics/dashboard/dashboard_empty_card.dart';
import 'package:blood_pressure_app/features/statistics/dashboard/dashboard_page_body.dart';
import 'package:blood_pressure_app/features/statistics/dashboard/dashboard_section.dart';
import 'package:blood_pressure_app/model/storage/interval_store_manager.dart';
import 'package:flutter/material.dart';

/// Central screen of the app with graph and measurement list.
class AppHome extends StatelessWidget {
  /// Create the blood-pressure home tab.
  const AppHome({super.key});

  Widget _graphCard() => const HomeBpChart();

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        if (showValueGraphAsHomeScreenInLandscapeMode && orientation == Orientation.landscape) {
          return Scaffold(
            primary: false,
            body: SafeArea(
              top: false,
              child: BleLaunchSyncPopout(
                child: DashboardPageBody(children: [_graphCard()]),
              ),
            ),
          );
        }
        return Scaffold(
          primary: false,
          body: SafeArea(
            top: false,
            child: BleLaunchSyncPopout(
              child: CombinedEntryBuilder(
                rangeType: IntervalStoreManagerLocation.mainPage,
                onEntries: (context, entries) => DashboardPageBody(
                  children: [
                    if (entries.isEmpty)
                      const DashboardEmptyCard()
                    else ...[
                      _graphCard(),
                      DashboardSection(
                        padding: EdgeInsets.zero,
                        child: MeasurementList(
                          entries: entries,
                          shrinkWrap: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
