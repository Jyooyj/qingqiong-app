import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/data/campus_geo/campus_geo_map_data.dart';

void main() {
  test('每个校园区域都必须能获取对应路线', () {
    for (final zone in CampusGeoMapData.zones) {
      final route = CampusGeoMapData.routeForZone(zone.id);

      expect(route, isNotNull, reason: '${zone.id} should have a route');

      expect(
        route!.zoneId,
        zone.id,
        reason: '${zone.id} route zoneId should match',
      );

      expect(
        route.plannedPath,
        isNotEmpty,
        reason: '${zone.id} route should not be empty',
      );

      expect(
        route.plannedPath.first,
        CampusGeoMapData.chargingStation.position,
        reason: '${zone.id} route should start at charging station',
      );

      expect(
        route.plannedPath.last,
        zone.center,
        reason: '${zone.id} route should end at target zone center',
      );
    }
  });
}
