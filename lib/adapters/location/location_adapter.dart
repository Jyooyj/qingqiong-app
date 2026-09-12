import '../../models/campus/campus_point.dart';

abstract class LocationAdapter {
  CampusPoint? get currentPosition;

  Stream<CampusPoint> watchRobotPosition();

  void loadPath(List<CampusPoint> path);

  void start();

  void pause();

  void resume();

  void stop();

  void reset();

  void dispose();
}
