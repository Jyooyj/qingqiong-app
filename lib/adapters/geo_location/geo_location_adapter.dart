import '../../models/campus_geo/campus_geo_point.dart';

abstract class GeoLocationAdapter {
  CampusGeoPoint? get currentPosition;

  Stream<CampusGeoPoint> watchRobotPosition();

  void loadPath(List<CampusGeoPoint> path);

  void start();

  void pause();

  void resume();

  void stop();

  void reset();

  void dispose();
}