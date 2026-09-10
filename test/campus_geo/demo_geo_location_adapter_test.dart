import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/adapters/geo_location/demo_geo_location_adapter.dart';
import 'package:robot_cleaner/models/campus_geo/campus_geo_point.dart';
import 'package:robot_cleaner/data/campus_geo/campus_geo_map_data.dart';

void main() {
  testWidgets(
    'default campus route takes 40 seconds and pause preserves position',
    (tester) async {
      final adapter = DemoGeoLocationAdapter();
      final path = CampusGeoMapData.routeForZone('lab_building')!.plannedPath;
      try {
        adapter.loadPath(path);
        adapter.start();
        await tester.pump(const Duration(seconds: 9));
        expect(adapter.currentPosition, path.first);
        await tester.pump(const Duration(seconds: 1));
        expect(adapter.currentPosition, path[1]);
        adapter.pause();
        await tester.pump(const Duration(seconds: 20));
        expect(adapter.currentPosition, path[1]);
        adapter.resume();
        await tester.pump(const Duration(seconds: 29));
        expect(adapter.currentPosition, path[3]);
        await tester.pump(const Duration(seconds: 1));
        expect(adapter.currentPosition, path.last);
        await tester.pump(const Duration(seconds: 20));
        expect(adapter.currentPosition, path.last);
      } finally {
        adapter.dispose();
      }
    },
  );

  group('DemoGeoLocationAdapter', () {
    late DemoGeoLocationAdapter adapter;

    final testPath = [
      const CampusGeoPoint(latitude: 30.0, longitude: 120.0),
      const CampusGeoPoint(latitude: 30.1, longitude: 120.1),
      const CampusGeoPoint(latitude: 30.2, longitude: 120.2),
    ];

    setUp(() {
      adapter = DemoGeoLocationAdapter(
        stepInterval: const Duration(milliseconds: 20),
      );
      adapter.loadPath(testPath);
    });

    tearDown(() {
      adapter.dispose();
    });

    test('start advances robot position', () async {
      expect(adapter.currentPosition, testPath[0]);

      adapter.start();

      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(adapter.currentPosition, testPath[1]);
    });

    test('pause freezes robot position', () async {
      adapter.start();

      await Future<void>.delayed(const Duration(milliseconds: 30));

      adapter.pause();
      final pausedPosition = adapter.currentPosition;

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(adapter.currentPosition, pausedPosition);
    });

    test('resume continues robot movement', () async {
      adapter.start();

      await Future<void>.delayed(const Duration(milliseconds: 30));

      adapter.pause();
      final pausedPosition = adapter.currentPosition;

      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(adapter.currentPosition, pausedPosition);

      adapter.resume();

      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(adapter.currentPosition, testPath[2]);
    });

    test('reset returns to start and does not auto-run', () async {
      adapter.start();

      await Future<void>.delayed(const Duration(milliseconds: 30));

      adapter.reset();

      expect(adapter.currentPosition, testPath[0]);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(adapter.currentPosition, testPath[0]);
    });
  });
}
