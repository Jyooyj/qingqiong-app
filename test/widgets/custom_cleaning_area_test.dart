import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/services/product_session.dart';
import 'package:robot_cleaner/widgets/campus/cleaning_area_sheet.dart';
import 'package:robot_cleaner/models/campus_geo/campus_geo_point.dart';
import 'package:robot_cleaner/models/campus_geo/custom_cleaning_area.dart';
import 'package:robot_cleaner/data/campus_geo/campus_geo_map_data.dart';

class _Tiles extends TileProvider {
  @override
  ImageProvider getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) => MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAE0lEQVR4nGN8/eEZAwMDEwMYAAAhOwLFiRReMAAAAABJRU5ErkJggg==',
    ),
  );
}

void main() {
  test('invalid polygons cannot be saved', () {
    const a = CampusGeoPoint(latitude: 30.88, longitude: 121.89);
    const b = CampusGeoPoint(latitude: 30.881, longitude: 121.891);
    const c = CampusGeoPoint(latitude: 30.882, longitude: 121.892);
    for (final points in <List<CampusGeoPoint>>[
      [],
      [a, b],
      [a, b, a],
      [a, b, c],
    ]) {
      expect(
        () => CustomCleaningArea(
          id: 'test',
          name: '道路',
          type: CustomAreaType.road,
          polygon: points,
          createdAt: DateTime(2026),
        ),
        throwsArgumentError,
      );
    }
  });

  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    testWidgets('create, select and reopen custom area at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = ProductSession();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  builder: (_) => CleaningAreaSheet(
                    session: session,
                    tileProviderFactory: () => _Tiles(),
                  ),
                ),
                child: const Text('更多区域'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('更多区域'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('new-custom-area')));
      await tester.pumpAndSettle();
      expect(find.text('新建自定义区域'), findsOneWidget);
      await tester.tap(find.byKey(const Key('save-custom-area')));
      await tester.pump();
      expect(find.text('请输入区域名称'), findsOneWidget);
      expect(session.customCleaningAreas.areas, isEmpty);
      await tester.enterText(
        find.byKey(const Key('custom-area-name')),
        '校园东侧道路',
      );
      // Keyboard insets must not hide the form's scrollable actions.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.ensureVisible(find.byKey(const Key('pick-custom-range')));
      await tester.tap(find.byKey(const Key('pick-custom-range')));
      await tester.pumpAndSettle();
      final mapFinder = find.byKey(const Key('custom-area-map'));
      expect(mapFinder, findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('confirm-custom-range')))
            .onPressed,
        isNull,
      );
      final rect = tester.getRect(mapFinder);
      final clicks = [
        rect.center + const Offset(-60, -60),
        rect.center + const Offset(60, -60),
        rect.center + const Offset(0, 60),
      ];
      final expected = <CampusGeoPoint>[];
      for (final click in clicks) {
        final element = tester.element(find.byType(TileLayer));
        final point = MapCamera.of(
          element,
        ).screenOffsetToLatLng(click - rect.topLeft);
        expected.add(
          CampusGeoPoint(latitude: point.latitude, longitude: point.longitude),
        );
        await tester.tapAt(click);
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
      }
      expect(
        find.byWidgetPredicate((widget) => widget is PolygonLayer),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('confirm-custom-range')));
      await tester.pumpAndSettle();
      expect(find.text('已选择 3 个边界点'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('save-custom-area')));
      await tester.tap(find.byKey(const Key('save-custom-area')));
      await tester.pumpAndSettle();
      final area = session.customCleaningAreas.areas.single;
      expect(area.name, '校园东侧道路');
      expect(area.polygon, expected);
      expect(area.isCustom, isTrue);
      expect(area.generatedRoute.plannedPath.length, 4);
      expect(
        area.generatedRoute.plannedPath.first,
        area.generatedRoute.plannedPath.last,
      );
      expect(CampusGeoMapData.routeForZone(area.id), isNull);
      final row = find.byKey(Key('custom-area-${area.id}'));
      expect(row, findsOneWidget);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.textContaining('尚未配置清扫路线'), findsNothing);
      expect(find.byKey(Key('run-custom-area-${area.id}')), findsOneWidget);
      expect(session.taskController.tasks, isEmpty);
      await tester.tap(find.byKey(Key('run-custom-area-${area.id}')));
      await tester.pumpAndSettle();
      expect(session.currentTask!.campusZoneId, area.id);
      final start = session.campusCoordinator.geoRobotPosition;
      await tester.pump(const Duration(seconds: 10));
      expect(session.campusCoordinator.geoRobotPosition, isNot(start));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    });
  }
}
