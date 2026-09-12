import '../../services/campus_demo_coordinator.dart';
import '../../services/product_session.dart';
import "package:latlong2/latlong.dart";

import 'package:flutter/material.dart';
import 'campus_geo_map_view.dart';
import '../../data/campus_geo/campus_geo_map_data.dart';
import '../../data/campus_geo/campus_buildings.dart';
import '../../models/campus_geo/campus_geo_point.dart';
import '../../models/robot_status.dart';

/// Geographic display bound to the shared campus task coordinator.
class CampusGeoPreviewPage extends StatefulWidget {
  const CampusGeoPreviewPage({super.key, this.coordinator});
  final CampusDemoCoordinator? coordinator;
  @override
  State<CampusGeoPreviewPage> createState() => _CampusGeoPreviewPageState();
}

class _CampusGeoPreviewPageState extends State<CampusGeoPreviewPage> {
  static LatLng _point(CampusGeoPoint point) =>
      LatLng(point.latitude, point.longitude);
  static final _zones = CampusGeoMapData.zones
      .map(
        (zone) => CampusGeoZoneView(
          id: zone.id,
          name: zone.name,
          center: _point(zone.center),
          polygon: zone.polygon.map(_point).toList(),
        ),
      )
      .toList();
  static final _station = CampusGeoMarkerView(
    id: CampusGeoMapData.chargingStation.id,
    label: '充电桩',
    position: _point(CampusGeoMapData.chargingStation.position),
  );
  ProductSession? _ownedSession;
  late final CampusDemoCoordinator _coordinator;
  String? get _selected => _coordinator.selectedZoneId;
  bool get _obstacle =>
      _coordinator.session.robotController.currentStatus.pathBlocked;
  void _select(String id) => _coordinator.selectZone(id);
  @override
  void initState() {
    super.initState();
    _coordinator =
        widget.coordinator ??
        (_ownedSession = ProductSession()).campusCoordinator;
    _coordinator.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _coordinator.removeListener(_refresh);
    _ownedSession?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zone = _zones.where((z) => z.id == _selected).firstOrNull;
    final campusBuildingTags = CampusBuildings.all.where(
      (building) =>
          !building.pendingCalibration &&
          building.latitude != null &&
          building.longitude != null,
    );
    final path = _coordinator.geoPlannedPath;
    return Scaffold(
      appBar: AppBar(title: const Text('校园地图')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '上海海洋大学 · 校园智能清扫地图',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text('校园清扫任务地图，支持机器人位置、任务路线与异常状态实时展示。'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final building in campusBuildingTags)
                        ChoiceChip(
                          label: Text(building.name),
                          selected: _selected == building.zoneId,
                          onSelected: building.zoneId == null
                              ? null
                              : (_) => _select(building.zoneId!),
                        ),
                    ],
                  ),
                  if (zone != null && path.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('${zone.name}暂无任务路线。'),
                    ),
                  if (zone != null && zone.polygon.isEmpty)
                    const Text('该地点暂未提供区域边界，使用中心点标记。'),
                  const SizedBox(height: 12),
                  if (_coordinator
                              .session
                              .robotController
                              .currentStatus
                              .state ==
                          RobotState.returningToCharge ||
                      _coordinator
                              .session
                              .robotController
                              .currentStatus
                              .state ==
                          RobotState.charging)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _coordinator
                            .session
                            .robotController
                            .currentStatus
                            .stateText,
                        key: const Key('map-charge-status'),
                      ),
                    ),
                  CampusGeoMapView(
                    zones: _zones,
                    campusBuildings: CampusBuildings.all,
                    selectedZoneId: _selected,
                    robotPosition: _coordinator.geoRobotPosition,
                    plannedPath: path,
                    routeLabel:
                        _coordinator
                            .session
                            .robotController
                            .currentStatus
                            .emergency
                        ? '中断任务路线'
                        : _coordinator.currentTask?.status.name == 'paused'
                        ? '已暂停路线'
                        : '规划路线',
                    cleanedPath: _coordinator.geoCleanedPath,
                    chargingStation: _station,
                    obstacles: _obstacle
                        ? [
                            CampusGeoMarkerView(
                              id: 'sample',
                              label: '路径阻塞',
                              position: path.isEmpty
                                  ? _station.position
                                  : path[path.length ~/ 2],
                            ),
                          ]
                        : const [],
                    onZoneTap: _select,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('显示临时障碍'),
                    value: _obstacle,
                    onChanged: _coordinator.setDemoPathBlocked,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
