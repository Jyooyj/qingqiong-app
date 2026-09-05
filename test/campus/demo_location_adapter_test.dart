import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/adapters/location/demo_location_adapter.dart';
import 'package:robot_cleaner/models/campus/campus_point.dart';

void main() {
  group('DemoLocationAdapter', () {
    test('moves along planned path when started', () async {
      final adapter = DemoLocationAdapter(
        interval: const Duration(milliseconds: 20),
      );

      final positions = <CampusPoint>[];

      final subscription =
          adapter.watchRobotPosition().listen(positions.add);

      adapter.loadPath(const [
        CampusPoint(x: 0.1, y: 0.1),
        CampusPoint(x: 0.2, y: 0.2),
        CampusPoint(x: 0.3, y: 0.3),
      ]);

      adapter.start();

      await Future<void>.delayed(
        const Duration(milliseconds: 70),
      );

      expect(positions.length, greaterThanOrEqualTo(2));
      expect(
        adapter.currentPosition,
        const CampusPoint(x: 0.3, y: 0.3),
      );

      await subscription.cancel();
      adapter.dispose();
    });

    test('does not move while paused', () async {
      final adapter = DemoLocationAdapter(
        interval: const Duration(milliseconds: 20),
      );

      adapter.loadPath(const [
        CampusPoint(x: 0.1, y: 0.1),
        CampusPoint(x: 0.2, y: 0.2),
        CampusPoint(x: 0.3, y: 0.3),
        CampusPoint(x: 0.4, y: 0.4),
      ]);

      adapter.start();

      await Future<void>.delayed(
        const Duration(milliseconds: 25),
      );

      adapter.pause();

      final pausedPosition = adapter.currentPosition;

      await Future<void>.delayed(
        const Duration(milliseconds: 60),
      );

      expect(adapter.currentPosition, pausedPosition);

      adapter.dispose();
    });

    test('continues moving after resume', () async {
      final adapter = DemoLocationAdapter(
        interval: const Duration(milliseconds: 20),
      );

      adapter.loadPath(const [
        CampusPoint(x: 0.1, y: 0.1),
        CampusPoint(x: 0.2, y: 0.2),
        CampusPoint(x: 0.3, y: 0.3),
        CampusPoint(x: 0.4, y: 0.4),
      ]);

      adapter.start();

      await Future<void>.delayed(
        const Duration(milliseconds: 25),
      );

      adapter.pause();

      final pausedPosition = adapter.currentPosition;

      await Future<void>.delayed(
        const Duration(milliseconds: 40),
      );

      adapter.resume();

      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );

      expect(
        adapter.currentPosition,
        isNot(pausedPosition),
      );

      adapter.dispose();
    });
  });
}