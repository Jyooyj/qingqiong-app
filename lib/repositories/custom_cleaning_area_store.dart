import 'package:flutter/foundation.dart';

import '../models/campus_geo/campus_geo_point.dart';
import '../models/campus_geo/custom_cleaning_area.dart';

/// Session-owned demo storage, independent of executable campus task targets.
class CustomCleaningAreaStore extends ChangeNotifier {
  final List<CustomCleaningArea> _areas = [];
  List<CustomCleaningArea> get areas => List.unmodifiable(_areas);
  CustomCleaningArea? findById(String id) {
    for (final area in _areas) {
      if (area.id == id) return area;
    }
    return null;
  }

  int _sequence = 0;

  CustomCleaningArea save({
    required String name,
    required CustomAreaType type,
    required List<CampusGeoPoint> polygon,
  }) {
    final now = DateTime.now();
    final area = CustomCleaningArea(
      id: 'custom-${now.microsecondsSinceEpoch}-${_sequence++}',
      name: name,
      type: type,
      polygon: polygon,
      createdAt: now,
    );
    _areas.add(area);
    notifyListeners();
    return area;
  }
}
