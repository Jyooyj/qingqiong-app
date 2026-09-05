import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/adapters/location/demo_location_adapter.dart';
import 'package:robot_cleaner/data/campus/campus_map_data.dart';
import 'package:robot_cleaner/services/location/campus_location_service.dart';

void main() {
  group('CampusLocationService', () {
    test('loads planned path for experiment building', () {
      final adapter = DemoLocationAdapter(
        interval: const Duration(milliseconds: 20),
      );

      final service = CampusLocationService(
        locationAdapter: adapter,
      );

      service.loadZone('lab_building');

      expect(service.activeZoneId, 'lab_building');
      expect(service.currentState.plannedPath, isNotEmpty);
      expect(service.currentState.cleanedPath, isEmpty);
      expect(
        service.currentState.chargingStation,
        CampusMapData.chargingStation,
      );

      service.dispose();
    });

    test('robot position and cleanedPath update while running', () async {
      final adapter = DemoLocationAdapter(
        interval: const Duration(milliseconds: 20),
      );

      final service = CampusLocationService(
        locationAdapter: adapter,
      );

      service.loadZone('lab_building');

      final initialPosition = service.currentState.robotPosition;

      service.start();

      await Future<void>.delayed(
        const Duration(milliseconds: 70),
      );

      expect(
        service.currentState.robotPosition,
        isNot(initialPosition),
      );

      expect(
        service.currentState.cleanedPath,
        isNotEmpty,
      );

      service.dispose();
    });

    test('robot position and cleanedPath freeze while paused', () async {
      final adapter = DemoLocationAdapter(
        interval: const Duration(milliseconds: 20),
      );

      final service = CampusLocationService(
        locationAdapter: adapter,
      );

      service.loadZone('lab_building');
      service.start();

      await Future<void>.delayed(
        const Duration(milliseconds: 25),
      );

      service.pause();

      final pausedPosition =
          service.currentState.robotPosition;

      final cleanedPathLength =
          service.currentState.cleanedPath.length;

      await Future<void>.delayed(
        const Duration(milliseconds: 60),
      );

      expect(
        service.currentState.robotPosition,
        pausedPosition,
      );

      expect(
        service.currentState.cleanedPath.length,
        cleanedPathLength,
      );

      service.dispose();
    });

    test('robot continues and cleanedPath grows after resume', () async {
      final adapter = DemoLocationAdapter(
        interval: const Duration(milliseconds: 20),
      );

      final service = CampusLocationService(
        locationAdapter: adapter,
      );

      service.loadZone('lab_building');
      service.start();

      await Future<void>.delayed(
        const Duration(milliseconds: 25),
      );

      service.pause();

      final pausedPosition =
          service.currentState.robotPosition;

      final pausedCleanedPathLength =
          service.currentState.cleanedPath.length;

      await Future<void>.delayed(
        const Duration(milliseconds: 40),
      );

      service.resume();

      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );

      expect(
        service.currentState.robotPosition,
        isNot(pausedPosition),
      );

      expect(
        service.currentState.cleanedPath.length,
        greaterThan(pausedCleanedPathLength),
      );

      service.dispose();
    });
  });
}