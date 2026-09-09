import "package:latlong2/latlong.dart";

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'campus_geo_map_view.dart';
import '../../data/campus_geo/campus_geo_map_data.dart';
import '../../models/campus_geo/campus_geo_point.dart';

/// Local, manual UI preview. No timer or business coordinator.
class CampusGeoPreviewPage extends StatefulWidget {
  const CampusGeoPreviewPage({super.key});
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
  String? _selected;
  int _step = 0;
  bool _obstacle = false, _picker = false;
  void _select(String id) => setState(() {
    _selected = id;
    _step = 0;
  });
  @override
  Widget build(BuildContext context) {
    final zone = _zones.where((z) => z.id == _selected).firstOrNull;
    final path = zone == null
        ? const <LatLng>[]
        : (CampusGeoMapData.routeForZone(
                zone.id,
              )?.plannedPath.map(_point).toList() ??
              const <LatLng>[]);
    final step = path.isEmpty ? 0 : _step.clamp(0, path.length - 1);
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
                    robotPosition: path.isEmpty
                        ? _station.position
                        : path[step],
                    plannedPath: path,
                    cleanedPath: path.isEmpty
                        ? const []
                        : path.take(step + 1).toList(),
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
                        onPressed: path.isEmpty || step >= path.length - 1
                            ? null
                            : () => setState(() => _step++),
                        icon: const Icon(Icons.skip_next),
                        label: const Text('演示位置前进一步'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _step = 0),
                        child: const Text('重置演示位置'),
                      ),
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
