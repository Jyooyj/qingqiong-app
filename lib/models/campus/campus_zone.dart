import 'campus_point.dart';

enum CampusZoneCategory {
  dining,
  teaching,
  laboratory,
  dormitory,
  library,
  road,
  publicArea,
}

class CampusZone {
  final String id;
  final String name;
  final List<String> aliases;
  final CampusPoint center;
  final List<CampusPoint> polygon;
  final CampusZoneCategory category;

  const CampusZone({
    required this.id,
    required this.name,
    required this.aliases,
    required this.center,
    required this.polygon,
    required this.category,
  });

  bool matchesAlias(String text) {
    return aliases.any((alias) => text.contains(alias));
  }
}