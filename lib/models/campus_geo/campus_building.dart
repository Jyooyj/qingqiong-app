/// A permanent campus wayfinding label, independent from task zones.
class CampusBuilding {
  const CampusBuilding({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.labelOffset = const CampusLabelOffset(),
    this.zoneId,
    this.displayOnly = false,
    this.pendingCalibration = false,
  });

  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final CampusLabelOffset labelOffset;

  /// Links a label to a task zone when one exists, without making the label
  /// dependent on that zone's lifecycle.
  final String? zoneId;

  /// A display-only label has no task target, route, or navigation meaning.
  final bool displayOnly;

  /// True when a display-only POI still needs a verified map coordinate.
  final bool pendingCalibration;
}

class CampusLabelOffset {
  const CampusLabelOffset({this.dx = 0, this.dy = 0});

  final double dx;
  final double dy;
}
