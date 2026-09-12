import 'dart:async';

import '../../models/campus/campus_point.dart';
import 'location_adapter.dart';

class DemoLocationAdapter implements LocationAdapter {
  DemoLocationAdapter({this.interval = const Duration(seconds: 1)});

  final Duration interval;

  final StreamController<CampusPoint> _positionController =
      StreamController<CampusPoint>.broadcast();

  List<CampusPoint> _plannedPath = [];
  int _currentIndex = 0;
  CampusPoint? _currentPosition;

  Timer? _timer;
  bool _paused = false;

  @override
  CampusPoint? get currentPosition => _currentPosition;

  bool get isRunning => _timer != null;

  bool get isPaused => _paused;

  @override
  Stream<CampusPoint> watchRobotPosition() {
    return _positionController.stream;
  }

  @override
  void loadPath(List<CampusPoint> path) {
    stop();

    _plannedPath = List<CampusPoint>.from(path);
    _currentIndex = 0;
    _paused = false;

    if (_plannedPath.isNotEmpty) {
      _currentPosition = _plannedPath.first;
    } else {
      _currentPosition = null;
    }
  }

  @override
  void start() {
    if (_plannedPath.isEmpty) {
      return;
    }

    _paused = false;
    _currentPosition ??= _plannedPath.first;

    _positionController.add(_currentPosition!);

    _timer ??= Timer.periodic(interval, (_) {
      _advance();
    });
  }

  void _advance() {
    if (_paused || _plannedPath.isEmpty) {
      return;
    }

    if (_currentIndex >= _plannedPath.length - 1) {
      stop();
      return;
    }

    _currentIndex++;
    _currentPosition = _plannedPath[_currentIndex];
    _positionController.add(_currentPosition!);
  }

  @override
  void pause() {
    _paused = true;
  }

  @override
  void resume() {
    if (_plannedPath.isEmpty) {
      return;
    }

    _paused = false;

    _timer ??= Timer.periodic(interval, (_) {
      _advance();
    });
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void reset() {
    stop();
    _paused = false;
    _currentIndex = 0;

    if (_plannedPath.isNotEmpty) {
      _currentPosition = _plannedPath.first;
    } else {
      _currentPosition = null;
    }
  }

  @override
  void dispose() {
    stop();
    _positionController.close();
  }
}
