import '../../models/campus_geo/campus_geo_point.dart';
import '../../models/campus_geo/campus_geo_route.dart';
import '../../models/campus_geo/campus_geo_zone.dart';
import 'campus_buildings.dart';

/// Demo boundaries around calibrated building anchors, not surveyed footprints.
class CampusCollegeData {
  static const ids = {
    'ain_college',
    'engineering_college',
    'information_college',
    'food_college',
    'ocean_college',
    'fisheries_life_college',
  };

  static final List<CampusGeoZone> zones = List.unmodifiable([
    for (final building in CampusBuildings.all.where((b) => ids.contains(b.id)))
      CampusGeoZone(
        id: building.id,
        name: building.name,
        aliases: [building.name],
        center: CampusGeoPoint(
          latitude: building.latitude!,
          longitude: building.longitude!,
        ),
        // Approximately 29 x 27 metres at this campus latitude.
        polygon: List.unmodifiable([
          for (final offset in [(-1, -1), (-1, 1), (1, 1), (1, -1)])
            CampusGeoPoint(
              latitude: building.latitude! + offset.$1 * 0.00012,
              longitude: building.longitude! + offset.$2 * 0.00015,
            ),
        ]),
        type: 'teaching',
        isTaskTarget: true,
      ),
  ]);

  static final List<CampusGeoRoute> routes = List.unmodifiable([
    for (final zone in zones)
      CampusGeoRoute(
        zoneId: zone.id,
        plannedPath: List.unmodifiable([...zone.polygon, zone.polygon.first]),
      ),
  ]);
}
