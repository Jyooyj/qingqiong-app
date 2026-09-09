import '../../models/campus_geo/campus_geo_charging_station.dart';
import '../../models/campus_geo/campus_geo_point.dart';
import '../../models/campus_geo/campus_geo_route.dart';
import '../../models/campus_geo/campus_geo_zone.dart';

class CampusGeoMapData {
  static const List<CampusGeoZone> zones = [
    CampusGeoZone(
      id: 'lab_building',
      name: '实验楼',
      aliases: [
        '实验楼',
        '实验楼A',
        '公共实验楼A',
      ],
      center: CampusGeoPoint(
        latitude: 30.883660,
        longitude: 121.891570,
      ),
      polygon: [
        CampusGeoPoint(
          latitude: 30.883760,
          longitude: 121.891450,
        ),
        CampusGeoPoint(
          latitude: 30.883760,
          longitude: 121.891690,
        ),
        CampusGeoPoint(
          latitude: 30.883560,
          longitude: 121.891690,
        ),
        CampusGeoPoint(
          latitude: 30.883560,
          longitude: 121.891450,
        ),
      ],
    ),

    CampusGeoZone(
      id: 'canteen_1',
      name: '第一食堂',
      aliases: [
        '第一食堂',
        '一餐',
        '第一餐厅',
      ],
      center: CampusGeoPoint(
        latitude: 30.883980,
        longitude: 121.892430,
      ),
      polygon: [
        CampusGeoPoint(
          latitude: 30.884080,
          longitude: 121.892300,
        ),
        CampusGeoPoint(
          latitude: 30.884080,
          longitude: 121.892560,
        ),
        CampusGeoPoint(
          latitude: 30.883880,
          longitude: 121.892560,
        ),
        CampusGeoPoint(
          latitude: 30.883880,
          longitude: 121.892300,
        ),
      ],
    ),
        CampusGeoZone(
          id: 'canteen_2',
          name: '第二食堂',
          aliases: ['第二食堂', '二餐', '第二餐厅'],
          center: CampusGeoPoint(
          latitude: 30.884760,
          longitude: 121.894120,
    ),
    polygon: [],
),
        CampusGeoZone(
          id: 'teaching_3',
          name: '第三教学楼',
          aliases: ['第三教学楼', '三教'],
          center: CampusGeoPoint(
          latitude: 30.885860,
           longitude: 121.894180,
  ),
    polygon: [],
),
    CampusGeoZone(
      id: 'teaching_2',
      name: '第二教学楼',
      aliases: [
        '第二教学楼',
        '二教',
      ],
      center: CampusGeoPoint(
        latitude: 30.885420,
        longitude: 121.893520,
      ),
      polygon: [
        CampusGeoPoint(
          latitude: 30.885530,
          longitude: 121.893390,
        ),
        CampusGeoPoint(
          latitude: 30.885530,
          longitude: 121.893650,
        ),
        CampusGeoPoint(
          latitude: 30.885310,
          longitude: 121.893650,
        ),
        CampusGeoPoint(
          latitude: 30.885310,
          longitude: 121.893390,
        ),
      ],
    ),

    CampusGeoZone(
      id: 'dormitory',
      name: '学生宿舍',
      aliases: [
        '学生宿舍',
        '宿舍',
        '宿舍区',
      ],
      center: CampusGeoPoint(
        latitude: 30.882930,
        longitude: 121.893230,
      ),
      polygon: [
        CampusGeoPoint(
          latitude: 30.883100,
          longitude: 121.893020,
        ),
        CampusGeoPoint(
          latitude: 30.883100,
          longitude: 121.893440,
        ),
        CampusGeoPoint(
          latitude: 30.882760,
          longitude: 121.893440,
        ),
        CampusGeoPoint(
          latitude: 30.882760,
          longitude: 121.893020,
        ),
      ],
    ),
        CampusGeoZone(
          id: 'main_road',
          name: '校园主干道',
          aliases: ['校园主干道', '主干道', '校园道路'],
          center: CampusGeoPoint(
          latitude: 30.884500,
          longitude: 121.892900,
  ),
  polygon: [],
), 
    CampusGeoZone(
      id: 'library',
      name: '图书馆',
      aliases: [
        '图书馆',
        '海大图书馆',
        '上海海洋大学图书馆',
      ],
      center: CampusGeoPoint(
        latitude: 30.885707,
        longitude: 121.892017,
      ),
      polygon: [
        CampusGeoPoint(
          latitude: 30.885820,
          longitude: 121.891880,
        ),
        CampusGeoPoint(
          latitude: 30.885820,
          longitude: 121.892150,
        ),
        CampusGeoPoint(
          latitude: 30.885590,
          longitude: 121.892150,
        ),
        CampusGeoPoint(
          latitude: 30.885590,
          longitude: 121.891880,
        ),
      ],
    ),

    CampusGeoZone(
      id: 'teaching_1',
      name: '第一教学楼',
      aliases: [
        '第一教学楼',
        '一教',
      ],
      center: CampusGeoPoint(
        latitude: 30.884460,
        longitude: 121.893870,
      ),
      polygon: [],
    ),
  ];

static const List<CampusGeoRoute> routes = [
  CampusGeoRoute(
    zoneId: 'lab_building',
    plannedPath: [
      CampusGeoPoint(
        latitude: 30.884300,
        longitude: 121.892050,
      ),
      CampusGeoPoint(
        latitude: 30.884100,
        longitude: 121.891980,
      ),
      CampusGeoPoint(
        latitude: 30.883900,
        longitude: 121.891850,
      ),
      CampusGeoPoint(
        latitude: 30.883760,
        longitude: 121.891700,
      ),
      CampusGeoPoint(
        latitude: 30.883660,
        longitude: 121.891570,
      ),
    ],
  ),

  CampusGeoRoute(
    zoneId: 'canteen_1',
    plannedPath: [
      CampusGeoPoint(
        latitude: 30.884300,
        longitude: 121.892050,
      ),
      CampusGeoPoint(
        latitude: 30.884180,
        longitude: 121.892180,
      ),
      CampusGeoPoint(
        latitude: 30.884100,
        longitude: 121.892280,
      ),
      CampusGeoPoint(
        latitude: 30.884040,
        longitude: 121.892360,
      ),
      CampusGeoPoint(
        latitude: 30.883980,
        longitude: 121.892430,
      ),
    ],
  ),

  CampusGeoRoute(
    zoneId: 'teaching_2',
    plannedPath: [
      CampusGeoPoint(
        latitude: 30.884300,
        longitude: 121.892050,
      ),
      CampusGeoPoint(
        latitude: 30.884520,
        longitude: 121.892300,
      ),
      CampusGeoPoint(
        latitude: 30.884800,
        longitude: 121.892650,
      ),
      CampusGeoPoint(
        latitude: 30.885100,
        longitude: 121.893000,
      ),
      CampusGeoPoint(
        latitude: 30.885420,
        longitude: 121.893520,
      ),
    ],
  ),

  CampusGeoRoute(
    zoneId: 'dormitory',
    plannedPath: [
      CampusGeoPoint(
        latitude: 30.884300,
        longitude: 121.892050,
      ),
      CampusGeoPoint(
        latitude: 30.884050,
        longitude: 121.892300,
      ),
      CampusGeoPoint(
        latitude: 30.883700,
        longitude: 121.892650,
      ),
      CampusGeoPoint(
        latitude: 30.883300,
        longitude: 121.892950,
      ),
      CampusGeoPoint(
        latitude: 30.882930,
        longitude: 121.893230,
      ),
    ],
  ),
];

static const CampusGeoChargingStation chargingStation =
    CampusGeoChargingStation(
  id: 'charging_1',
  name: '校园充电点',
  position: CampusGeoPoint(
    latitude: 30.884300,
    longitude: 121.892050,
  ),
);

  static CampusGeoZone? findZoneById(String id) {
    for (final zone in zones) {
      if (zone.id == id) {
        return zone;
      }
    }
    return null;
  }

  static CampusGeoZone? findZoneByAlias(String text) {
    for (final zone in zones) {
      if (zone.name == text || zone.matchesAlias(text)) {
        return zone;
      }
    }
    return null;
  }

  static CampusGeoRoute? routeForZone(String zoneId) {
    for (final route in routes) {
      if (route.zoneId == zoneId) {
        return route;
      }
    }
    return null;
  }
}