import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/widgets/campus/current_task_map_card.dart';
import 'package:robot_cleaner/widgets/campus/campus_map_view.dart';
import 'package:robot_cleaner/data/campus/campus_map_data.dart';

void main() {
  testWidgets('task values render and callbacks do not mutate display state', (
    tester,
  ) async {
    var pauses = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CurrentTaskMapCard(
            data: const CampusTaskViewData(
              targetZoneName: '实验楼',
              status: CampusTaskStatus.running,
              progress: 42,
              cleanedArea: 12.5,
              elapsed: Duration(seconds: 90),
              battery: 80,
            ),
            onPause: () => pauses++,
          ),
        ),
      ),
    );
    expect(find.text('42%'), findsOneWidget);
    expect(find.text('12.5 m²'), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    await tester.tap(find.byKey(const Key('campus-pause')));
    await tester.pump();
    expect(pauses, 1);
    expect(find.text('清扫中'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('campus-resume')))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'unknown invalid values and emergency lock are not presented as valid',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CurrentTaskMapCard(
              data: CampusTaskViewData(
                status: CampusTaskStatus.emergency,
                progress: double.nan,
                battery: 110,
                cleanedArea: -1,
              ),
            ),
          ),
        ),
      );
      expect(find.text('—'), findsNWidgets(4));
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('急停锁定'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('campus-resume')))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('coincident robot and charger are both visible', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampusMapView(
            zones: CampusMapData.zones,
            robotPosition: CampusMapData.chargingStation.position,
            chargingStation: CampusMapData.chargingStation,
          ),
        ),
      ),
    );
    final robot = tester.getRect(find.byKey(const Key('campus-robot')));
    final charger = tester.getRect(find.byKey(const Key('campus-charger')));
    expect(robot.overlaps(charger), isFalse);
    expect(find.byKey(const Key('campus-shared-marker')), findsOneWidget);
  });

  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(430, 932),
    const Size(1366, 768),
  ]) {
    testWidgets('task controls fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CurrentTaskMapCard(
                data: CampusTaskViewData(
                  targetZoneName: '第二教学楼',
                  status: CampusTaskStatus.paused,
                  progress: 30,
                  battery: 70,
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
