import 'campus_geo_point.dart';

class CampusGeoZone {
  final String id;
  final String name;
  final List<String> aliases;
  final CampusGeoPoint center;
  final List<CampusGeoPoint> polygon;

  const CampusGeoZone({
    required this.id,
    required this.name,
    required this.aliases,
    required this.center,
    required this.polygon,
  });

  bool matchesAlias(String text) {
    return aliases.any((alias) => text.contains(alias));
  }
}