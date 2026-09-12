import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:robot_cleaner/widgets/geo_map/campus_geo_map_view.dart';
import 'package:robot_cleaner/widgets/geo_map/campus_geo_map_fallback.dart';
import 'package:robot_cleaner/models/campus_geo/campus_building.dart';

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

const center = CampusGeoMapView.campusCenter;
final zone = CampusGeoZoneView(
  id: 'lab_building',
  name: '实验楼',
  center: center,
  polygon: [
    LatLng(center.latitude - .001, center.longitude - .001),
    LatLng(center.latitude - .001, center.longitude + .001),
    LatLng(center.latitude + .001, center.longitude + .001),
    LatLng(center.latitude + .001, center.longitude - .001),
  ],
);

Widget host({
  String? selected,
  LatLng? robot,
  ValueChanged<String>? tap,
  bool picker = false,
  ValueChanged<LatLng>? pick,
  bool overlays = true,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: CampusGeoMapView(
        zones: [zone],
        // This fixture tests a synthetic polygon, independent of live POIs.
        campusBuildings: [
          CampusBuilding(
            id: zone.id,
            zoneId: zone.id,
            name: zone.name,
            latitude: center.latitude,
            longitude: center.longitude,
          ),
        ],
        selectedZoneId: selected,
        robotPosition: robot,
        plannedPath: overlays
            ? [center, LatLng(center.latitude + .002, center.longitude)]
            : [],
        cleanedPath: overlays
            ? [center, LatLng(center.latitude + .001, center.longitude)]
            : [],
        obstacles: overlays
            ? [
                const CampusGeoMarkerView(
                  id: 'a',
                  position: center,
                  label: '障碍',
                ),
              ]
            : [],
        chargingStation: overlays
            ? CampusGeoMarkerView(
                id: 'c',
                position: LatLng(center.latitude - .002, center.longitude),
                label: '充电',
              )
            : null,
        onZoneTap: tap,
        enableCoordinatePicker: picker,
        onCoordinatePicked: pick,
        tileProviderFactory: () => _Tiles(),
      ),
    ),
  ),
);

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  testWidgets(
    'center-only zone remains selectable without an invented polygon',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampusGeoMapView(
              zones: [
                CampusGeoZoneView(
                  id: 'teaching_1',
                  name: '第一教学楼',
                  center: center,
                  polygon: const [],
                ),
              ],
              campusBuildings: const [],
              onZoneTap: (id) => selected = id,
              tileProviderFactory: () => _Tiles(),
            ),
          ),
        ),
      );
      await settle(tester);
      expect(
        tester
            .widget<PolygonLayer<String>>(find.byType(PolygonLayer<String>))
            .polygons,
        isEmpty,
      );
      await tester.tap(find.byKey(const Key('geo-zone-teaching_1')));
      expect(selected, 'teaching_1');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('layers are controlled and polygon tap returns only the id', (
    tester,
  ) async {
    String? tapped;
    await tester.pumpWidget(host(tap: (id) => tapped = id));
    await settle(tester);
    final layer = tester.widget<PolygonLayer<String>>(
      find.byType(PolygonLayer<String>),
    );
    expect(layer.polygons.single.hitValue, 'lab_building');
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final local = map.mapController!.camera.latLngToScreenOffset(
      LatLng(center.latitude + .0007, center.longitude + .0007),
    );
    await tester.tapAt(tester.getTopLeft(find.byType(FlutterMap)) + local);
    await settle(tester);
    expect(tapped, 'lab_building');
    expect(
      tester
          .widget<CampusGeoMapView>(find.byType(CampusGeoMapView))
          .selectedZoneId,
      isNull,
    );
    await tester.pumpWidget(host(selected: 'lab_building'));
    await settle(tester);
    expect(
      tester
          .widget<PolygonLayer<String>>(find.byType(PolygonLayer<String>))
          .polygons
          .single
          .borderStrokeWidth,
      3,
    );
    expect(
      tester.widget<PolylineLayer>(find.byType(PolylineLayer)).polylines.length,
      2,
    );
  });

  testWidgets('moving robot updates marker without recentering the camera', (
    tester,
  ) async {
    await tester.pumpWidget(host(selected: 'lab_building', robot: center));
    await settle(tester);
    final controller = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!;
    final offsetCenter = LatLng(center.latitude + .003, center.longitude);
    controller.move(offsetCenter, 16);
    await settle(tester);
    final moved = LatLng(center.latitude + .0003, center.longitude + .0003);
    await tester.pumpWidget(host(selected: 'lab_building', robot: moved));
    await settle(tester);
    expect(controller.camera.center, offsetCenter);
    expect(
      tester
          .widget<MarkerLayer>(
            find.byKey(const Key('geo-dynamic-marker-layer')),
          )
          .markers
          .last
          .point,
      moved,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(controller.camera.center, offsetCenter);
    await tester.pumpWidget(host(selected: 'lab_building', overlays: false));
    await settle(tester);
    expect(
      tester.widget<PolylineLayer>(find.byType(PolylineLayer)).polylines,
      isEmpty,
    );
    expect(find.byKey(const Key('geo-obstacle-a')), findsNothing);
  });

  testWidgets('zoom drag and coordinate picker work with clipboard', (
    tester,
  ) async {
    LatLng? picked;
    await tester.pumpWidget(
      host(picker: true, pick: (p) => picked = p, overlays: false),
    );
    await settle(tester);
    final controller = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!;
    final zoom = controller.camera.zoom;
    await tester.tap(find.byTooltip('放大'));
    await settle(tester);
    expect(controller.camera.zoom, greaterThan(zoom));
    final rect = tester.getRect(find.byType(FlutterMap));
    await tester.dragFrom(
      rect.center + const Offset(-100, 100),
      const Offset(60, 30),
    );
    await settle(tester);
    expect(controller.camera.center, isNot(center));
    await tester.tapAt(rect.topLeft + const Offset(70, 70));
    await settle(tester);
    expect(picked, isNotNull);
    Object? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') clipboard = call.arguments;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.ensureVisible(find.text('复制坐标'));
    await tester.tap(find.text('复制坐标'));
    await tester.pump();
    expect(clipboard, isNotNull);
    await tester.pumpWidget(host(picker: false));
    await settle(tester);
    expect(find.text('复制坐标'), findsNothing);
  });

  testWidgets('failure banner retains overlays and retry rebuilds tiles', (
    tester,
  ) async {
    await tester.pumpWidget(host(robot: center));
    await settle(tester);
    final tiles = tester.widget<TileLayer>(find.byType(TileLayer));
    final oldKey = tiles.key;
    // The callback is the public flutter_map transport failure boundary.
    final mapContext = tester.element(find.byType(FlutterMap));
    final tile = TileImage(
      vsync: tester,
      coordinates: const TileCoordinates(54957, 26851, 16),
      imageProvider: const AssetImage('unused'),
      onLoadComplete: (_) {},
      onLoadError: (_, _, _) {},
      errorImage: null,
      cancelLoading: Completer<void>(),
      tileDisplay: const TileDisplay.instantaneous(),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await settle(tester);
    tiles.errorTileCallback!(tile, Exception('offline'), StackTrace.current);
    await settle(tester);
    expect(mapContext.mounted, isTrue);
    expect(find.text('部分底图加载失败，已加载区域仍可使用。'), findsOneWidget);
    expect(find.byKey(const Key('geo-robot')), findsOneWidget);
    await tester.tap(find.text('重试底图'));
    await settle(tester);
    final newTiles = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(newTiles.key, isNot(oldKey));
    newTiles.errorTileCallback!(tile, Exception('offline'), StackTrace.current);
    await settle(tester);
    final controller = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!;
    controller.move(const LatLng(31.2, 121.5), 16);
    await settle(tester);
    expect(find.byType(CampusGeoMapFallback), findsNothing);
    tile.dispose();
  });

  testWidgets('robot and coincident obstacle remain separately visible', (
    tester,
  ) async {
    await tester.pumpWidget(host(robot: center));
    await settle(tester);
    final robot = tester.getRect(find.byKey(const Key('geo-robot')));
    final obstacle = tester.getRect(find.byKey(const Key('geo-obstacle-a')));
    expect(robot.overlaps(obstacle), isFalse);
  });

  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(430, 932),
    const Size(1366, 768),
  ]) {
    testWidgets('geo map fits $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(selected: 'lab_building', robot: center, picker: true),
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }
}
