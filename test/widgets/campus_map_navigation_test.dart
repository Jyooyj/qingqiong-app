import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/pages/map_page.dart';
import 'package:robot_cleaner/widgets/geo_map/campus_geo_preview_page.dart';
import 'package:robot_cleaner/widgets/geo_map/campus_geo_map_view.dart';
import 'package:robot_cleaner/services/product_session.dart';
import 'package:robot_cleaner/data/campus_geo/campus_buildings.dart';

void main() {
  testWidgets('geo page follows shared voice task and pause state', (
    tester,
  ) async {
    final session = ProductSession();
    final coordinator = session.campusCoordinator;
    try {
      await tester.pumpWidget(
        MaterialApp(home: CampusGeoPreviewPage(coordinator: coordinator)),
      );
      expect(session.voiceControlService.execute('去实验楼清扫').success, isTrue);
      await tester.pump();
      CampusGeoMapView map() => tester.widget(find.byType(CampusGeoMapView));
      expect(map().plannedPath, coordinator.geoPlannedPath);
      expect(map().robotPosition, coordinator.geoRobotPosition);
      await tester.pump(const Duration(seconds: 10));
      expect(map().robotPosition, coordinator.geoPlannedPath[1]);
      expect(map().cleanedPath, coordinator.geoCleanedPath);
      coordinator.pause();
      await tester.pump();
      final position = map().robotPosition;
      await tester.pump(const Duration(seconds: 2));
      expect(map().robotPosition, position);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    }
  });

  testWidgets('map page opens geographic map directly', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MapPage()));
    await tester.pump();
    expect(find.byType(CampusGeoPreviewPage), findsOneWidget);
    expect(find.byType(CampusGeoMapView), findsOneWidget);
    expect(find.text('查看校园地图'), findsNothing);
    expect(find.text('A区'), findsNothing);
    expect(find.text('演示位置前进一步'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('normal campus map keeps labels without calibration UI', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CampusGeoPreviewPage()));
    expect(find.byKey(const Key('poi-calibration-controls')), findsNothing);
    expect(find.byKey(const Key('poi-calibration-building')), findsNothing);
    expect(find.byKey(const Key('poi-calibration-result')), findsNothing);
    expect(find.text('隐藏现有建筑标签'), findsNothing);
    final map = tester.widget<CampusGeoMapView>(find.byType(CampusGeoMapView));
    expect(map.enableCoordinatePicker, isFalse);
    expect(map.onCoordinatePicked, isNull);
    expect(map.showCampusLabels, isTrue);
    expect(map.campusBuildings, same(CampusBuildings.all));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
