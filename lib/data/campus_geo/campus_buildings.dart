import '../../models/campus_geo/campus_building.dart';

/// Trusted permanent labels for the current campus map extent.
/// Coordinates mirror the existing verified CampusGeoMapData points.
/// Add buildings (including displayOnly POIs) only after their real geographic
/// coordinates have a reliable source; never use presentation-only anchors.
class CampusBuildings {
  static const List<CampusBuilding> all = [
    CampusBuilding(
      id: 'lab_building',
      zoneId: 'lab_building',
      name: '实验楼',
      latitude: 30.883660,
      longitude: 121.891570,
      labelOffset: CampusLabelOffset(dy: -18),
    ),
    CampusBuilding(
      id: 'canteen_1',
      zoneId: 'canteen_1',
      name: '第一食堂',
      latitude: 30.883980,
      longitude: 121.892430,
      labelOffset: CampusLabelOffset(dx: 28, dy: -18),
    ),
    CampusBuilding(
      id: 'teaching_2',
      zoneId: 'teaching_2',
      name: '第二教学楼',
      latitude: 30.885200,
      longitude: 121.893501,
      labelOffset: CampusLabelOffset(dy: -18),
    ),
    CampusBuilding(
      id: 'teaching_1',
      zoneId: 'teaching_1',
      name: '第一教学楼',
      latitude: 30.884428,
      longitude: 121.894047,
      labelOffset: CampusLabelOffset(dx: 28, dy: 18),
    ),
    CampusBuilding(
      id: 'library',
      zoneId: 'library',
      name: '图书馆',
      latitude: 30.885826,
      longitude: 121.891878,
      labelOffset: CampusLabelOffset(dx: -28, dy: -18),
    ),
    CampusBuilding(
      id: 'dormitory',
      zoneId: 'dormitory',
      name: '学生宿舍',
      latitude: 30.881308,
      longitude: 121.892049,
      labelOffset: CampusLabelOffset(dy: 18),
    ),
    // Source: final-data-campus @ 0cca7d27. Geographic POIs only; no routes.
    CampusBuilding(
      id: 'canteen_2',
      zoneId: 'canteen_2',
      name: '第二餐厅',
      latitude: 30.882666,
      longitude: 121.891107,
      displayOnly: true,
    ),
    CampusBuilding(
      id: 'canteen_3',
      zoneId: 'canteen_3',
      name: '第三餐厅',
      latitude: 30.889386,
      longitude: 121.891885,
      displayOnly: true,
    ),
    CampusBuilding(
      id: 'teaching_3',
      zoneId: 'teaching_3',
      name: '第三教学楼',
      latitude: 30.885779,
      longitude: 121.894235,
      displayOnly: true,
    ),
    CampusBuilding(
      id: 'teaching_4',
      zoneId: 'teaching_4',
      name: '第四教学楼',
      latitude: 30.886403,
      longitude: 121.894931,
      displayOnly: true,
    ),

    // Coordinates verified from the POI calibration map.
    CampusBuilding(
      id: 'ain_college',
      zoneId: 'ain_college',
      name: '\u7231\u6069\u5b66\u9662',
      latitude: 30.888560,
      longitude: 121.893287,
      pendingCalibration: false,
    ),
    CampusBuilding(
      id: 'engineering_college',
      zoneId: 'engineering_college',
      name: '\u5de5\u7a0b\u5b66\u9662',
      latitude: 30.887970,
      longitude: 121.892293,
      pendingCalibration: false,
    ),
    CampusBuilding(
      id: 'information_college',
      zoneId: 'information_college',
      name: '\u4fe1\u606f\u5b66\u9662',
      latitude: 30.888320,
      longitude: 121.894264,
      pendingCalibration: false,
    ),
    CampusBuilding(
      id: 'food_college',
      zoneId: 'food_college',
      name: '\u98df\u54c1\u5b66\u9662',
      latitude: 30.887495,
      longitude: 121.891124,
      pendingCalibration: false,
    ),
    CampusBuilding(
      id: 'ocean_college',
      zoneId: 'ocean_college',
      name: '\u6d77\u6d0b\u5b66\u9662',
      latitude: 30.887474,
      longitude: 121.892207,
      pendingCalibration: false,
    ),
    CampusBuilding(
      id: 'fisheries_life_college',
      zoneId: 'fisheries_life_college',
      name: '\u6c34\u4ea7\u4e0e\u751f\u547d\u5b66\u9662',
      latitude: 30.887360,
      longitude: 121.890232,
      pendingCalibration: false,
    ),
  ];
}
