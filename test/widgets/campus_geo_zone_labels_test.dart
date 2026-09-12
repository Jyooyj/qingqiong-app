import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:robot_cleaner/data/campus_geo/campus_geo_map_data.dart';
import 'package:robot_cleaner/data/campus_geo/campus_buildings.dart';
import 'package:robot_cleaner/widgets/geo_map/campus_geo_map_view.dart';

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

List<CampusGeoZoneView> _zones() => CampusGeoMapData.zones
    .map(
      (zone) => CampusGeoZoneView(
        id: zone.id,
        name: zone.name,
        center: LatLng(zone.center.latitude, zone.center.longitude),
        polygon: zone.polygon
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList(),
      ),
    )
    .toList();

Future<void> _pumpMap(
  WidgetTester tester, {
  String? selectedZoneId,
  List<LatLng> plannedPath = const [],
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CampusGeoMapView(
          zones: _zones(),
          selectedZoneId: selectedZoneId,
          plannedPath: plannedPath,
          tileProviderFactory: () => _Tiles(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('overview renders every trusted campus zone label', (
    tester,
  ) async {
    await _pumpMap(tester);

    final markers = tester
        .widget<MarkerLayer>(find.byKey(const Key('geo-campus-label-layer')))
        .markers;
    final zoneMarkers = markers
        .where(
          (marker) =>
              marker.key?.toString().contains('geo-building-marker-') ?? false,
        )
        .toList();
    for (final marker in zoneMarkers) {
      expect((marker.child as Semantics).properties.selected, isFalse);
    }
    expect(
      zoneMarkers,
      hasLength(CampusBuildings.all.where((b) => b.latitude != null).length),
    );
    for (final building in CampusBuildings.all.where(
      (b) => b.latitude != null,
    )) {
      expect(find.text(building.name), findsOneWidget);
    }
    for (final name in ['体育馆', '体育场', '行政楼', '校医院', '校门']) {
      expect(find.text(name), findsNothing);
    }
  });

  testWidgets('selecting a zone keeps all other labels visible', (
    tester,
  ) async {
    await _pumpMap(tester, selectedZoneId: 'canteen_1');
    final markers = tester
        .widget<MarkerLayer>(find.byKey(const Key('geo-campus-label-layer')))
        .markers;
    final expectedBuildingIds = CampusBuildings.all
        .where((building) => building.latitude != null)
        .map((building) => building.id);
    expect(
      markers.map((marker) => marker.key),
      containsAll(
        expectedBuildingIds.map((id) => Key('geo-building-marker-$id')),
      ),
    );
    final selectedMarker = markers.singleWhere(
      (marker) => marker.key?.toString().contains('canteen_1') ?? false,
    );
    expect(selectedMarker.alignment, isNotNull);
    expect((selectedMarker.child as Semantics).properties.selected, isTrue);
    for (final marker in markers.where((m) => m != selectedMarker)) {
      expect((marker.child as Semantics).properties.selected, isFalse);
    }
    expect(
      CampusBuildings.all.any((building) => building.id == 'ain_college'),
      isTrue,
    );
  });

  testWidgets('active task overlays do not remove base zone labels', (
    tester,
  ) async {
    final route = CampusGeoMapData.routeForZone('lab_building')!.plannedPath;
    await _pumpMap(
      tester,
      selectedZoneId: 'lab_building',
      plannedPath: route
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList(),
    );
    expect(find.byType(PolylineLayer), findsOneWidget);
    final markers = tester
        .widget<MarkerLayer>(find.byKey(const Key('geo-campus-label-layer')))
        .markers;
    expect(
      markers.map((marker) => marker.key),
      unorderedEquals(
        CampusBuildings.all
            .where((b) => b.latitude != null)
            .map((building) => Key('geo-building-marker-${building.id}')),
      ),
    );
    // A focused task may put distant POIs outside the viewport. They remain
    // in the independent label layer and reappear when returning to overview.
    await tester.tap(find.byTooltip('回到校园'));
    await tester.pump();
    for (final building in CampusBuildings.all.where(
      (b) => b.latitude != null,
    )) {
      expect(find.text(building.name), findsOneWidget);
    }
  });

  testWidgets('warning overlays keep the permanent label layer visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampusGeoMapView(
            zones: _zones(),
            robotPosition: const LatLng(30.8843, 121.89205),
            obstacles: const [
              CampusGeoMarkerView(
                id: 'blocked',
                label: '路径阻塞',
                position: LatLng(30.8848, 121.8927),
              ),
            ],
            tileProviderFactory: () => _Tiles(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    for (final building in CampusBuildings.all.where(
      (b) => b.latitude != null,
    )) {
      expect(find.text(building.name), findsOneWidget);
    }
    expect(find.byKey(const Key('geo-obstacle-blocked')), findsOneWidget);
  });

  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    testWidgets('all labels fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pumpMap(tester);
      expect(tester.takeException(), isNull);
      final markers = tester
          .widget<MarkerLayer>(find.byKey(const Key('geo-campus-label-layer')))
          .markers;
      expect(
        markers.map((marker) => marker.key),
        containsAll(
          CampusBuildings.all
              .where((building) => building.latitude != null)
              .map((building) => Key('geo-building-marker-${building.id}')),
        ),
      );
    });
  }
}
