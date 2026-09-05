import 'dart:async';

import '../../adapters/location/location_adapter.dart';
import '../../data/campus/campus_map_data.dart';
import '../../models/campus/campus_map_state.dart';
import '../../models/campus/campus_point.dart';
class CampusLocationService {
  CampusLocationService({
    required this._locationAdapter,
  }) {
    _positionSubscription =
        _locationAdapter.watchRobotPosition().listen(_handlePositionUpdate);
  }

  final LocationAdapter _locationAdapter;

  StreamSubscription<CampusPoint>? _positionSubscription;

  final StreamController<CampusMapState> _stateController =
      StreamController<CampusMapState>.broadcast();

  String? _activeZoneId;

  CampusMapState _state = CampusMapState(
    robotPosition: CampusMapData.chargingStation.position,
    plannedPath: const [],
    cleanedPath: const [],
    obstacles: CampusMapData.obstacles,
    chargingStation: CampusMapData.chargingStation,
  );

  CampusMapState get currentState => _state;

  String? get activeZoneId => _activeZoneId;

  Stream<CampusMapState> watchMapState() {
    return _stateController.stream;
  }

  void loadZone(String zoneId) {
    final route = CampusMapData.routeForZone(zoneId);

    _activeZoneId = zoneId;

    _state = CampusMapState(
      robotPosition: CampusMapData.chargingStation.position,
      plannedPath: route.plannedPath,
      cleanedPath: const [],
      obstacles: CampusMapData.obstacles,
      chargingStation: CampusMapData.chargingStation,
    );

    _locationAdapter.loadPath(route.plannedPath);

    _emit();
  }

  void start() {
    _locationAdapter.start();
  }

  void pause() {
    _locationAdapter.pause();
  }

  void resume() {
    _locationAdapter.resume();
  }

  void stop() {
    _locationAdapter.stop();
  }

  void reset() {
    _locationAdapter.reset();

    _activeZoneId = null;

    _state = CampusMapState(
      robotPosition: CampusMapData.chargingStation.position,
      plannedPath: const [],
      cleanedPath: const [],
      obstacles: CampusMapData.obstacles,
      chargingStation: CampusMapData.chargingStation,
    );

    _emit();
  }

  void _handlePositionUpdate(CampusPoint position) {
    final updatedCleanedPath =
        List<CampusPoint>.from(_state.cleanedPath);

    if (updatedCleanedPath.isEmpty ||
        updatedCleanedPath.last != position) {
      updatedCleanedPath.add(position);
    }

    _state = _state.copyWith(
      robotPosition: position,
      cleanedPath: updatedCleanedPath,
    );

    _emit();
  }

  void _emit() {
    _stateController.add(_state);
  }

  void dispose() {
    _positionSubscription?.cancel();
    _locationAdapter.dispose();
    _stateController.close();
  }
}