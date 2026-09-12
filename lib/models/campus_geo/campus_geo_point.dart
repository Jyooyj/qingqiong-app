class CampusGeoPoint {
  final double latitude;
  final double longitude;

  const CampusGeoPoint({required this.latitude, required this.longitude});

  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CampusGeoPoint &&
            runtimeType == other.runtimeType &&
            latitude == other.latitude &&
            longitude == other.longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
