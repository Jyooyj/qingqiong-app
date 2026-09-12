import '../../models/campus_geo/campus_geo_zone.dart';
import '../campus/campus_map_data.dart';
import 'campus_geo_map_data.dart';

enum CleaningAreaCategory {
  teaching('教学建筑'),
  dining('食堂'),
  dormitory('宿舍区'),
  road('道路'),
  publicArea('公共区域'),
  custom('自定义区域');

  const CleaningAreaCategory(this.label);
  final String label;

  static CleaningAreaCategory forZone(CampusGeoZone zone) =>
      switch (zone.type) {
        'laboratory' || 'teaching' => teaching,
        'canteen' => dining,
        'dormitory' => dormitory,
        'road' => road,
        'custom' => custom,
        _ => publicArea,
      };
}

/// Executable targets only; map POIs are deliberately not a data source.
/// Shortcut configuration is independent of the unbounded full catalog.
class CampusCleaningCatalog {
  static const shortcutIds = ['lab_building', 'canteen_1', 'teaching_2'];

  static List<CampusGeoZone> get areas => List.unmodifiable(
    CampusGeoMapData.zones.where(
      (zone) =>
          zone.isTaskTarget &&
          CampusMapData.findZoneById(zone.id) != null &&
          (CampusGeoMapData.routeForZone(zone.id)?.plannedPath.length ?? 0) >=
              2,
    ),
  );

  static List<CampusGeoZone> get shortcuts {
    final byId = {for (final zone in areas) zone.id: zone};
    return List.unmodifiable([
      for (final id in shortcutIds)
        if (byId[id] != null) byId[id]!,
    ]);
  }
}
