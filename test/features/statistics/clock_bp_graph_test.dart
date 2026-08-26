import 'dart:math';

import 'package:blood_pressure_app/features/statistics/clock_bp_graph.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../model/blood_pressure_analyzer_test.dart';
import '../../util.dart';

void main() {
  testWidgets("doesn't throw when empty" , (tester) async {
    await pumpApp(tester, await materialApp(
      const ClockBpGraph(measurements: []),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(ClockBpGraph), findsOneWidget);
    expect(find.byType(RadarChart), findsOneWidget);
  });
  testWidgets('[gold] renders sample data like expected in light mode', (tester) async {
    final rng = Random(1234);
    await pumpApp(tester, await materialApp(
      ClockBpGraph(measurements: [
        for (int i = 0; i < 50; i++)
          mockRecord(
            time: DateTime.fromMillisecondsSinceEpoch(rng.nextInt(1724578014) * 1000),
            sys: rng.nextInt(60) + 70,
            dia: rng.nextInt(60) + 40,
            pul: rng.nextInt(70) + 40,
          )
      ],),
      settings: TestSettingsSeed(pulColor: Colors.pink),
    ), extraPumps: 0);
    await expectLater(find.byType(ClockBpGraph), myMatchesGoldenFile('ClockBpGraph-light.png'));
  }, tags: 'gold');
  testWidgets('[gold] renders sample data like expected in dark mode', (tester) async {
    final rng = Random(1234);
    await pumpApp(tester, await materialApp(
      Theme(
        data: ThemeData.dark(useMaterial3: true),
        child: ClockBpGraph(measurements: [
          for (int i = 0; i < 50; i++)
            mockRecord(
              time: DateTime.fromMillisecondsSinceEpoch(rng.nextInt(1724578014) * 1000),
              sys: rng.nextInt(60) + 70,
              dia: rng.nextInt(60) + 40,
              pul: rng.nextInt(70) + 40,
            )
        ],),
      ),
      settings: TestSettingsSeed(pulColor: Colors.pink),
    ), extraPumps: 0);
    await expectLater(find.byType(ClockBpGraph), myMatchesGoldenFile('ClockBpGraph-dark.png'));
  }, tags: 'gold');
}
