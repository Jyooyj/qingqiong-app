import 'package:flutter/material.dart';

/// UI-only normalized map point (coordinates in 0..1)
class MapPointView {
  const MapPointView({required this.x, required this.y, this.label});

  final double x;
  final double y;
  final String? label;

  Offset toOffset(Size size) => Offset(x * size.width, y * size.height);
}

/// UI-only zone definition for display
class MapZoneView {
  const MapZoneView({
    required this.id,
    required this.label,
    required this.points,
  });

  final String id;
  final String label;
  final List<MapPointView> points;
}

/// UI-only obstacle representation
class MapObstacleView {
  const MapObstacleView({required this.position, this.code});

  final MapPointView position;
  final String? code;
}
