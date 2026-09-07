import 'package:flutter/material.dart';
import '../../data/campus/campus_map_data.dart';
import 'campus_map_view.dart';
import 'current_task_map_card.dart';

/// Local selection preview only. Live task integration belongs to the host.
class CampusDemoPage extends StatefulWidget {
  const CampusDemoPage({super.key});
  @override
  State<CampusDemoPage> createState() => _CampusDemoPageState();
}

class _CampusDemoPageState extends State<CampusDemoPage> {
  String? _selected;
  bool _showObstacle = false;

  @override
  Widget build(BuildContext context) {
    final zone = _selected == null
        ? null
        : CampusMapData.findZoneById(_selected!);
    return Scaffold(
      appBar: AppBar(title: const Text('校园地图预览')),
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
                    '选择清扫区域',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text('点击地图或下方地点查看路线。当前为预览，不会创建清扫任务。'),
                  const SizedBox(height: 16),
                  CampusMapView(
                    zones: CampusMapData.zones,
                    taskData: CampusTaskViewData(
                      targetZoneName: zone?.name,
                      message: '任务尚未启动，运行数据暂未提供。',
                    ),
                    selectedZoneId: _selected,
                    robotPosition: CampusMapData.chargingStation.position,
                    plannedPath: zone == null
                        ? const []
                        : CampusMapData.routeForZone(zone.id).plannedPath,
                    chargingStation: CampusMapData.chargingStation,
                    obstacles: _showObstacle
                        ? CampusMapData.obstacles
                        : const [],
                    onZoneTap: (id) => setState(() => _selected = id),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final item in CampusMapData.zones)
                        ChoiceChip(
                          label: Text(item.name),
                          selected: item.id == _selected,
                          onSelected: (selected) => setState(
                            () => _selected = selected ? item.id : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('预览实验楼障碍标记'),
                    subtitle: const Text('仅检查显示效果，不触发故障或暂停'),
                    value: _showObstacle,
                    onChanged: (value) => setState(() => _showObstacle = value),
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
