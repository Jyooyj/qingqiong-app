import '../../services/campus_demo_coordinator.dart';
import '../../services/product_session.dart';
import "package:latlong2/latlong.dart";

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'campus_geo_map_view.dart';
import '../../data/campus_geo/campus_geo_map_data.dart';
import '../../models/campus_geo/campus_geo_point.dart';

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
    label: 'Demo充电点',
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
                    '上海海洋大学 · 地图 UI 预览',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '已接入校园经纬度数据，部分地点为近似值；区域边界、路线和充电点为Demo数据，尚未完成道路校准。机器人位置为演示位置。',
                  ),
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
                      child: Text('${zone.name}暂未提供演示路线，仅显示地点。'),
                    ),
                  if (zone != null && zone.polygon.isEmpty)
                    const Text('该地点暂未提供区域边界，使用中心点标记。'),
                  const SizedBox(height: 12),
                  CampusGeoMapView(
                    zones: _zones,
                    selectedZoneId: _selected,
                    robotPosition: _coordinator.geoRobotPosition,
                    plannedPath: path,
                    cleanedPath: _coordinator.geoCleanedPath,
                    chargingStation: _station,
                    obstacles: _obstacle
                        ? [
                            CampusGeoMarkerView(
                              id: 'sample',
                              label: '演示障碍',
                              position: path.isEmpty
                                  ? _station.position
                                  : path[path.length ~/ 2],
                            ),
                          ]
                        : const [],
                    onZoneTap: _select,
                    enableCoordinatePicker: _picker,
                    onFallback: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.skip_next),
                        label: const Text('演示位置前进一步'),
                      ),
                      TextButton(onPressed: null, child: const Text('重置演示位置')),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('显示临时障碍'),
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
