import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/widgets/map/cleaning_map_view.dart';
import 'package:robot_cleaner/widgets/map/map_view_data.dart';

void main() {
  testWidgets('CleaningMapView builds and shows zones labels', (tester) async {
    final zones = [
      MapZoneView(
        id: 'a',
        label: 'A区',
        points: const [
          MapPointView(x: 0, y: 0),
          MapPointView(x: 1, y: 0),
          MapPointView(x: 1, y: 1),
          MapPointView(x: 0, y: 1),
        ],
      ),
      MapZoneView(
        id: 'b',
        label: 'B区',
        points: const [
          MapPointView(x: 0, y: 0),
          MapPointView(x: 1, y: 0),
          MapPointView(x: 1, y: 1),
          MapPointView(x: 0, y: 1),
        ],
      ),
      MapZoneView(
        id: 'c',
        label: 'C区',
        points: const [
          MapPointView(x: 0, y: 0),
          MapPointView(x: 1, y: 0),
          MapPointView(x: 1, y: 1),
          MapPointView(x: 0, y: 1),
        ],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CleaningMapView(zones: zones)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('zone-label-a')), findsOneWidget);
    expect(find.byKey(const Key('zone-label-b')), findsOneWidget);
    expect(find.byKey(const Key('zone-label-c')), findsOneWidget);
  });

  testWidgets(
    'CleaningMapView builds with robot, charger, paths, obstacles and highlight',
    (tester) async {
      final robot = const MapPointView(x: 0.2, y: 0.3);
      final charger = const MapPointView(x: 0.1, y: 0.15);
      final planned = [
        const MapPointView(x: 0.2, y: 0.3),
        const MapPointView(x: 0.4, y: 0.5),
      ];
      final cleaned = [
        const MapPointView(x: 0.18, y: 0.28),
        const MapPointView(x: 0.35, y: 0.34),
      ];
      final obstacles = [
        MapObstacleView(
          position: const MapPointView(x: 0.5, y: 0.5),
          code: 'WARN-007',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CleaningMapView(
              zones: const [],
              robotPosition: robot,
              plannedPath: planned,
              cleanedPath: cleaned,
              obstacles: obstacles,
              chargingStation: charger,
              highlightedWarningCode: 'WARN-007',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // highlight marker and label should be present
      expect(
        find.byKey(const Key('obstacle-highlight-WARN-007')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('highlight-label-WARN-007')), findsOneWidget);
      // robot and charger overlay markers
      expect(find.byKey(const Key('robot-marker')), findsOneWidget);
      expect(find.byKey(const Key('charger-marker')), findsOneWidget);
    },
  );

  testWidgets(
    'CleaningMapView responsive sizes no overflow mobile and desktop',
    (tester) async {
      // mobile 360x800
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CleaningMapView(zones: [])),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // desktop 1366x768
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CleaningMapView(zones: [])),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Overlay widgets have finite coordinates and repaint on update', (
    tester,
  ) async {
    final zones = [
      MapZoneView(
        id: 'a',
        label: 'A区',
        points: const [
          MapPointView(x: 0, y: 0),
          MapPointView(x: 1, y: 0),
          MapPointView(x: 1, y: 1),
          MapPointView(x: 0, y: 1),
        ],
      ),
    ];
    final obstacles = [
      MapObstacleView(
        position: const MapPointView(x: 0.5, y: 0.5),
        code: 'WARN-007',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CleaningMapView(
            zones: zones,
            obstacles: obstacles,
            highlightedWarningCode: 'WARN-007',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // zone label position finite
    final zoneLabel = find.byKey(const Key('zone-label-a'));
    expect(zoneLabel, findsOneWidget);
    final zoneOffset = tester.getTopLeft(zoneLabel);
    expect(zoneOffset.dx.isFinite, isTrue);
    expect(zoneOffset.dy.isFinite, isTrue);

    // highlight marker position finite and within map bounds
    final highlight = find.byKey(const Key('obstacle-highlight-WARN-007'));
    expect(highlight, findsOneWidget);
    final hlOff = tester.getTopLeft(highlight);
    expect(hlOff.dx.isFinite, isTrue);
    expect(hlOff.dy.isFinite, isTrue);
    // get map size from CustomPaint
    final cpFinder = find.byType(CustomPaint).first;
    final mapSize = tester.getSize(cpFinder);
    expect(hlOff.dx >= 0 && hlOff.dx <= mapSize.width, isTrue);
    expect(hlOff.dy >= 0 && hlOff.dy <= mapSize.height, isTrue);

    // repaint on update: change robot position and cleaned path
    final robot1 = const MapPointView(x: 0.2, y: 0.2);
    final cleaned1 = [const MapPointView(x: 0.18, y: 0.18)];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CleaningMapView(
            zones: zones,
            obstacles: obstacles,
            highlightedWarningCode: 'WARN-007',
            robotPosition: robot1,
            cleanedPath: cleaned1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final robot2 = const MapPointView(x: 0.25, y: 0.25);
    final cleaned2 = [const MapPointView(x: 0.22, y: 0.22)];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CleaningMapView(
            zones: zones,
            obstacles: obstacles,
            highlightedWarningCode: 'WARN-007',
            robotPosition: robot2,
            cleanedPath: cleaned2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Planned/cleaned/robot semantics and legend items', (
    tester,
  ) async {
    final planned = [
      const MapPointView(x: 0.08, y: 0.12),
      const MapPointView(x: 0.42, y: 0.12),
      const MapPointView(x: 0.42, y: 0.18),
      const MapPointView(x: 0.08, y: 0.18),
      const MapPointView(x: 0.08, y: 0.24),
      const MapPointView(x: 0.42, y: 0.24),
      const MapPointView(x: 0.42, y: 0.30),
      const MapPointView(x: 0.08, y: 0.30),
    ];
    final cleaned = planned.sublist(0, planned.length ~/ 2);
    final robot = cleaned.last;
    final obstacles = [
      MapObstacleView(position: planned[cleaned.length], code: 'WARN-007'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CleaningMapView(
            zones: const [],
            plannedPath: planned,
            cleanedPath: cleaned,
            robotPosition: robot,
            obstacles: obstacles,
            highlightedWarningCode: 'WARN-007',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // cleanedPath is prefix of plannedPath
    expect(cleaned.length <= planned.length, isTrue);
    for (var i = 0; i < cleaned.length; i++) {
      expect(cleaned[i].x, planned[i].x);
      expect(cleaned[i].y, planned[i].y);
    }

    // robot marker corresponds to cleaned.last
    final robotMarker = find.byKey(const Key('robot-marker'));
    expect(robotMarker, findsOneWidget);

    // highlight label exists and within map
    expect(find.byKey(const Key('highlight-label-WARN-007')), findsOneWidget);
    final hl = tester.getTopLeft(
      find.byKey(const Key('obstacle-highlight-WARN-007')),
    );
    final cp = find.byType(CustomPaint).first;
    final mapSize = tester.getSize(cp);
    expect(hl.dx >= 0 && hl.dx <= mapSize.width, isTrue);
    expect(hl.dy >= 0 && hl.dy <= mapSize.height, isTrue);

    // legend items exist
    expect(find.byKey(const Key('legend-charger')), findsOneWidget);
    expect(find.byKey(const Key('legend-robot')), findsOneWidget);
    expect(find.byKey(const Key('legend-planned')), findsOneWidget);
    expect(find.byKey(const Key('legend-cleaned')), findsOneWidget);
    expect(find.byKey(const Key('legend-obstacle')), findsOneWidget);
    expect(find.byKey(const Key('legend-warn')), findsOneWidget);

    // legend should be outside the map canvas (not a descendant of the map CustomPaint)
    final mapFinder = find.byWidgetPredicate((w) {
      if (w is! CustomPaint) return false;
      final p = (w as CustomPaint).painter;
      return p != null &&
          p.runtimeType.toString().contains('CleaningMapPainter');
    }).first;
    final legendFinder = find.byKey(const Key('legend-charger'));
    expect(
      find.descendant(of: mapFinder, matching: legendFinder),
      findsNothing,
    );
  });
}
