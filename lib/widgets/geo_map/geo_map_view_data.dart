import 'package:latlong2/latlong.dart';

/// Presentation-only contracts. Convert engine latitude/longitude to LatLng.
/// These are not replacements for member 2's CampusGeo models.
class CampusGeoZoneView {
  const CampusGeoZoneView({
    required this.id,
    required this.name,
    required this.center,
    required this.polygon,
  });
  final String id, name;
  final LatLng center;
  final List<LatLng> polygon;
}

class CampusGeoMarkerView {
  const CampusGeoMarkerView({
    required this.id,
    required this.position,
    required this.label,
  });
  final String id, label;
  final LatLng position;
}

bool validGeoPoint(LatLng p) =>
    p.latitude.isFinite &&
    p.longitude.isFinite &&
    p.latitude >= -90 &&
    p.latitude <= 90 &&
    p.longitude >= -180 &&
    p.longitude <= 180;
