import '../../services/campus_demo_coordinator.dart';
import '../../services/product_session.dart';
import "package:latlong2/latlong.dart";

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'campus_geo_map_view.dart';
import '../tasks/task_view_data.dart';
import '../../data/campus_geo/campus_geo_map_data.dart';
import '../../models/campus_geo/campus_geo_point.dart';

/// Geographic display bound to the shared campus task coordinator.
class CampusGeoPreviewPage extends StatefulWidget {
  const CampusGeoPreviewPage({
    super.key,
    this.coordinator,
    this.pathBlocked = false,
  });
  final CampusDemoCoordinator? coordinator;
  final bool pathBlocked;
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
    label: '充电点',
    position: _point(CampusGeoMapData.chargingStation.position),
  );
  ProductSession? _ownedSession;
  late final CampusDemoCoordinator _coordinator;
  String? get _selected => _coordinator.selectedZoneId;
  bool _obstacle = false, _picker = false;
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
                  const Text('实时展示清扫区域、规划路线、机器人位置与任务状态'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final item in _zones)
                        ChoiceChip(
                          label: Text(item.name),
                          selected: _selected == item.id,
                          onSelected: (_) => _select(item.id),
                        ),
                    ],
                  ),
                  if (zone != null && path.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('${zone.name}暂无可用清扫路线。'),
                    ),
                  if (zone != null && zone.polygon.isEmpty)
                    const Text('该地点以位置标记显示。'),
                  const SizedBox(height: 12),
                  CampusGeoMapView(
                    zones: _zones,
                    selectedZoneId: _selected,
                    robotPosition: _coordinator.geoRobotPosition,
                    plannedPath: path,
                    cleanedPath: _coordinator.geoCleanedPath,
                    chargingStation: _station,
                    obstacles: _obstacle || widget.pathBlocked
                        ? [
                            CampusGeoMarkerView(
                              id: widget.pathBlocked ? 'WARN-007' : 'sample',
                              label: '路径阻塞',
                              position: widget.pathBlocked
                                  ? _coordinator.geoRobotPosition
                                  : path.isEmpty
                                  ? _station.position
                                  : path[path.length ~/ 2],
                            ),
                          ]
                        : const [],
                    onZoneTap: _select,
                    enableCoordinatePicker: _picker,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    key: const Key('geo-task-status-card'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _coordinator.currentTask?.name ?? '暂无清扫任务',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 6,
                            children: [
                              Text('地点：${zone?.name ?? "未选择"}'),
                              Text(
                                _coordinator.currentTask == null
                                    ? '待机'
                                    : taskStatusLabel(
                                        _coordinator.currentTask!.status.name,
                                      ),
                              ),
                              Text(
                                '${(_coordinator.geoProgress * 100).round()}%',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            key: const Key('geo-task-progress'),
                            value: _coordinator.geoProgress.clamp(0.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('模拟路径阻塞'),
                    value: _obstacle,
                    onChanged: (v) => setState(() => _obstacle = v),
                  ),
                  if (kDebugMode)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('开发用坐标拾取'),
                      value: _picker,
                      onChanged: (v) => setState(() => _picker = v),
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
