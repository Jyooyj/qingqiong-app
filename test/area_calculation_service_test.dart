import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:robot_cleaner/services/area_calculation_service.dart';

void main() {
  const service = AreaCalculationService();
  const square = [
    LatLng(0, 0),
    LatLng(0, .001),
    LatLng(.001, .001),
    LatLng(.001, 0),
  ];

  test('spherical equatorial rectangle returns square metres', () {
    expect(service.calculate(square), closeTo(12364.3458675, .001));
    expect(
      service.calculate(square.reversed.toList()),
      closeTo(service.calculate(square), .00001),
    );
    expect(
      service.calculate([...square, square.first]),
      closeTo(service.calculate(square), .00001),
    );
    expect(
      service.calculate(square.take(3).toList()),
      closeTo(service.calculate(square) / 2, .00001),
    );
  });

  test('missing, invalid and degenerate geometry has no invented area', () {
    expect(service.calculate([]), 0);
    expect(service.calculate(square.take(2).toList()), 0);
    expect(
      service.calculate(const [LatLng(0, 0), LatLng(0, 1), LatLng(0, 2)]),
      0,
    );
    expect(service.calculate([LatLng(double.nan, 0), ...square]), 0);
  });

  test('date-line crossing uses the shorter longitude span', () {
    final crossing = [
      LatLng(0, 179.9995),
      LatLng(0, -179.9995),
      LatLng(.001, -179.9995),
      LatLng(.001, 179.9995),
    ];
    expect(
      service.calculate(crossing),
      closeTo(service.calculate(square), .001),
    );
  });

  test(
    'route extent is independent of traversal order and interior points',
    () {
      final route = [
        square[0],
        square[2],
        const LatLng(.0005, .0005),
        square[1],
        square[3],
        square[0],
      ];
      expect(
        service.routeCoverage(route),
        closeTo(service.calculate(square), .001),
      );
      expect(
        service.routeCoverage(const [LatLng(0, 0), LatLng(0, 1), LatLng(0, 2)]),
        0,
      );
    },
  );
}
