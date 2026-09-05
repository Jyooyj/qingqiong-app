import '../../models/campus/campus_map_objects.dart';
import '../../models/campus/campus_point.dart';
import '../../models/campus/campus_route.dart';
import '../../models/campus/campus_zone.dart';

class CampusMapData {
  static const zones = <CampusZone>[
    CampusZone(
      id: 'lab_building',
      name: '实验楼',
      aliases: [
        '实验楼',
        '实验大楼',
        '实验楼附近',
        '实验区',
      ],
      center: CampusPoint(x: 0.70, y: 0.30),
      polygon: [
        CampusPoint(x: 0.63, y: 0.23),
        CampusPoint(x: 0.77, y: 0.23),
        CampusPoint(x: 0.77, y: 0.37),
        CampusPoint(x: 0.63, y: 0.37),
      ],
      category: CampusZoneCategory.laboratory,
    ),
    CampusZone(
      id: 'canteen_1',
      name: '一餐',
      aliases: [
        '一餐',
        '第一食堂',
        '一食堂',
        '一餐附近',
      ],
      center: CampusPoint(x: 0.30, y: 0.65),
      polygon: [
        CampusPoint(x: 0.24, y: 0.58),
        CampusPoint(x: 0.36, y: 0.58),
        CampusPoint(x: 0.36, y: 0.72),
        CampusPoint(x: 0.24, y: 0.72),
      ],
      category: CampusZoneCategory.dining,
    ),
    CampusZone(
      id: 'canteen_2',
      name: '二餐',
      aliases: [
        '二餐',
        '第二食堂',
        '二食堂',
      ],
      center: CampusPoint(x: 0.43, y: 0.70),
      polygon: [
        CampusPoint(x: 0.38, y: 0.64),
        CampusPoint(x: 0.48, y: 0.64),
        CampusPoint(x: 0.48, y: 0.76),
        CampusPoint(x: 0.38, y: 0.76),
      ],
      category: CampusZoneCategory.dining,
    ),
    CampusZone(
      id: 'teaching_1',
      name: '第一教学楼',
      aliases: [
        '一教',
        '第一教学楼',
        '一号教学楼',
      ],
      center: CampusPoint(x: 0.40, y: 0.35),
      polygon: [
        CampusPoint(x: 0.34, y: 0.29),
        CampusPoint(x: 0.46, y: 0.29),
        CampusPoint(x: 0.46, y: 0.41),
        CampusPoint(x: 0.34, y: 0.41),
      ],
      category: CampusZoneCategory.teaching,
    ),
    CampusZone(
      id: 'teaching_2',
      name: '第二教学楼',
      aliases: [
        '二教',
        '第二教学楼',
        '二号教学楼',
      ],
      center: CampusPoint(x: 0.51, y: 0.35),
      polygon: [
        CampusPoint(x: 0.46, y: 0.29),
        CampusPoint(x: 0.57, y: 0.29),
        CampusPoint(x: 0.57, y: 0.41),
        CampusPoint(x: 0.46, y: 0.41),
      ],
      category: CampusZoneCategory.teaching,
    ),
    CampusZone(
      id: 'teaching_3',
      name: '第三教学楼',
      aliases: [
        '三教',
        '第三教学楼',
        '三号教学楼',
      ],
      center: CampusPoint(x: 0.61, y: 0.35),
      polygon: [
        CampusPoint(x: 0.56, y: 0.29),
        CampusPoint(x: 0.66, y: 0.29),
        CampusPoint(x: 0.66, y: 0.41),
        CampusPoint(x: 0.56, y: 0.41),
      ],
      category: CampusZoneCategory.teaching,
    ),
    CampusZone(
      id: 'dormitory',
      name: '学生宿舍',
      aliases: [
        '学生宿舍',
        '宿舍',
        '宿舍区',
        '学生宿舍区',
      ],
      center: CampusPoint(x: 0.23, y: 0.78),
      polygon: [
        CampusPoint(x: 0.14, y: 0.70),
        CampusPoint(x: 0.32, y: 0.70),
        CampusPoint(x: 0.32, y: 0.86),
        CampusPoint(x: 0.14, y: 0.86),
      ],
      category: CampusZoneCategory.dormitory,
    ),
    CampusZone(
      id: 'library',
      name: '图书馆',
      aliases: [
        '图书馆',
        '图书馆附近',
        '图书馆周边',
      ],
      center: CampusPoint(x: 0.52, y: 0.55),
      polygon: [
        CampusPoint(x: 0.46, y: 0.48),
        CampusPoint(x: 0.58, y: 0.48),
        CampusPoint(x: 0.58, y: 0.62),
        CampusPoint(x: 0.46, y: 0.62),
      ],
      category: CampusZoneCategory.library,
    ),
        CampusZone(
      id: 'main_road',
      name: '校园主干道',
      aliases: [
        '主干道',
        '校园主干道',
        '主路',
      ],
      center: CampusPoint(x: 0.50, y: 0.45),
      polygon: [
        CampusPoint(x: 0.15, y: 0.43),
        CampusPoint(x: 0.85, y: 0.43),
        CampusPoint(x: 0.85, y: 0.47),
        CampusPoint(x: 0.15, y: 0.47),
      ],
      category: CampusZoneCategory.road,
    ),
  ];

  static const chargingStation = CampusChargingStation(
    id: 'charging_station_01',
    name: '校园充电桩',
    position: CampusPoint(x: 0.10, y: 0.90),
  );

  static const obstacles = <CampusObstacle>[
    CampusObstacle(
      id: 'lab_obstacle_01',
      position: CampusPoint(x: 0.68, y: 0.34),
      zoneId: 'lab_building',
    ),
  ];

  static CampusZone? findZoneById(String zoneId) {
    for (final zone in zones) {
      if (zone.id == zoneId) {
        return zone;
      }
    }
    return null;
  }

 static CampusZone? findZoneByAlias(String text) {
  CampusZone? bestMatch;
  var bestAliasLength = -1;

  for (final zone in zones) {
    for (final alias in zone.aliases) {
      if (text.contains(alias) && alias.length > bestAliasLength) {
        bestMatch = zone;
        bestAliasLength = alias.length;
      }
    }
  }

  return bestMatch;
}

  static CampusRoute routeForZone(String zoneId) {
    switch (zoneId) {
      case 'lab_building':
        return const CampusRoute(
          zoneId: 'lab_building',
          plannedPath: [
            CampusPoint(x: 0.10, y: 0.90),
            CampusPoint(x: 0.20, y: 0.80),
            CampusPoint(x: 0.30, y: 0.70),
            CampusPoint(x: 0.40, y: 0.60),
            CampusPoint(x: 0.50, y: 0.50),
            CampusPoint(x: 0.58, y: 0.42),
            CampusPoint(x: 0.64, y: 0.36),
            CampusPoint(x: 0.70, y: 0.30),
          ],
        );

      case 'canteen_1':
        return const CampusRoute(
          zoneId: 'canteen_1',
          plannedPath: [
            CampusPoint(x: 0.10, y: 0.90),
            CampusPoint(x: 0.16, y: 0.84),
            CampusPoint(x: 0.22, y: 0.77),
            CampusPoint(x: 0.26, y: 0.71),
            CampusPoint(x: 0.30, y: 0.65),
          ],
        );

      case 'teaching_2':
        return const CampusRoute(
          zoneId: 'teaching_2',
          plannedPath: [
            CampusPoint(x: 0.10, y: 0.90),
            CampusPoint(x: 0.20, y: 0.76),
            CampusPoint(x: 0.30, y: 0.62),
            CampusPoint(x: 0.40, y: 0.48),
            CampusPoint(x: 0.51, y: 0.35),
          ],
        );

      case 'dormitory':
        return const CampusRoute(
          zoneId: 'dormitory',
          plannedPath: [
            CampusPoint(x: 0.10, y: 0.90),
            CampusPoint(x: 0.15, y: 0.86),
            CampusPoint(x: 0.19, y: 0.82),
            CampusPoint(x: 0.23, y: 0.78),
          ],
        );

      default:
        final zone = findZoneById(zoneId);

        return CampusRoute(
          zoneId: zoneId,
          plannedPath: zone == null
              ? const [CampusPoint(x: 0.10, y: 0.90)]
              : [
                  chargingStation.position,
                  zone.center,
                ],
        );
    }
  }
}