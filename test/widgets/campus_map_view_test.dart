import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/data/campus/campus_map_data.dart';
import 'package:robot_cleaner/models/campus/campus_point.dart';
import 'package:robot_cleaner/widgets/campus/campus_map_view.dart';

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
}
