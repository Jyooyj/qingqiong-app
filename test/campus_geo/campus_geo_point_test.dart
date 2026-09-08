import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/models/campus_geo/campus_geo_point.dart';

void main() {
  group('CampusGeoPoint', () {
    test('valid latitude and longitude are accepted', () {
      const point = CampusGeoPoint(
        latitude: 30.0,
        longitude: 120.0,
      );

      expect(point.isValid, isTrue);
    });

    test('invalid latitude is rejected', () {
      const point = CampusGeoPoint(
        latitude: 91.0,
        longitude: 120.0,
      );

      expect(point.isValid, isFalse);
    });

    test('invalid longitude is rejected', () {
      const point = CampusGeoPoint(
        latitude: 30.0,
        longitude: 181.0,
      );

      expect(point.isValid, isFalse);
    });
  });
}