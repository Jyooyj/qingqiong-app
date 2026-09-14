import '../../data/campus_geo/campus_buildings.dart';
import '../../data/campus_geo/campus_geo_map_data.dart';

class TaskViewData {
  String get statusText => switch (status) {
    'pending' => '待执行',
    'running' => '执行中',
    'paused' => '已暂停',
    'completed' => '已完成',
    'cancelled' => '已停止',
    'failed' => '失败',
    'charging' => '充电中',
    'returningToCharge' => '返回充电中',
    _ => '未知状态',
  };
  final String id;
  final String name;
  final String area;
  final String status; // e.g., pending, running, paused, completed, failed
  final int progress; // 0-100
  final String timeText; // planned or start time for display
  final double cleanedArea;
  final double cleanedDistance;
  final String durationText;
  final String? startTimeText;
  final String? endTimeText;
  final String mode; // '标准','深度','快速' for UI display
  final String? campusZoneId;
  final String? displayArea;
  final String? displayTaskName;

  /// User-facing area label; internal campus IDs never reach task cards.
  String get presentationArea {
    final id = campusZoneId;
    if (id == null || id.isEmpty) return area;
    if (id.startsWith('custom-')) return '自定义清扫区域';
    for (final building in CampusBuildings.all) {
      if (building.id == id || building.zoneId == id) return building.name;
    }
    final zone = CampusGeoMapData.findZoneById(id);
    if (zone != null) return zone.name;
    // Unknown IDs are implementation details; keep a safe product label.
    return area == id ? '校园区域' : area;
  }

  TaskViewData({
    required this.id,
    required this.name,
    required this.area,
    required this.status,
    required this.progress,
    required this.timeText,
    this.cleanedArea = 0.0,
    this.cleanedDistance = 0.0,
    this.durationText = '0 分 0 秒',
    this.startTimeText,
    this.endTimeText,
    this.mode = '标准',
    this.campusZoneId,
    this.displayArea,
    this.displayTaskName,
  });
}

/// Presentation only; raw status values remain unchanged for task actions.
String taskStatusLabel(String status) => switch (status) {
  'pending' => '待执行',
  'running' => '执行中',
  'paused' => '已暂停',
  'completed' => '已完成',
  'cancelled' => '已停止',
  'failed' => '失败',
  _ => '未知状态',
};
