import 'package:latlong2/latlong.dart';
import 'geo_map_view_data.dart';

/// Synthetic UI fixtures near the campus overview, NOT calibrated POIs/routes.
/// Replace the entire fixture through the public view API after engine delivery.
class TemporaryGeoData {
  static const chargingStation = CampusGeoMarkerView(
    id: 'demo_charger',
    label: '临时充电点',
    position: LatLng(30.8825, 121.8900),
  );
  static final zones = [
    _zone('lab_building', '实验楼·测试', const LatLng(30.8856, 121.8934)),
    _zone('canteen_1', '一餐·测试', const LatLng(30.8828, 121.8917)),
    _zone('teaching_2', '二教·测试', const LatLng(30.8850, 121.8918)),
  ];
  static CampusGeoZoneView _zone(String id, String name, LatLng center) =>
      CampusGeoZoneView(
        id: id,
        name: name,
        center: center,
        polygon: [
          LatLng(center.latitude - .00025, center.longitude - .00035),
          LatLng(center.latitude - .00025, center.longitude + .00035),
          LatLng(center.latitude + .00025, center.longitude + .00035),
          LatLng(center.latitude + .00025, center.longitude - .00035),
        ],
      );
  static List<LatLng> route(CampusGeoZoneView zone) => [
    chargingStation.position,
    const LatLng(30.8833, 121.8906),
    const LatLng(30.8840, 121.8910),
    zone.center,
  ];
}
