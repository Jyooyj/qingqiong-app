class CampusPoint {
  final double x;
  final double y;

  const CampusPoint({
    required this.x,
    required this.y,
  });

  bool get isValid =>
      x >= 0.0 &&
      x <= 1.0 &&
      y >= 0.0 &&
      y <= 1.0;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CampusPoint &&
            runtimeType == other.runtimeType &&
            x == other.x &&
            y == other.y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}
