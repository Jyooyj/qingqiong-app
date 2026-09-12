import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/models/campus_geo/campus_geo_point.dart';
import 'package:robot_cleaner/models/cleaning_task.dart';
import 'package:robot_cleaner/services/task_statistics_service.dart';

void main() {
  const service = TaskStatisticsService();
  const triangle = [
    CampusGeoPoint(latitude: 0, longitude: 0),
    CampusGeoPoint(latitude: 0, longitude: .001),
    CampusGeoPoint(latitude: .001, longitude: .001),
  ];
  const square = [...triangle, CampusGeoPoint(latitude: .001, longitude: 0)];

  CleaningTask task({DateTime? start, DateTime? end}) => CleaningTask(
    id: 'any-id',
    name: 'test',
    area: 'A',
    mode: 'standard',
    campusZoneId: 'unknown',
    status: CleaningTaskStatus.completed,
    progress: 100,
    createdAt: DateTime(2026),
    startedAt: start,
    completedAt: end,
    cleanedArea: 999999,
    elapsed: const Duration(days: 10),
  );

  test('custom polygon wins, then zone polygon, then route extent', () {
    expect(
      service.areaFor(
        customPolygon: triangle,
        zonePolygon: square,
        route: square,
      ),
      closeTo(6182.172934, .001),
    );
    expect(
      service.areaFor(customPolygon: [], zonePolygon: square, route: triangle),
      closeTo(12364.3458675, .001),
    );
    expect(
      service.areaFor(zonePolygon: [], route: triangle),
      closeTo(6182.172934, .001),
    );
    expect(service.areaFor(), 0);
  });

  test(
    'only recorded timestamps define duration, regardless of old metrics or id',
    () {
      final start = DateTime.utc(2026, 9, 12, 23, 55);
      final end = start.add(const Duration(minutes: 14, seconds: 23));
      final metrics = service.forTask(
        task(start: start, end: end),
        customPolygon: triangle,
      );
      expect(metrics.duration, const Duration(minutes: 14, seconds: 23));
      expect(metrics.startedAt, start);
      expect(metrics.completedAt, end);
      expect(metrics.area, closeTo(6182.172934, .001));
      final renamed = service.forTask(
        task(start: start, end: end).copyWith(id: 'different-id'),
        customPolygon: triangle,
      );
      expect(renamed.duration, metrics.duration);
      expect(renamed.area, metrics.area);
    },
  );

  test(
    'missing timestamps and geometry never fall back to synthetic metrics',
    () {
      final metrics = service.forTask(task());
      expect(metrics.duration, Duration.zero);
      expect(metrics.startedAt, isNull);
      expect(metrics.completedAt, isNull);
      expect(metrics.area, 0);
      final start = DateTime(2026);
      expect(service.forTask(task(start: start)).duration, Duration.zero);
      expect(service.forTask(task(end: start)).duration, Duration.zero);
      expect(
        service
            .forTask(
              task(
                start: start,
                end: start.subtract(const Duration(seconds: 1)),
              ),
            )
            .duration,
        Duration.zero,
      );
    },
  );
}
