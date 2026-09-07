import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/data/campus/campus_map_data.dart';
import 'package:robot_cleaner/models/campus/campus_point.dart';
import 'package:robot_cleaner/widgets/campus/campus_map_view.dart';
import 'package:robot_cleaner/widgets/campus/campus_demo_page.dart';
import 'package:robot_cleaner/pages/map_page.dart';

void main() {
  testWidgets('selection callback and external selection stay controlled', (
    tester,
  ) async {
    String? tapped;
    Future<void> show(String? selected) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampusMapView(
            zones: CampusMapData.zones,
            selectedZoneId: selected,
            onZoneTap: (id) => tapped = id,
          ),
        ),
      ),
    );
    await show(null);
    await tester.tap(find.byKey(const Key('campus-zone-lab_building')));
    expect(tapped, 'lab_building');
    expect(
      tester.widget<CampusMapView>(find.byType(CampusMapView)).selectedZoneId,
      isNull,
    );
    await show('canteen_1');
    final label = find.byKey(const Key('campus-zone-canteen_1'));
    final semantics = tester.widget<Semantics>(
      find.ancestor(of: label, matching: find.byType(Semantics)).first,
    );
    expect(semantics.properties.selected, isTrue);
  });

  testWidgets('external positions and paths update; idle map does not move', (
    tester,
  ) async {
    Future<void> show(CampusPoint point) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampusMapView(
            zones: CampusMapData.zones,
            robotPosition: point,
            plannedPath: CampusMapData.routeForZone('lab_building').plannedPath,
            cleanedPath: [CampusMapData.chargingStation.position, point],
            obstacles: CampusMapData.obstacles,
            chargingStation: CampusMapData.chargingStation,
          ),
        ),
      ),
    );
    await show(const CampusPoint(x: .2, y: .2));
    final before = tester.getTopLeft(find.byKey(const Key('campus-robot')));
    await show(const CampusPoint(x: .5, y: .5));
    final after = tester.getTopLeft(find.byKey(const Key('campus-robot')));
    expect(after.dx, greaterThan(before.dx));
    expect(after.dy, greaterThan(before.dy));
    await tester.pump(const Duration(seconds: 3));
    expect(tester.getTopLeft(find.byKey(const Key('campus-robot'))), after);
    expect(
      find.byKey(const Key('campus-obstacle-lab_obstacle_01')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('campus-charger')), findsOneWidget);
  });

  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(430, 932),
    const Size(1366, 768),
  ]) {
    testWidgets('campus preview fits $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: CampusDemoPage()));
      await tester.tap(find.byKey(const Key('campus-zone-lab_building')));
      await tester.pumpAndSettle();
      expect(find.text('当前目标：实验楼'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('existing map opens campus preview and returns', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MapPage()));
    await tester.tap(find.byKey(const Key('open-campus-map')));
    await tester.pumpAndSettle();
    expect(find.byType(CampusDemoPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open-campus-map')), findsOneWidget);
  });
}
