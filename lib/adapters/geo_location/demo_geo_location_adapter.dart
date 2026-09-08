import 'dart:async';

import '../../models/campus_geo/campus_geo_point.dart';
import 'geo_location_adapter.dart';

class DemoGeoLocationAdapter implements GeoLocationAdapter {
  final Duration stepInterval;

  final StreamController<CampusGeoPoint> _positionController =
      StreamController<CampusGeoPoint>.broadcast();

  List<CampusGeoPoint> _path = [];
  Timer? _timer;
  int _currentIndex = 0;
  bool _isRunning = false;

  DemoGeoLocationAdapter({
    this.stepInterval = const Duration(seconds: 1),
  });

  @override
  CampusGeoPoint? get currentPosition {
    if (_path.isEmpty) {
      return null;
    }

    return _path[_currentIndex];
  }

  @override
  Stream<CampusGeoPoint> watchRobotPosition() {
    return _positionController.stream;
  }

  @override
  void loadPath(List<CampusGeoPoint> path) {
    _cancelTimer();

    _path = List<CampusGeoPoint>.from(path);
    _currentIndex = 0;
    _isRunning = false;

    final position = currentPosition;
    if (position != null) {
      _positionController.add(position);
    }
  }

  @override
  void start() {
    if (_path.isEmpty || _isRunning) {
      return;
    }

    _isRunning = true;
    _startTimer();
  }

  @override
  void pause() {
    if (!_isRunning) {
      return;
    }

    _isRunning = false;
    _cancelTimer();
  }

  @override
  void resume() {
    if (_path.isEmpty || _isRunning) {
      return;
    }

    _isRunning = true;
    _startTimer();
  }

  @override
  void stop() {
    _isRunning = false;
    _cancelTimer();
  }

  @override
  void reset() {
    _isRunning = false;
    _cancelTimer();
    _currentIndex = 0;

    final position = currentPosition;
    if (position != null) {
      _positionController.add(position);
    }
  }

  void _startTimer() {
    _cancelTimer();

    _timer = Timer.periodic(stepInterval, (_) {
      if (!_isRunning || _path.isEmpty) {
        return;
      }

      if (_currentIndex >= _path.length - 1) {
        stop();
        return;
      }

      _currentIndex += 1;
      _positionController.add(_path[_currentIndex]);

      if (_currentIndex >= _path.length - 1) {
        stop();
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _isRunning = false;
    _cancelTimer();
    _positionController.close();
  }
}