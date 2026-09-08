import "package:latlong2/latlong.dart";

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'campus_geo_map_view.dart';
import 'temporary_geo_data.dart';

/// Local, manual UI preview. No timer or business coordinator.
class CampusGeoPreviewPage extends StatefulWidget {
  const CampusGeoPreviewPage({super.key});
  @override
  State<CampusGeoPreviewPage> createState() => _CampusGeoPreviewPageState();
}

class _CampusGeoPreviewPageState extends State<CampusGeoPreviewPage> {
  String? _selected;
  int _step = 0;
  bool _obstacle = false, _picker = false;
  void _select(String id) => setState(() {
    _selected = id;
    _step = 0;
  });
  @override
  Widget build(BuildContext context) {
    final zone = TemporaryGeoData.zones
        .where((z) => z.id == _selected)
        .firstOrNull;
    final path = zone == null ? const <LatLng>[] : TemporaryGeoData.route(zone);
    final step = path.isEmpty ? 0 : _step.clamp(0, path.length - 1);
    return Scaffold(
      appBar: AppBar(title: const Text('真实地理地图')),
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
                  const Text('底图为真实地理地图。区域、路线和位置为临时测试数据，未校准，不代表设备定位或真实清扫任务。'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final item in TemporaryGeoData.zones)
                        ChoiceChip(
                          label: Text(item.name),
                          selected: _selected == item.id,
                          onSelected: (_) => _select(item.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CampusGeoMapView(
                    zones: TemporaryGeoData.zones,
                    selectedZoneId: _selected,
                    robotPosition: path.isEmpty
                        ? TemporaryGeoData.chargingStation.position
                        : path[step],
                    plannedPath: path,
                    cleanedPath: path.isEmpty
                        ? const []
                        : path.take(step + 1).toList(),
                    chargingStation: TemporaryGeoData.chargingStation,
                    obstacles: _obstacle
                        ? [
                            const CampusGeoMarkerView(
                              id: 'sample',
                              label: '临时障碍',
                              position: LatLng(30.8840, 121.8910),
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
